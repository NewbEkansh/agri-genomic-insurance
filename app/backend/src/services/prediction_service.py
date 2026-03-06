"""
prediction_service.py
----------------------
Orchestrates the full prediction → fraud check → payout pipeline.
Called by the /predictions/score route.

Fraud detection has two layers:
  Layer 1 — Regional Consensus: are neighbouring farms also affected?
  Layer 2 — NDVI Delta: does satellite data confirm crop damage is real?

Both layers must pass for a full payout. Either failing reduces the
payout to FRAUD_PAYOUT_MULTIPLIER (0.65).
"""

import math
from datetime import datetime, timedelta, timezone
from src.models.prediction import PredictionInput, PredictionDB, PayoutLog
from src.db import schemas as db
from src.core.config import settings
from src.services import blockchain_service, alert_service, bedrock_service, agromonitoring_service


# ── Layer 1: Regional Consensus ───────────────────────────────────────────────

def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi, dlambda = math.radians(lat2 - lat1), math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _regional_consensus_check(farm_id: str, farm_lat: float, farm_lon: float) -> tuple[float, float]:
    """
    Returns (payout_multiplier, consensus_pct).

    Scans all registered farms and finds those within REGIONAL_RADIUS_KM.
    If >= REGIONAL_CONSENSUS_MIN fraction of them are also flagged with a
    recent high-confidence prediction, the outbreak is genuine → full payout.
    Otherwise the farm is an isolated anomaly → fraud guard multiplier.
    """
    all_farmers = db.scan_all_farmers()
    nearby_ids = [
        f["farmer_id"] for f in all_farmers
        if f["farmer_id"] != farm_id
        and _haversine_km(farm_lat, farm_lon, float(f["farm_lat"]), float(f["farm_lon"]))
        <= settings.REGIONAL_RADIUS_KM
    ]

    if not nearby_ids:
        # No registered neighbours — cannot confirm regional outbreak.
        # Apply conservative fraud guard rather than denying outright.
        print(f"[Consensus] No neighbours within {settings.REGIONAL_RADIUS_KM}km — applying fraud guard")
        return settings.FRAUD_PAYOUT_MULTIPLIER, 0.0

    cutoff = (datetime.now(timezone.utc) - timedelta(hours=48)).isoformat()
    flagged_ids = db.get_recent_predictions_for_farms(nearby_ids, cutoff)
    consensus_pct = len(flagged_ids) / len(nearby_ids)

    print(
        f"[Consensus] {len(flagged_ids)}/{len(nearby_ids)} nearby farms flagged "
        f"({consensus_pct:.0%}) — threshold is {settings.REGIONAL_CONSENSUS_MIN:.0%}"
    )

    if consensus_pct >= settings.REGIONAL_CONSENSUS_MIN:
        return 1.0, consensus_pct
    return settings.FRAUD_PAYOUT_MULTIPLIER, consensus_pct


# ── Layer 2: NDVI Fraud Check ─────────────────────────────────────────────────

def _ndvi_fraud_check(farmer: dict) -> tuple[bool, dict | None]:
    """
    Returns (fraud_flag, ndvi_analysis | None).

    Fetches current NDVI via Agromonitoring satellite and compares
    against the baseline captured at farmer registration.

    fraud_flag = True means the NDVI pattern looks suspicious:
      - Baseline was already unhealthy at registration (< 0.3)
      - AND current drop is small (< 10%) — doesn't match a real disease event
      This pattern suggests the farmer registered with already-bad crops
      specifically to claim a payout.

    A genuine disease shows: healthy baseline (0.6+) → sharp current drop.
    """
    polygon_id = farmer.get("agro_polygon_id")
    baseline_ndvi = farmer.get("baseline_ndvi")

    if not polygon_id or baseline_ndvi is None:
        # No satellite data available — skip NDVI check, don't penalise
        print("[NDVI] No polygon/baseline available — skipping NDVI fraud check")
        return False, None

    current_ndvi = agromonitoring_service.get_current_ndvi(polygon_id)
    if current_ndvi is None:
        # Satellite pass not available — skip silently
        print("[NDVI] No recent satellite pass available — skipping NDVI check")
        return False, None

    analysis = agromonitoring_service.compute_ndvi_delta(
        baseline_ndvi=float(baseline_ndvi),
        current_ndvi=current_ndvi,
    )

    print(
        f"[NDVI] baseline={baseline_ndvi:.3f}, current={current_ndvi:.3f}, "
        f"delta={analysis['delta']:.3f}, severity={analysis['severity']}, "
        f"fraud_flag={analysis['fraud_flag']}"
    )

    return analysis["fraud_flag"], analysis


# ── Main Orchestrator ─────────────────────────────────────────────────────────

def process_prediction(payload: PredictionInput, farmer: dict, policy: dict) -> PredictionDB:
    """
    Full pipeline for a single AI prediction event:

      1.  Build initial prediction record.
      2.  Check if confidence crosses payout threshold.
      3.  If yes → run Layer 1 (regional consensus fraud check).
      4.        → run Layer 2 (NDVI satellite fraud check).
      5.        → compute final payout_multiplier (1.0 or 0.65).
      6.        → generate Bedrock narrative assessment.
      7.        → write payout log to DynamoDB.
      8.        → call blockchain oracle to execute Sepolia transaction.
      9.        → update policy status.
      10.       → send payout SMS to farmer.
      11. If below payout threshold but above early warning → send warning SMS.
      12. Persist prediction record to DynamoDB.
      13. Return prediction record.
    """
    # ── 1. Build prediction record ────────────────────────────────────────────
    prediction = PredictionDB(**payload.model_dump())

    payout_triggered = payload.confidence_score >= settings.PAYOUT_TRIGGER_THRESHOLD
    early_warning = (
        not payout_triggered
        and payload.confidence_score >= settings.EARLY_WARNING_THRESHOLD
    )

    # ── 2–10. Payout pipeline ─────────────────────────────────────────────────
    if payout_triggered:

        # ── 3. Layer 1: Regional consensus ───────────────────────────────────
        payout_multiplier, consensus_pct = _regional_consensus_check(
            farm_id=payload.farm_id,
            farm_lat=float(farmer["farm_lat"]),
            farm_lon=float(farmer["farm_lon"]),
        )

        # ── 4. Layer 2: NDVI satellite check ─────────────────────────────────
        ndvi_fraud_flag, ndvi_analysis = _ndvi_fraud_check(farmer)

        if ndvi_fraud_flag and payout_multiplier == 1.0:
            # Consensus said genuine but NDVI says suspicious → apply guard
            payout_multiplier = settings.FRAUD_PAYOUT_MULTIPLIER
            print(
                f"[NDVI] Fraud flag raised despite regional consensus — "
                f"multiplier adjusted to {payout_multiplier}"
            )

        # ── 5. Final payout amount ────────────────────────────────────────────
        insured = float(policy["insured_amount_usdc"])
        final_payout = insured * payout_multiplier

        print(
            f"[Payout] farm={payload.farm_id}, insured=${insured}, "
            f"multiplier={payout_multiplier}, final=${final_payout:.2f}"
        )

        # ── 6. Bedrock narrative ──────────────────────────────────────────────
        assessment_text = bedrock_service.generate_assessment(
            farmer_name=farmer["name"],
            crop_type=farmer["crop_type"],
            disease_type=payload.disease_type,
            confidence=payload.confidence_score,
            affected_area_pct=payload.affected_area_percent,
            consensus_pct=consensus_pct,
            payout_multiplier=payout_multiplier,
            insured_amount=insured,
            final_payout=final_payout,
        )

        # ── 7. Write payout log ───────────────────────────────────────────────
        payout_log = PayoutLog(
            farm_id=payload.farm_id,
            farmer_id=farmer["farmer_id"],
            prediction_id=prediction.prediction_id,
            farmer_wallet=farmer["wallet_address"],
            insured_amount_usdc=insured,
            payout_multiplier=payout_multiplier,
            final_payout_usdc=final_payout,
            status="pending",
        )
        db.put_payout_log(payout_log.to_dynamo())

        # ── 8. Blockchain transaction ─────────────────────────────────────────
        try:
            tx_hash = blockchain_service.trigger_payout(
                farmer_wallet=farmer["wallet_address"],
                farm_id=payload.farm_id,
                payout_percent=int(payout_multiplier * 100),
                tx_note=prediction.prediction_id,
            )
            payout_log.tx_hash = tx_hash
            payout_log.status = "submitted"
            db.update_payout_log(payout_log.payout_id, tx_hash, "submitted")
            print(f"[Blockchain] tx submitted: {tx_hash}")

            # ── 9. Update policy status ───────────────────────────────────────
            db.update_policy_status(policy["policy_id"], "triggered")

            # ── 10. Payout SMS ────────────────────────────────────────────────
            alert_service.send_payout_alert(
                phone=farmer.get("phone", ""),
                name=farmer["name"],
                final_payout=final_payout,
                tx_hash=tx_hash,
                assessment=assessment_text,
            )

        except Exception as e:
            print(f"[Blockchain] Transaction failed: {e}")
            db.update_payout_log(payout_log.payout_id, "", "failed")
            # Don't re-raise — prediction record still gets saved

        # ── Update prediction record with all results ─────────────────────────
        prediction.regional_consensus_pct = consensus_pct
        prediction.payout_multiplier = payout_multiplier
        prediction.payout_triggered = True
        prediction.payout_id = payout_log.payout_id
        prediction.bedrock_assessment = assessment_text

    # ── 11. Early warning SMS (no payout) ────────────────────────────────────
    elif early_warning:
        alert_service.send_early_warning(
            phone=farmer.get("phone", ""),
            name=farmer["name"],
            disease_type=payload.disease_type,
            confidence=payload.confidence_score,
            crop_type=farmer["crop_type"],
        )
        print(f"[Warning] Early warning SMS sent to {farmer['name']} ({payload.confidence_score:.0%} confidence)")

    # ── 12. Persist prediction ────────────────────────────────────────────────
    db.put_prediction(prediction.to_dynamo())
    print(f"[Prediction] Saved prediction {prediction.prediction_id} to DynamoDB")

    # ── 13. Return ────────────────────────────────────────────────────────────
    return prediction
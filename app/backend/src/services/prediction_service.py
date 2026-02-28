"""
prediction_service.py
----------------------
Orchestrates the full prediction → fraud check → payout pipeline.
Called by the /predictions/score route.
"""

import math
from datetime import datetime, timedelta, timezone
from src.models.prediction import PredictionInput, PredictionDB, PayoutLog
from src.db import schemas as db
from src.core.config import settings
from src.services import blockchain_service, alert_service, bedrock_service


# ── Fraud Detection ───────────────────────────────────────────────────────────

def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi, dlambda = math.radians(lat2 - lat1), math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _regional_consensus_check(farm_id: str, farm_lat: float, farm_lon: float) -> tuple[float, float]:
    """
    Returns (payout_multiplier, consensus_pct).

    Checks what fraction of farms within REGIONAL_RADIUS_KM are ALSO
    flagged with a recent high-confidence prediction. If the outbreak is
    regional, it's genuine → full payout. If isolated → fraud guard.
    """
    all_farmers = db.scan_all_farmers()
    nearby_ids = [
        f["farmer_id"] for f in all_farmers
        if f["farmer_id"] != farm_id
        and _haversine_km(farm_lat, farm_lon, float(f["farm_lat"]), float(f["farm_lon"]))
        <= settings.REGIONAL_RADIUS_KM
    ]

    if not nearby_ids:
        # No registered neighbours — can't confirm outbreak. Apply conservative guard.
        return settings.FRAUD_PAYOUT_MULTIPLIER, 0.0

    cutoff = (datetime.now(timezone.utc) - timedelta(hours=48)).isoformat()
    flagged_ids = db.get_recent_predictions_for_farms(nearby_ids, cutoff)
    consensus_pct = len(flagged_ids) / len(nearby_ids)

    if consensus_pct >= settings.REGIONAL_CONSENSUS_MIN:
        return 1.0, consensus_pct
    return settings.FRAUD_PAYOUT_MULTIPLIER, consensus_pct


# ── Main Orchestrator ─────────────────────────────────────────────────────────

def process_prediction(payload: PredictionInput, farmer: dict, policy: dict) -> PredictionDB:
    """
    Full pipeline:
      1. Fraud check → payout multiplier
      2. If above threshold → Bedrock narrative + blockchain payout + SMS
      3. If above early warning threshold → warning SMS only
      4. Persist prediction record
    """
    prediction = PredictionDB(**payload.model_dump())

    payout_triggered = payload.confidence_score >= settings.PAYOUT_TRIGGER_THRESHOLD
    early_warning = (
        not payout_triggered
        and payload.confidence_score >= settings.EARLY_WARNING_THRESHOLD
    )

    if payout_triggered:
        payout_multiplier, consensus_pct = _regional_consensus_check(
            farm_id=payload.farm_id,
            farm_lat=float(farmer["farm_lat"]),
            farm_lon=float(farmer["farm_lon"]),
        )
        insured = float(policy["insured_amount_usdc"])
        final_payout = insured * payout_multiplier

        # Generate human-readable assessment via Bedrock
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

        # Execute blockchain payout
        payout_log = PayoutLog(
            farm_id=payload.farm_id,
            farmer_id=farmer["farmer_id"],
            prediction_id=prediction.prediction_id,
            farmer_wallet=farmer["wallet_address"],
            insured_amount_usdc=insured,
            payout_multiplier=payout_multiplier,
            final_payout_usdc=final_payout,
        )
        db.put_payout_log(payout_log.to_dynamo())

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

            # Update policy status
            db.update_policy_status(policy["policy_id"], "triggered")

            # Send payout SMS
            alert_service.send_payout_alert(
                phone=farmer["phone"],
                name=farmer["name"],
                final_payout=final_payout,
                tx_hash=tx_hash,
                assessment=assessment_text,
            )
        except Exception as e:
            db.update_payout_log(payout_log.payout_id, "", "failed")
            # Don't re-raise — we still want to save the prediction record

        prediction.regional_consensus_pct = consensus_pct
        prediction.payout_multiplier = payout_multiplier
        prediction.payout_triggered = True
        prediction.payout_id = payout_log.payout_id
        prediction.bedrock_assessment = assessment_text

    elif early_warning:
        alert_service.send_early_warning(
            phone=farmer["phone"],
            name=farmer["name"],
            disease_type=payload.disease_type,
            confidence=payload.confidence_score,
            crop_type=farmer["crop_type"],
        )

    db.put_prediction(prediction.to_dynamo())
    return prediction
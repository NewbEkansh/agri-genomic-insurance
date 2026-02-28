from fastapi import APIRouter, HTTPException, Depends
from src.models.prediction import PredictionInput, PredictionDB, PayoutLog
from src.db import schemas as db
from src.api.deps import require_internal_key
from src.services import prediction_service
from src.core.config import settings

router = APIRouter()


@router.post("/score", response_model=PredictionDB, status_code=201)
def submit_prediction_score(
    payload: PredictionInput,
    _: None = Depends(require_internal_key),     # AI pipeline must include X-API-Key header
):
    """
    Main integration endpoint — called by the AI pipeline after model inference.

    Full flow:
      1. Validate farm + active policy exist.
      2. Run Regional Consensus fraud check.
      3. Compute payout_multiplier (1.0 or 0.65).
      4. If confidence >= threshold → call Bedrock for narrative + trigger payout.
      5. If confidence >= early_warning → send SMS warning (no payout).
      6. Persist prediction to DynamoDB.
    """
    # 1. Validate farm exists and has an active policy
    farmer = db.get_farmer_by_id(payload.farm_id)
    if not farmer:
        raise HTTPException(status_code=404, detail=f"Farm {payload.farm_id} not registered")

    active_policies = [p for p in db.get_policies_by_farmer(payload.farm_id) if p.get("status") == "active"]
    if not active_policies:
        raise HTTPException(status_code=400, detail="Farm has no active insurance policy")

    policy = active_policies[0]

    # 2-6. Delegate to prediction_service for all the heavy logic
    prediction = prediction_service.process_prediction(
        payload=payload,
        farmer=farmer,
        policy=policy,
    )

    return prediction


@router.get("/farm/{farm_id}")
def get_farm_predictions(farm_id: str, limit: int = 10):
    """Get recent prediction history for a farm."""
    predictions = db.get_recent_predictions_for_farm(farm_id, limit=limit)
    return {"farm_id": farm_id, "predictions": predictions}


@router.get("/payout/{payout_id}")
def get_payout_status(payout_id: str):
    """Check the status of a specific payout by ID."""
    payout = db.get_payout_by_id(payout_id)
    if not payout:
        raise HTTPException(status_code=404, detail="Payout not found")
    return payout
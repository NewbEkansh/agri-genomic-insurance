from fastapi import APIRouter, HTTPException
from src.models.farmer import FarmerCreate, FarmerDB
from src.db import schemas as db

router = APIRouter()


@router.post("/register", response_model=FarmerDB, status_code=201)
def register_farmer(payload: FarmerCreate):
    """
    Register a new farmer. Captures farm coordinates and crop type
    which are essential for the regional fraud consensus check later.
    """
    farmer = FarmerDB(**payload.model_dump())
    db.put_farmer(farmer.to_dynamo())
    return farmer


@router.get("/{farmer_id}", response_model=FarmerDB)
def get_farmer(farmer_id: str):
    """Retrieve a farmer profile by ID."""
    farmer = db.get_farmer_by_id(farmer_id)
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")
    return farmer


@router.get("/{farmer_id}/policies")
def get_farmer_policies(farmer_id: str):
    """Get all insurance policies for a farmer."""
    # Verify farmer exists first
    if not db.get_farmer_by_id(farmer_id):
        raise HTTPException(status_code=404, detail="Farmer not found")
    policies = db.get_policies_by_farmer(farmer_id)
    return {"farmer_id": farmer_id, "policies": policies}


@router.get("/{farmer_id}/predictions")
def get_farmer_predictions(farmer_id: str, limit: int = 10):
    """Get recent AI predictions for a farmer's farm."""
    predictions = db.get_recent_predictions_for_farm(farmer_id, limit=limit)
    return {"farm_id": farmer_id, "predictions": predictions}


@router.get("/{farmer_id}/payouts")
def get_farmer_payouts(farmer_id: str):
    """Get all payout history for a farmer."""
    payouts = db.get_payouts_by_farm(farmer_id)
    return {"farm_id": farmer_id, "payouts": payouts}
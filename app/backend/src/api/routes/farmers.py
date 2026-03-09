from fastapi import APIRouter, HTTPException, Depends
from src.models.farmer import FarmerCreate, FarmerDB
from src.db import schemas as db
from src.services import agromonitoring_service
from src.services.wallet_service import create_farmer_wallet
from src.core.security import get_current_farmer
import time

router = APIRouter()


@router.post("/register", response_model=FarmerDB, status_code=201)
def register_farmer(
    payload: FarmerCreate,
    current_user: dict = Depends(get_current_farmer),  # JWT required
):
    """
    Register a new farmer after OTP verification.

    Requires: Authorization: Bearer <token> (from /auth/verify-otp)

    On registration:
      1. Validates phone matches the JWT token
      2. Checks farmer isn't already registered
      3. Auto-creates an Ethereum wallet (stored in Secrets Manager)
      4. Creates Agromonitoring polygon
      5. Captures baseline NDVI
      6. Saves to DynamoDB
    """
    # Verify the phone in payload matches the authenticated phone
    if payload.phone != current_user["phone"]:
        raise HTTPException(
            status_code=403,
            detail="Phone number does not match authenticated session"
        )

    # Check not already registered
    from src.api.routes.auth import _get_farmer_by_phone
    existing = _get_farmer_by_phone(payload.phone)
    if existing:
        raise HTTPException(
            status_code=409,
            detail="Farmer already registered with this phone number"
        )

    farmer = FarmerDB(**payload.model_dump())

    # Auto-create wallet — farmer doesn't need to know about this
    wallet = create_farmer_wallet(farmer.farmer_id)
    farmer.wallet_address = wallet["address"]
    print(f"[Registration] Wallet created for {farmer.name}: {farmer.wallet_address}")

    # Create Agromonitoring polygon
    polygon_id = agromonitoring_service.create_farm_polygon(
        farmer_name=farmer.name,
        farm_lat=farmer.farm_lat,
        farm_lon=farmer.farm_lon,
        area_hectares=farmer.farm_area_hectares,
    )
    if polygon_id:
        farmer.agro_polygon_id = polygon_id
        time.sleep(1)
        baseline = agromonitoring_service.get_current_ndvi(polygon_id)
        if baseline is not None:
            farmer.baseline_ndvi = baseline

    db.put_farmer(farmer.to_dynamo())
    return farmer


@router.get("/me", response_model=FarmerDB)
def get_my_profile(current_user: dict = Depends(get_current_farmer)):
    """Get the logged-in farmer's profile."""
    farmer_id = current_user["farmer_id"]
    if farmer_id == "pending":
        raise HTTPException(status_code=400, detail="Registration not complete")

    farmer = db.get_farmer_by_id(farmer_id)
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")
    return farmer


@router.get("/{farmer_id}", response_model=FarmerDB)
def get_farmer(farmer_id: str):
    """Get farmer by ID — public endpoint for internal service calls."""
    farmer = db.get_farmer_by_id(farmer_id)
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")
    return farmer


@router.get("/{farmer_id}/policies")
def get_farmer_policies(farmer_id: str):
    if not db.get_farmer_by_id(farmer_id):
        raise HTTPException(status_code=404, detail="Farmer not found")
    return {"farmer_id": farmer_id, "policies": db.get_policies_by_farmer(farmer_id)}


@router.get("/{farmer_id}/predictions")
def get_farmer_predictions(farmer_id: str, limit: int = 10):
    return {
        "farm_id": farmer_id,
        "predictions": db.get_recent_predictions_for_farm(farmer_id, limit=limit)
    }


@router.get("/{farmer_id}/payouts")
def get_farmer_payouts(farmer_id: str):
    return {"farm_id": farmer_id, "payouts": db.get_payouts_by_farm(farmer_id)}


@router.get("/{farmer_id}/farm-health")
def get_farm_health(farmer_id: str):
    farmer = db.get_farmer_by_id(farmer_id)
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")

    polygon_id = farmer.get("agro_polygon_id")
    if not polygon_id:
        raise HTTPException(status_code=404, detail="No satellite polygon registered for this farm")

    current_ndvi = agromonitoring_service.get_current_ndvi(polygon_id)
    soil = agromonitoring_service.get_soil_data(polygon_id)

    result = {
        "farmer_id": farmer_id,
        "polygon_id": polygon_id,
        "current_ndvi": current_ndvi,
        "baseline_ndvi": farmer.get("baseline_ndvi"),
        "soil_data": soil,
    }

    baseline = farmer.get("baseline_ndvi")
    if current_ndvi and baseline:
        result["ndvi_analysis"] = agromonitoring_service.compute_ndvi_delta(
            baseline_ndvi=float(baseline),
            current_ndvi=current_ndvi,
        )

    return result
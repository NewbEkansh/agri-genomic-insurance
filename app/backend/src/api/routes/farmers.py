from fastapi import APIRouter, HTTPException
from src.models.farmer import FarmerCreate, FarmerDB
from src.db import schemas as db
from src.services import agromonitoring_service

router = APIRouter()


@router.post("/register", response_model=FarmerDB, status_code=201)
def register_farmer(payload: FarmerCreate):
    """
    Register a new farmer.

    On registration we:
      1. Save the farmer record to DynamoDB.
      2. Create an Agromonitoring polygon for their farm boundary.
      3. Fetch their baseline NDVI — stored for later fraud comparison.

    Steps 2 and 3 are non-fatal: if Agromonitoring is down, registration
    still succeeds. The polygon_id and baseline_ndvi will just be null.
    """
    farmer = FarmerDB(**payload.model_dump())

    # Step 2: Create Agromonitoring polygon
    polygon_id = agromonitoring_service.create_farm_polygon(
        farmer_name=farmer.name,
        farm_lat=farmer.farm_lat,
        farm_lon=farmer.farm_lon,
        area_hectares=farmer.farm_area_hectares,
    )
    if polygon_id:
        farmer.agro_polygon_id = polygon_id

        # Step 3: Capture baseline NDVI
        # Slight delay to allow Agromonitoring to process the new polygon
        import time; time.sleep(1)
        baseline = agromonitoring_service.get_current_ndvi(polygon_id)
        if baseline is not None:
            farmer.baseline_ndvi = baseline
            print(f"[Registration] Baseline NDVI for {farmer.name}: {baseline}")

    db.put_farmer(farmer.to_dynamo())
    return farmer


@router.get("/{farmer_id}", response_model=FarmerDB)
def get_farmer(farmer_id: str):
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
    return {"farm_id": farmer_id, "predictions": db.get_recent_predictions_for_farm(farmer_id, limit=limit)}


@router.get("/{farmer_id}/payouts")
def get_farmer_payouts(farmer_id: str):
    return {"farm_id": farmer_id, "payouts": db.get_payouts_by_farm(farmer_id)}


@router.get("/{farmer_id}/farm-health")
def get_farm_health(farmer_id: str):
    """
    Returns current satellite health data for a farmer's farm.
    Used by the frontend dashboard and can be passed to the AI model.
    """
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

    # Compute NDVI delta if both values exist
    baseline = farmer.get("baseline_ndvi")
    if current_ndvi and baseline:
        result["ndvi_analysis"] = agromonitoring_service.compute_ndvi_delta(
            baseline_ndvi=float(baseline),
            current_ndvi=current_ndvi,
        )

    return result
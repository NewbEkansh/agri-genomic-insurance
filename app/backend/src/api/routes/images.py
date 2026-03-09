import boto3
import uuid
import threading
import tempfile
import os
import sys
import requests as http_requests
from fastapi import APIRouter, UploadFile, File, HTTPException
from src.core.config import settings
from src.db import schemas as db
from src.services.image_validator import validate_image

router = APIRouter()

# ── Add ml_pipeline to path ───────────────────────────────────────────────────
ML_PIPELINE_PATH = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "..", "ml_pipeline")
)
if ML_PIPELINE_PATH not in sys.path:
    sys.path.insert(0, ML_PIPELINE_PATH)

# Pre-load AI model once at startup
try:
    from ml_service import analyze_farm
    AI_MODEL_AVAILABLE = True
    print("✅ AI model loaded successfully")
except ImportError:
    AI_MODEL_AVAILABLE = False
    print("⚠️  ml_service not found — using mock predictions until AI teammate deploys")

    def analyze_farm(image_path, soil_temp, soil_moisture, ndvi):
        """Mock until real model is deployed."""
        return "rice_blast", 0.91, 0.60


def get_s3():
    return boto3.client(
        "s3",
        region_name=settings.AWS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID or None,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY or None,
    )


# ── Background prediction runner ──────────────────────────────────────────────

def _run_prediction_async(farmer_id: str, s3_key: str):
    """
    Runs in a background thread after image upload.
    Image quality has already been validated before this runs.
    """
    tmp_path = None
    try:
        # Download image from S3 to temp file
        tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        tmp_path = tmp.name
        tmp.close()

        get_s3().download_file(settings.S3_BUCKET_CROPS, s3_key, tmp_path)
        print(f"[AI] Image downloaded to {tmp_path}")

        # Fetch soil + NDVI from Agromonitoring
        soil_temp = 30.0
        soil_moisture = 50.0
        ndvi = 0.6

        farmer = db.get_farmer_by_id(farmer_id)
        if farmer and farmer.get("agro_polygon_id"):
            try:
                from src.services import agromonitoring_service
                polygon_id = farmer["agro_polygon_id"]

                soil = agromonitoring_service.get_soil_data(polygon_id)
                if soil:
                    soil_temp = soil.get("soil_temp_celsius", soil_temp)
                    soil_moisture = float(soil.get("soil_moisture", 0.5)) * 100

                current_ndvi = agromonitoring_service.get_current_ndvi(polygon_id)
                if current_ndvi is not None:
                    ndvi = current_ndvi

                print(f"[AI] Agromonitoring — temp={soil_temp}°C, moisture={soil_moisture}%, ndvi={ndvi}")
            except Exception as e:
                print(f"[AI] Agromonitoring fetch failed, using defaults: {e}")

        # Run AI model
        print(f"[AI] Running analyze_farm for farmer {farmer_id}...")
        disease_type, confidence_score, affected_area = analyze_farm(
            image_path=tmp_path,
            soil_temp=soil_temp,
            soil_moisture=soil_moisture,
            ndvi=ndvi,
        )
        print(f"[AI] Result — disease={disease_type}, confidence={confidence_score:.2f}, area={affected_area:.2f}")

        # POST to /predictions/score
        resp = http_requests.post(
            "http://localhost:8000/predictions/score",
            headers={
                "X-API-Key": settings.INTERNAL_API_KEY,
                "Content-Type": "application/json",
            },
            json={
                "farm_id": farmer_id,
                "disease_type": disease_type,
                "confidence_score": round(float(confidence_score), 4),
                "affected_area_percent": round(float(affected_area), 4),
                "model_version": "v1",
            },
            timeout=30,
        )
        print(f"[AI] Prediction submitted — status={resp.status_code}, payout_triggered={resp.json().get('payout_triggered')}")

    except Exception as e:
        print(f"[AI] Prediction pipeline failed for farmer {farmer_id}: {e}")
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.unlink(tmp_path)


# ── Upload endpoint ───────────────────────────────────────────────────────────

@router.post("/upload/{farmer_id}")
def upload_crop_image(farmer_id: str, file: UploadFile = File(...)):
    """
    Upload a crop image for a farmer.

    Validates image quality (blur, brightness, resolution) before accepting.
    If quality check fails, returns 422 with a farmer-friendly reason.

    On success:
      - Stores image in S3
      - Triggers AI inference in background thread
      - Returns immediately — frontend polls GET /farmers/{farmer_id}/predictions
    """
    # Validate farmer + active policy
    farmer = db.get_farmer_by_id(farmer_id)
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")

    active_policies = [
        p for p in db.get_policies_by_farmer(farmer_id)
        if p.get("status") == "active"
    ]
    if not active_policies:
        raise HTTPException(status_code=400, detail="Farmer has no active insurance policy")

    # Validate file type
    allowed_types = ["image/jpeg", "image/png", "image/jpg"]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Only JPEG/PNG images allowed")

    # ── Save to temp file for quality validation ───────────────────────────────
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
    tmp_path = tmp.name
    try:
        tmp.write(file.file.read())
        tmp.close()

        # ── Image quality check ───────────────────────────────────────────────
        validation = validate_image(tmp_path)
        print(f"[Quality] farmer={farmer_id}, valid={validation.is_valid}, details={validation.details}")

        if not validation.is_valid:
            raise HTTPException(
                status_code=422,
                detail={
                    "message": validation.reason,
                    "quality_metrics": validation.details,
                }
            )

        # ── Upload validated image to S3 ──────────────────────────────────────
        ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
        s3_key = f"crops/{farmer_id}/{uuid.uuid4()}.{ext}"

        with open(tmp_path, "rb") as f:
            get_s3().upload_fileobj(
                f,
                settings.S3_BUCKET_CROPS,
                s3_key,
                ExtraArgs={"ContentType": file.content_type},
            )
        print(f"[Upload] Stored at s3://{settings.S3_BUCKET_CROPS}/{s3_key}")

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {e}")
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)

    # ── Trigger AI in background ──────────────────────────────────────────────
    if AI_MODEL_AVAILABLE:
        thread = threading.Thread(
            target=_run_prediction_async,
            args=(farmer_id, s3_key),
            daemon=True,
        )
        thread.start()
        ai_status = "processing"
        message = "Image accepted. AI analysis running. Poll GET /farmers/{farmer_id}/predictions for results."
    else:
        ai_status = "unavailable"
        message = "Image uploaded. AI model not loaded on this server."

    return {
        "farmer_id": farmer_id,
        "s3_key": s3_key,
        "s3_url": f"s3://{settings.S3_BUCKET_CROPS}/{s3_key}",
        "ai_status": ai_status,
        "quality_metrics": validation.details,
        "message": message,
    }


@router.get("/uploads/{farmer_id}")
def get_farmer_uploads(farmer_id: str):
    """List all uploaded images for a farmer from S3."""
    try:
        response = get_s3().list_objects_v2(
            Bucket=settings.S3_BUCKET_CROPS,
            Prefix=f"crops/{farmer_id}/",
        )
        files = [
            {
                "s3_key": obj["Key"],
                "uploaded_at": obj["LastModified"].isoformat(),
                "size_kb": round(obj["Size"] / 1024, 2),
            }
            for obj in response.get("Contents", [])
        ]
        return {"farmer_id": farmer_id, "uploads": files}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to list uploads: {e}")
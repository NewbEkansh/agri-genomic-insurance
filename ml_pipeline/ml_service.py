"""
ml_service.py
-------------
YieldShield AI inference service.
Called by the backend's images.py after downloading the crop image from S3.

Input:  local image path (temp file), soil_temp, soil_moisture, ndvi
Output: (disease_type, confidence_score, affected_area_percent)

Model files expected at:
  agri-genomic-insurance/ml_pipeline/models/yolov8_disease_classifier.pt
  agri-genomic-insurance/ml_pipeline/models/xgboost_yield_model.pkl

If model files are missing, falls back to mock values so the
backend pipeline still runs end-to-end without crashing.
"""

import os
import sys
import numpy as np

# ── Resolve model paths relative to this file ─────────────────────────────────
# Works regardless of where the file is called from (EC2, local, tests)
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(CURRENT_DIR, "models")
VISION_MODEL_PATH = os.path.join(MODELS_DIR, "yolov8_disease_classifier.pt")
TABULAR_MODEL_PATH = os.path.join(MODELS_DIR, "xgboost_yield_model.pkl")

# ── Load models at import time (once, not per request) ────────────────────────
vision_model = None
xgb_model = None

def _load_models():
    global vision_model, xgb_model

    # Vision model (YOLOv8)
    if os.path.exists(VISION_MODEL_PATH):
        try:
            from ultralytics import YOLO
            vision_model = YOLO(VISION_MODEL_PATH)
            print(f"✅ YOLOv8 model loaded from {VISION_MODEL_PATH}")
        except Exception as e:
            print(f"⚠️  YOLOv8 load failed: {e} — will use mock")
    else:
        print(f"⚠️  YOLOv8 model not found at {VISION_MODEL_PATH} — will use mock")

    # Tabular model (XGBoost)
    if os.path.exists(TABULAR_MODEL_PATH):
        try:
            import joblib
            xgb_model = joblib.load(TABULAR_MODEL_PATH)
            print(f"✅ XGBoost model loaded from {TABULAR_MODEL_PATH}")
        except Exception as e:
            print(f"⚠️  XGBoost load failed: {e} — will use fallback")
    else:
        print(f"⚠️  XGBoost model not found at {TABULAR_MODEL_PATH} — will use fallback")


_load_models()


# ── Disease label normalisation ───────────────────────────────────────────────
# YOLOv8 class names may vary — map them to your standard disease_type strings
# that the backend and blockchain use. Add more as your model's classes expand.

DISEASE_NAME_MAP = {
    # Common variants from PlantVillage-trained models
    "Bacterial_spot":               "bacterial_spot",
    "Early_blight":                 "early_blight",
    "Late_blight":                  "late_blight",
    "Leaf_Mold":                    "leaf_mold",
    "Septoria_leaf_spot":           "septoria_leaf_spot",
    "Spider_mites":                 "spider_mites",
    "Target_Spot":                  "target_spot",
    "Tomato_Yellow_Leaf_Curl_Virus":"yellow_leaf_curl_virus",
    "Tomato_mosaic_virus":          "mosaic_virus",
    "healthy":                      "healthy",
    # Rice diseases
    "rice_blast":                   "rice_blast",
    "brown_spot":                   "brown_spot",
    "leaf_blight":                  "leaf_blight",
    # Maize
    "Northern_Leaf_Blight":         "northern_leaf_blight",
    "Common_rust":                  "common_rust",
    "Gray_leaf_spot":               "gray_leaf_spot",
}

def _normalise_disease(raw_label: str) -> str:
    """Convert YOLOv8 class name to standardised snake_case disease type."""
    return DISEASE_NAME_MAP.get(raw_label, raw_label.lower().replace(" ", "_"))


# ── Mock fallback ─────────────────────────────────────────────────────────────

def _mock_prediction(image_path: str) -> tuple[str, float, float]:
    """
    Returns a deterministic mock based on image file size.
    Different images give slightly different results so testing feels real.
    Used when model files are not present.
    """
    try:
        size = os.path.getsize(image_path)
        # Use file size to vary the mock output
        confidence = 0.85 + (size % 10) * 0.01      # 0.85 - 0.94
        area = 0.50 + (size % 20) * 0.02             # 0.50 - 0.88
        diseases = ["rice_blast", "brown_spot", "leaf_blight", "early_blight"]
        disease = diseases[size % len(diseases)]
        return disease, round(confidence, 4), round(min(area, 1.0), 4)
    except Exception:
        return "rice_blast", 0.91, 0.65


# ── Main inference function ───────────────────────────────────────────────────

def analyze_farm(
    image_path: str,
    soil_temp: float,
    soil_moisture: float,
    ndvi: float,
) -> tuple[str, float, float]:
    """
    Run YOLOv8 + XGBoost inference on a crop image.

    Args:
        image_path:    Path to a local image file (JPEG/PNG).
                       The backend downloads from S3 to a temp file before calling this.
        soil_temp:     Soil temperature in Celsius (from Agromonitoring).
        soil_moisture: Soil moisture as percentage 0-100 (from Agromonitoring, already * 100).
        ndvi:          Current NDVI value -1 to 1 (from Agromonitoring).

    Returns:
        Tuple of (disease_type: str, confidence_score: float, affected_area_percent: float)
        - disease_type:          snake_case string e.g. "rice_blast"
        - confidence_score:      0.0 to 1.0
        - affected_area_percent: 0.0 to 1.0 (fraction of farm affected)
    """
    # ── 1. Vision model (YOLOv8 classification) ───────────────────────────────
    if vision_model is None:
        print(f"[ML] No vision model — using mock for {image_path}")
        return _mock_prediction(image_path)

    try:
        results = vision_model(image_path, verbose=False)
        top_class_index = results[0].probs.top1
        raw_label = results[0].names[top_class_index]
        disease_type = _normalise_disease(raw_label)
        confidence_score = float(results[0].probs.top1conf)

        print(f"[ML] Vision: raw_label={raw_label}, disease={disease_type}, confidence={confidence_score:.3f}")

    except Exception as e:
        print(f"[ML] Vision model inference failed: {e} — using mock")
        return _mock_prediction(image_path)

    # ── 2. Tabular model (XGBoost yield prediction → affected area) ───────────
    try:
        if xgb_model is None:
            raise FileNotFoundError("XGBoost model not loaded")

        import pandas as pd
        features = pd.DataFrame({
            "crop_variety":               [0],
            "genomic_drought_resistance": [0.5],
            "genomic_disease_resistance": [0.5],
            "avg_temperature":            [soil_temp],
            "total_rainfall_mm":          [soil_moisture * 10],   # moisture % → proxy mm
            "satellite_ndvi":             [ndvi],
            "disease_severity":           [confidence_score],
        })

        predicted_yield = float(xgb_model.predict(features)[0])
        # Convert predicted yield (0-100 scale) to affected area fraction
        # Low yield → high affected area
        affected_area = float(np.clip((100.0 - predicted_yield) / 100.0, 0.0, 1.0))
        print(f"[ML] XGBoost: predicted_yield={predicted_yield:.1f}, affected_area={affected_area:.3f}")

    except Exception as e:
        print(f"[ML] XGBoost inference failed: {e} — using confidence-based fallback")
        # Fallback: derive affected area from confidence + NDVI
        # High confidence + low NDVI = large affected area
        ndvi_factor = max(0.0, 1.0 - ndvi)      # low NDVI → high factor
        affected_area = float(np.clip(confidence_score * 0.7 + ndvi_factor * 0.3, 0.0, 1.0))

    return disease_type, round(confidence_score, 4), round(affected_area, 4)


# ── Standalone test ───────────────────────────────────────────────────────────

if __name__ == "__main__":
    import sys
    test_img = sys.argv[1] if len(sys.argv) > 1 else os.path.join(CURRENT_DIR, "data", "test_leaf.jpg")

    if not os.path.exists(test_img):
        print(f"Test image not found at {test_img}")
        print("Usage: python ml_service.py path/to/image.jpg")
        sys.exit(1)

    print(f"\nRunning inference on: {test_img}")
    disease, conf, area = analyze_farm(
        image_path=test_img,
        soil_temp=30.0,
        soil_moisture=50.0,
        ndvi=0.6,
    )
    print(f"\n{'='*40}")
    print(f"Disease:        {disease}")
    print(f"Confidence:     {conf:.2%}")
    print(f"Affected Area:  {area:.2%}")
    print(f"{'='*40}")
    print(f"\nPayout triggered: {conf >= 0.85}")
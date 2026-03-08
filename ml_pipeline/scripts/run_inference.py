import os
import requests
import joblib
import pandas as pd
import numpy as np
from ultralytics import YOLO # <-- NEW: Importing your vision library!

# --- CONFIGURATION (Get these from your backend teammate!) ---
API_BASE = "http://localhost:8000"  
API_KEY = "yieldshield-dev-key"     
FARM_ID = "paste-farmer-id-here"    # Must be a pre-registered DB uuid
# -------------------------------------------------------------

def run_insurance_pipeline():
    print("🚀 Starting YieldGuard Inference Pipeline...")
    current_dir = os.path.dirname(os.path.abspath(__file__))

    # 1. FETCH FARM DATA FROM BACKEND
    print(f"📡 Fetching live satellite/soil data for Farm ID: {FARM_ID}...")
    try:
        r = requests.get(f"{API_BASE}/farmers/{FARM_ID}/farm-health")
        r.raise_for_status()
        farm_data = r.json()
        
        ndvi = farm_data.get('current_ndvi', 0.8)
        soil_moisture = farm_data.get('soil_data', {}).get('soil_moisture', 50)
        soil_temp = farm_data.get('soil_data', {}).get('soil_temp_celsius', 30)
        
        print(f"✅ Data received -> NDVI: {ndvi}, Moisture: {soil_moisture}, Temp: {soil_temp}°C")
    except Exception as e:
        print(f"❌ Failed to reach backend: {e}. Is the server running?")
        return

    # 2. RUN ML INFERENCE
    print("\n🧠 Running ML Models...")
    
    # --- A. Tabular Model (Yield Prediction) ---
    try:
        tabular_path = os.path.join(current_dir, '..', 'models', 'xgboost_yield_model.pkl')
        xgb_model = joblib.load(tabular_path)
        
        features = pd.DataFrame({
            'crop_variety': [0], 
            'genomic_drought_resistance': [0.5],
            'genomic_disease_resistance': [0.5],
            'avg_temperature': [soil_temp],
            'total_rainfall_mm': [soil_moisture * 10], 
            'satellite_ndvi': [ndvi],
            'disease_severity': [0.8] 
        })
        
        predicted_yield = xgb_model.predict(features)[0]
        affected_area = float(np.clip((100 - predicted_yield) / 100, 0.0, 1.0))
        print(f"📊 XGBoost Predicted Yield Loss Area: {affected_area:.2f}")
    except FileNotFoundError:
        print("⚠️ XGBoost model not found. Using default affected area.")
        affected_area = 0.65

    # --- B. Vision Model (YOUR NEW YOLOv8 BRAIN!) ---
    try:
        vision_model_path = os.path.join(current_dir, '..', 'models', 'yolov8_disease_classifier.pt')
        test_image_path = os.path.join(current_dir, '..', 'data', 'test_leaf.jpg')
        
        print(f"👁️ Analyzing crop image with YOLOv8...")
        vision_model = YOLO(vision_model_path)
        
        # Run inference on the image
        results = vision_model(test_image_path, verbose=False)
        
        # Extract the top predicted class and its confidence score
        top_class_index = results[0].probs.top1
        disease_type = results[0].names[top_class_index]
        confidence_score = float(results[0].probs.top1conf)
        
        print(f"✅ Vision AI detected: '{disease_type}' with {confidence_score:.2f} confidence!")
        
    except Exception as e:
        print(f"❌ Vision Model Error: {e}")
        return

    # 3. POST RESULTS TO BACKEND
    print(f"\n💸 Sending prediction to backend to trigger smart contract...")
    payload = {
        "farm_id": FARM_ID,
        "disease_type": disease_type,
        "confidence_score": confidence_score,
        "affected_area_percent": affected_area,
        "model_version": "v1.0"
    }
    
    headers = {
        "X-API-Key": API_KEY,
        "Content-Type": "application/json"
    }
    
    post_response = requests.post(f"{API_BASE}/predictions/score", headers=headers, json=payload)
    
    # 4. READ THE RESPONSE
    if post_response.status_code == 200:
        result = post_response.json()
        print("\n🎉 BACKEND RESPONSE SUCCESS:")
        print(f"💰 Payout Triggered: {result.get('payout_triggered')}")
        print(f"⚖️ Fraud Multiplier: {result.get('payout_multiplier')}")
        print(f"🔗 DynamoDB Payout ID: {result.get('payout_id')}")
    else:
        print(f"\n❌ ERROR {post_response.status_code}: {post_response.text}")

if __name__ == "__main__":
    run_insurance_pipeline()
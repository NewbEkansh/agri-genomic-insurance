import pandas as pd
import numpy as np
import os

def generate_agri_data(num_samples=5000):
    np.random.seed(42) # For reproducibility
    
    # 1. Base Farm & Genomic Features
    farm_ids = [f"FARM_{i:04d}" for i in range(num_samples)]
    crop_varieties = np.random.choice(['IR-64 (Standard)', 'Swarna-Sub1 (Flood Tolerant)', 'Sahbhagi-Dhan (Drought Tolerant)'], num_samples)
    
    # Genomic Traits (0.0 to 1.0)
    drought_resistance = np.where(crop_varieties == 'Sahbhagi-Dhan (Drought Tolerant)', np.random.uniform(0.7, 1.0, num_samples), np.random.uniform(0.1, 0.5, num_samples))
    disease_resistance = np.random.uniform(0.2, 0.8, num_samples)
    
    # 2. Macro Environmental Features (The Oracle Data)
    # Average temp in Celsius (20 to 40)
    avg_temperature = np.random.normal(30, 4, num_samples) 
    # Total seasonal rainfall in mm (100 is severe drought, 1000 is flood)
    total_rainfall_mm = np.random.normal(500, 200, num_samples)
    
    # 3. Micro Features (What the Vision model would output over a season)
    disease_severity = np.random.beta(a=2, b=5, size=num_samples) # Skewed towards lower severity
    
    # 4. Calculate Satellite NDVI (Vegetation Health Index 0.0 to 1.0)
    # NDVI drops if rainfall is low, temp is extreme, or disease is high
    ndvi_base = 0.8
    rain_penalty = np.where(total_rainfall_mm < 300, (300 - total_rainfall_mm) / 300, 0)
    disease_penalty = disease_severity * 0.4
    satellite_ndvi = np.clip(ndvi_base - rain_penalty - disease_penalty + np.random.normal(0, 0.05, num_samples), 0.1, 0.95)

    # 5. Calculate Target Variable: Yield Percentage (0 to 100%)
    # This is what our XGBoost model will try to predict!
    yield_base = 100.0
    
    # Drought logic: if rain is low, yield drops heavily, UNLESS drought resistance is high
    drought_impact = np.where(total_rainfall_mm < 300, (300 - total_rainfall_mm) * (1 - drought_resistance), 0)
    
    # Disease logic: yield drops based on disease severity, buffered by disease resistance
    disease_impact = (disease_severity * 100) * (1 - disease_resistance)
    
    # Heat stress
    heat_impact = np.where(avg_temperature > 35, (avg_temperature - 35) * 5, 0)

    # Final Yield Calculation
    yield_percentage = yield_base - drought_impact - disease_impact - heat_impact + np.random.normal(0, 5, num_samples)
    yield_percentage = np.clip(yield_percentage, 0, 100) # Keep between 0 and 100

    # Create DataFrame
    df = pd.DataFrame({
        'farm_id': farm_ids,
        'crop_variety': crop_varieties,
        'genomic_drought_resistance': np.round(drought_resistance, 2),
        'genomic_disease_resistance': np.round(disease_resistance, 2),
        'avg_temperature': np.round(avg_temperature, 1),
        'total_rainfall_mm': np.round(total_rainfall_mm, 1),
        'satellite_ndvi': np.round(satellite_ndvi, 3),
        'disease_severity': np.round(disease_severity, 2),
        'yield_percentage': np.round(yield_percentage, 1)
    })
    
    return df

if __name__ == "__main__":
    print("🚜 Generating Mock Agri-Genomic Dataset...")
    df = generate_agri_data(5000)
    
    # Save to the data folder
    os.makedirs('data', exist_ok=True)
    file_path = os.path.join('data', 'synthetic_yield_data.csv')
    df.to_csv(file_path, index=False)
    
    print(f"✅ Successfully generated 5000 records and saved to {file_path}")
    print("\nSample Data:")
    print(df.head())
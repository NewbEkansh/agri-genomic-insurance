from ultralytics import YOLO
import os

def train_disease_model():
    print("👁️ Starting YOLOv8 Vision Model Training...")

    # 1. Define paths
    current_dir = os.path.dirname(os.path.abspath(__file__))
    # Assuming this script is in ml_pipeline/scripts/
    yaml_path = os.path.abspath(os.path.join(current_dir, '..', 'data', 'raw', 'data.yaml'))
    models_dir = os.path.abspath(os.path.join(current_dir, '..', 'models'))

    if not os.path.exists(yaml_path):
        print(f"❌ Error: Cannot find data.yaml at {yaml_path}")
        print("Please ensure you extracted the Roboflow YOLOv8 zip into ml_pipeline/data/raw/")
        return

    print(f"✅ Found dataset config at: {yaml_path}")

    # 2. Load the pre-trained YOLOv8 Nano model
    # The 'nano' model is the fastest and best for mobile/edge deployments
    model = YOLO('yolov8n.pt') 

    # 3. Train the model
    print("🧠 Training YOLOv8... This might take a while depending on your hardware!")
    results = model.train(
        data=yaml_path,
        epochs=25,          # 25 is a good baseline for a hackathon (takes less time)
        imgsz=640,          # Standard image size for YOLO
        batch=16,           # Lower this to 8 if your computer runs out of memory
        project=models_dir, # Where to save the output
        name='yolov8_rice_disease',
        device='cpu'        # Change this to '0' if you have an NVIDIA GPU!
    )

    print(f"🎉 Training Complete! Your model weights are saved in {models_dir}/yolov8_rice_disease/weights/best.pt")

if __name__ == '__main__':
    train_disease_model()
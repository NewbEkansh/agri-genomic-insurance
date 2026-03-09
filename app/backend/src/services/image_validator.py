"""
image_validator.py
------------------
Validates crop image quality before passing to AI model.
Rejects images that are too blurry, too dark/bright, or too low resolution.

Farmers with basic Android phones will often submit:
  - Blurry images (shaky hands, moving crop)
  - Dark images (poor lighting, indoors)
  - Washed out images (direct sunlight)
  - Very low resolution images

We catch these early and return a clear rejection reason
so the frontend can ask the farmer to retake the photo.

Requires: pip install opencv-python-headless numpy
"""

import cv2
import numpy as np
from dataclasses import dataclass


@dataclass
class ValidationResult:
    is_valid: bool
    reason: str         # human-readable, can be shown to farmer
    details: dict       # raw metrics for logging


# ── Thresholds (tuned for crop field photos) ──────────────────────────────────

MIN_WIDTH = 224          # minimum pixels — matches YOLOv8 input size
MIN_HEIGHT = 224
BLUR_THRESHOLD = 80.0    # Laplacian variance below this = too blurry
                         # Clear photo: ~500+, Slightly blurry: ~100-500, Very blurry: <100
MIN_BRIGHTNESS = 30      # 0-255 scale, below this = too dark
MAX_BRIGHTNESS = 230     # above this = overexposed
MIN_CONTRAST = 20        # std deviation of pixel values, below = flat/foggy image


def validate_image(image_path: str) -> ValidationResult:
    """
    Validates an image file for quality.

    Returns ValidationResult with is_valid=True if the image is usable,
    or is_valid=False with a farmer-friendly reason if it should be rejected.
    """
    # ── Load image ────────────────────────────────────────────────────────────
    img = cv2.imread(image_path)
    if img is None:
        return ValidationResult(
            is_valid=False,
            reason="Could not read image. Please try taking the photo again.",
            details={"error": "cv2.imread returned None"},
        )

    height, width = img.shape[:2]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # ── 1. Resolution check ───────────────────────────────────────────────────
    if width < MIN_WIDTH or height < MIN_HEIGHT:
        return ValidationResult(
            is_valid=False,
            reason=f"Image is too small ({width}x{height}). Please take a closer photo of the crop.",
            details={"width": width, "height": height, "min_required": f"{MIN_WIDTH}x{MIN_HEIGHT}"},
        )

    # ── 2. Blur check (Laplacian variance) ────────────────────────────────────
    blur_score = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    if blur_score < BLUR_THRESHOLD:
        return ValidationResult(
            is_valid=False,
            reason="Image is too blurry. Please hold the phone steady and retake the photo.",
            details={"blur_score": round(blur_score, 2), "threshold": BLUR_THRESHOLD},
        )

    # ── 3. Brightness check ───────────────────────────────────────────────────
    brightness = float(np.mean(gray))
    if brightness < MIN_BRIGHTNESS:
        return ValidationResult(
            is_valid=False,
            reason="Image is too dark. Please take the photo in better lighting.",
            details={"brightness": round(brightness, 2), "min": MIN_BRIGHTNESS},
        )
    if brightness > MAX_BRIGHTNESS:
        return ValidationResult(
            is_valid=False,
            reason="Image is overexposed. Please avoid direct sunlight or flash when taking the photo.",
            details={"brightness": round(brightness, 2), "max": MAX_BRIGHTNESS},
        )

    # ── 4. Contrast check ────────────────────────────────────────────────────
    contrast = float(np.std(gray))
    if contrast < MIN_CONTRAST:
        return ValidationResult(
            is_valid=False,
            reason="Image appears flat or foggy. Please take a clearer photo of the crop leaves.",
            details={"contrast": round(contrast, 2), "min": MIN_CONTRAST},
        )

    # ── All checks passed ─────────────────────────────────────────────────────
    return ValidationResult(
        is_valid=True,
        reason="Image quality is acceptable",
        details={
            "width": width,
            "height": height,
            "blur_score": round(blur_score, 2),
            "brightness": round(brightness, 2),
            "contrast": round(contrast, 2),
        },
    )
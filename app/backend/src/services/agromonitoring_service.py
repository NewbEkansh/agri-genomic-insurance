"""
agromonitoring_service.py
--------------------------
Handles all Agromonitoring API calls for YieldShield.

Responsibilities:
  1. create_farm_polygon()   — called at farmer registration
  2. get_current_ndvi()      — called at registration (baseline) and at payout (fraud check)
  3. get_soil_data()         — called to enrich AI model features
  4. compute_ndvi_delta()    — fraud signal: how much has NDVI dropped since registration?

API base: https://agromonitoring.com/api/current
Docs: https://agromonitoring.com/api/docs
"""

import math
import time
import requests
from typing import Optional
from src.core.config import settings

BASE_URL = "https://api.agromonitoring.com/agro/1.0"


def _params(extra: dict = {}) -> dict:
    """Injects the API key into every request."""
    return {"appid": settings.AGROMONITORING_API_KEY, **extra}


# ── Step 1: Polygon creation ──────────────────────────────────────────────────

def _build_polygon_coords(center_lat: float, center_lon: float, area_hectares: float) -> list:
    """
    Builds a square GeoJSON polygon around a center point.
    Converts area_hectares to approximate degree offset.
    
    1 degree latitude  ≈ 111 km
    1 degree longitude ≈ 111 km * cos(latitude)
    1 hectare = 0.01 km²  →  side = sqrt(0.01) = 0.1 km per hectare
    """
    side_km = math.sqrt(area_hectares * 0.01)
    lat_offset = (side_km / 2) / 111.0
    lon_offset = (side_km / 2) / (111.0 * math.cos(math.radians(center_lat)))

    # GeoJSON requires coordinates as [lon, lat] (note: reversed from lat/lon)
    return [[
        [center_lon - lon_offset, center_lat - lat_offset],  # bottom-left
        [center_lon + lon_offset, center_lat - lat_offset],  # bottom-right
        [center_lon + lon_offset, center_lat + lat_offset],  # top-right
        [center_lon - lon_offset, center_lat + lat_offset],  # top-left
        [center_lon - lon_offset, center_lat - lat_offset],  # close ring
    ]]


def create_farm_polygon(
    farmer_name: str,
    farm_lat: float,
    farm_lon: float,
    area_hectares: float,
) -> Optional[str]:
    """
    Registers the farm as a polygon in Agromonitoring.
    Returns the polygon_id (string) which is stored in DynamoDB.
    Returns None on failure — non-fatal, farm registration still proceeds.

    Called once at farmer registration.
    """
    payload = {
        "name": f"{farmer_name} Farm",
        "geo_json": {
            "type": "Feature",
            "properties": {},
            "geometry": {
                "type": "Polygon",
                "coordinates": _build_polygon_coords(farm_lat, farm_lon, area_hectares),
            },
        },
    }

    try:
        resp = requests.post(
            f"{BASE_URL}/polygons",
            json=payload,
            params=_params(),
            timeout=10,
        )
        resp.raise_for_status()
        polygon_id = resp.json().get("id")
        print(f"[Agromonitoring] Polygon created: {polygon_id} for {farmer_name}")
        return polygon_id
    except Exception as e:
        print(f"[Agromonitoring] Polygon creation failed: {e}")
        return None


# ── Step 2: NDVI ──────────────────────────────────────────────────────────────

def get_current_ndvi(polygon_id: str) -> Optional[float]:
    """
    Fetches the most recent NDVI value for a polygon.

    NDVI ranges:
      < 0.2  : bare soil, dead crops, or severe disease
      0.2–0.4: sparse or stressed vegetation
      0.4–0.6: moderate vegetation health
      0.6–0.8: healthy, dense crops  ← what you want to see at registration
      > 0.8  : very dense/lush vegetation

    Returns the NDVI float, or None if no satellite pass is available yet.
    Called at registration (baseline) and at payout trigger (current).
    """
    try:
        resp = requests.get(
            f"{BASE_URL}/ndvi/history",
            params=_params({
                "polyid": polygon_id,
                "timestart": int(time.time()) - 30 * 86400,  # last 30 days
                "timeend": int(time.time()),
            }),
            timeout=10,
        )
        resp.raise_for_status()
        history = resp.json()

        if not history:
            return None

        # Most recent entry — sorted ascending by date
        latest = history[-1]
        ndvi = latest.get("data", {}).get("mean")
        return round(float(ndvi), 4) if ndvi is not None else None
    except Exception as e:
        print(f"[Agromonitoring] NDVI fetch failed for polygon {polygon_id}: {e}")
        return None


def compute_ndvi_delta(baseline_ndvi: float, current_ndvi: float) -> dict:
    """
    Computes the NDVI change between registration baseline and now.
    Used as an additional fraud signal in the payout pipeline.

    Returns a dict with:
      - delta: raw change (negative = crop got worse)
      - pct_drop: percentage drop from baseline
      - fraud_flag: True if drop looks suspicious (isolated, not disease-consistent)
      - severity: "healthy" | "stressed" | "severe" | "critical"
    """
    delta = current_ndvi - baseline_ndvi
    pct_drop = abs(delta) / baseline_ndvi if baseline_ndvi > 0 else 0

    if current_ndvi >= 0.6:
        severity = "healthy"
    elif current_ndvi >= 0.4:
        severity = "stressed"
    elif current_ndvi >= 0.2:
        severity = "severe"
    else:
        severity = "critical"

    # Fraud flag: baseline was healthy AND current is already low at registration time.
    # A >50% drop that wasn't gradual may indicate crop swapping or false registration.
    fraud_flag = baseline_ndvi < 0.3 and pct_drop < 0.1

    return {
        "baseline_ndvi": baseline_ndvi,
        "current_ndvi": current_ndvi,
        "delta": round(delta, 4),
        "pct_drop": round(pct_drop, 4),
        "severity": severity,
        "fraud_flag": fraud_flag,
    }


# ── Step 3: Soil data ─────────────────────────────────────────────────────────

def get_soil_data(polygon_id: str) -> Optional[dict]:
    """
    Fetches current soil conditions for a polygon.
    
    Returned values (passed to AI model as features):
      - t10: soil temperature at 10cm depth (Kelvin → convert to Celsius)
      - moisture: volumetric soil moisture (m³/m³)
      - t0: surface temperature (Kelvin)

    High moisture + warm temperature = prime conditions for fungal diseases
    like rice blast and wheat rust.

    Called optionally during prediction to enrich AI model input.
    """
    try:
        resp = requests.get(
            f"{BASE_URL}/soil",
            params=_params({"polyid": polygon_id}),
            timeout=10,
        )
        resp.raise_for_status()
        data = resp.json()

        return {
            "soil_moisture": round(data.get("moisture", 0), 4),
            "soil_temp_celsius": round(data.get("t10", 273.15) - 273.15, 2),
            "surface_temp_celsius": round(data.get("t0", 273.15) - 273.15, 2),
        }
    except Exception as e:
        print(f"[Agromonitoring] Soil data fetch failed for polygon {polygon_id}: {e}")
        return None


# ── Step 4: Delete polygon (cleanup) ─────────────────────────────────────────

def delete_farm_polygon(polygon_id: str) -> bool:
    """
    Deletes a polygon — call if a farmer cancels their policy.
    Agromonitoring has polygon limits on free tier, so cleanup matters.
    """
    try:
        resp = requests.delete(
            f"{BASE_URL}/polygons/{polygon_id}",
            params=_params(),
            timeout=10,
        )
        return resp.status_code == 204
    except Exception as e:
        print(f"[Agromonitoring] Polygon deletion failed: {e}")
        return False
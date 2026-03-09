"""
auth.py
-------
Phone-based OTP authentication for farmers.

Flow:
  POST /auth/send-otp    → sends 6-digit OTP via SMS
  POST /auth/verify-otp  → verifies OTP, returns JWT + farmer_id + is_new_farmer flag
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from src.services.otp_service import generate_and_send_otp, verify_otp
from src.core.security import create_jwt_token
from src.db import schemas as db

router = APIRouter()


# ── Request / Response models ─────────────────────────────────────────────────

class SendOTPRequest(BaseModel):
    phone: str      # E.164 format: +919876543210


class VerifyOTPRequest(BaseModel):
    phone: str
    otp: str


class AuthResponse(BaseModel):
    token: str
    farmer_id: str | None       # None if new farmer (not registered yet)
    is_new_farmer: bool
    message: str


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/send-otp")
def send_otp(payload: SendOTPRequest):
    """
    Step 1: Sends a 6-digit OTP to the farmer's phone number.
    Frontend shows OTP input screen after calling this.
    """
    if not payload.phone.startswith("+"):
        raise HTTPException(
            status_code=400,
            detail="Phone number must be in E.164 format e.g. +919876543210"
        )

    success = generate_and_send_otp(payload.phone)
    if not success:
        raise HTTPException(status_code=500, detail="Failed to send OTP. Try again.")

    return {"message": f"OTP sent to {payload.phone}", "phone": payload.phone}


@router.post("/verify-otp", response_model=AuthResponse)
def verify_otp_and_login(payload: VerifyOTPRequest):
    """
    Step 2: Verifies the OTP.

    If valid:
      - Issues a JWT token
      - Checks if farmer is already registered
      - Returns is_new_farmer=True if they need to complete registration

    Frontend flow:
      - If is_new_farmer=True  → show registration form → POST /farmers/register
      - If is_new_farmer=False → go straight to dashboard
    """
    if not verify_otp(payload.phone, payload.otp):
        raise HTTPException(status_code=401, detail="Invalid or expired OTP")

    # Check if farmer already exists with this phone
    existing_farmer = _get_farmer_by_phone(payload.phone)

    if existing_farmer:
        farmer_id = existing_farmer["farmer_id"]
        token = create_jwt_token(farmer_id=farmer_id, phone=payload.phone)
        return AuthResponse(
            token=token,
            farmer_id=farmer_id,
            is_new_farmer=False,
            message="Login successful",
        )
    else:
        # New farmer — issue token without farmer_id yet
        # farmer_id will be created during POST /farmers/register
        token = create_jwt_token(farmer_id="pending", phone=payload.phone)
        return AuthResponse(
            token=token,
            farmer_id=None,
            is_new_farmer=True,
            message="OTP verified. Please complete registration.",
        )


# ── Helper ────────────────────────────────────────────────────────────────────

def _get_farmer_by_phone(phone: str) -> dict | None:
    """Scan farmers table for a matching phone number."""
    from boto3.dynamodb.conditions import Attr
    from src.db.dynamodb import get_table
    from src.core.config import settings

    table = get_table(settings.TABLE_FARMERS)
    resp = table.scan(
        FilterExpression=Attr("phone").eq(phone),
        Limit=1,
    )
    items = resp.get("Items", [])
    return items[0] if items else None
"""
security.py
-----------
JWT token creation and verification.
Tokens are issued after successful OTP verification and
must be included in the Authorization header for protected routes.

Header format: Authorization: Bearer <token>
"""

from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt

# ── Config ────────────────────────────────────────────────────────────────────
# In production move this to Secrets Manager. Fine in .env for hackathon.
JWT_SECRET = "yieldshield-jwt-secret-change-in-production"
JWT_ALGORITHM = "HS256"
JWT_EXPIRY_HOURS = 24 * 7   # 7 days — farmer stays logged in

_bearer_scheme = HTTPBearer(auto_error=False)


# ── Token creation ────────────────────────────────────────────────────────────

def create_jwt_token(farmer_id: str, phone: str) -> str:
    """
    Creates a signed JWT containing farmer_id and phone.
    Returned to the frontend after OTP verification.
    """
    payload = {
        "farmer_id": farmer_id,
        "phone": phone,
        "exp": datetime.now(timezone.utc) + timedelta(hours=JWT_EXPIRY_HOURS),
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


# ── Token verification ────────────────────────────────────────────────────────

def decode_jwt_token(token: str) -> dict:
    """Decodes and validates a JWT token. Raises HTTPException on failure."""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired. Please log in again.",
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token.",
        )


# ── FastAPI dependency ────────────────────────────────────────────────────────

def get_current_farmer(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(_bearer_scheme),
) -> dict:
    """
    FastAPI dependency for protected routes.
    Usage: add `farmer: dict = Depends(get_current_farmer)` to route signature.
    Returns the decoded JWT payload containing farmer_id and phone.
    """
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header missing.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return decode_jwt_token(credentials.credentials)


# ── Internal API key (for AI pipeline → /predictions/score) ──────────────────

from fastapi import Security
from fastapi.security import APIKeyHeader

_API_KEY_HEADER = APIKeyHeader(name="X-API-Key", auto_error=False)


def require_internal_key(api_key: str = Security(_API_KEY_HEADER)):
    from src.core.config import settings
    if api_key != settings.INTERNAL_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or missing internal API key",
        )
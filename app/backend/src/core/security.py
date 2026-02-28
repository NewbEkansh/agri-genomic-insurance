"""
security.py
-----------
Simple API key guard for the /predictions/score endpoint.
The AI pipeline must include this key in the X-API-Key header when
POSTing risk scores — prevents random callers from triggering payouts.

"""

from fastapi import Security, HTTPException, status
from fastapi.security import APIKeyHeader
from app.core.config import settings  # noqa: F401 — extend settings if needed

API_KEY_HEADER = APIKeyHeader(name="X-API-Key", auto_error=False)

# Store in .env as INTERNAL_API_KEY — share with AI teammate
INTERNAL_API_KEY = "yieldshield-internal-dev-key"  # override via env var


def verify_internal_key(api_key: str = Security(API_KEY_HEADER)):
    if api_key != INTERNAL_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or missing API key",
        )
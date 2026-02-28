"""
deps.py
-------
FastAPI dependency injection for shared resources.
Import these in route files using Depends().
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import APIKeyHeader
from src.core.config import settings

# ── Internal API key (for AI pipeline → /predictions/score) ──────────────────

_API_KEY_HEADER = APIKeyHeader(name="X-API-Key", auto_error=False)

INTERNAL_API_KEY = "yieldshield-dev-key"   # Override in .env as INTERNAL_API_KEY


def require_internal_key(api_key: str = Depends(_API_KEY_HEADER)):
    """
    Dependency for routes that should only be called by internal services
    (e.g., the AI pipeline posting prediction scores).
    Usage: add `_: None = Depends(require_internal_key)` to route signature.
    """
    if api_key != INTERNAL_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or missing internal API key",
        )
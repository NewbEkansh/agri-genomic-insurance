from fastapi import APIRouter
from src.db.dynamodb import get_dynamodb_resource
from src.core.config import settings

router = APIRouter()


@router.get("/")
def health_check():
    return {"status": "ok", "service": "YieldShield API", "env": settings.APP_ENV}


@router.get("/db")
def db_health():
    """Verify DynamoDB connectivity — useful for debugging deployment."""
    try:
        db = get_dynamodb_resource()
        tables = list(db.tables.all())
        table_names = [t.name for t in tables]
        return {
            "status": "ok",
            "dynamodb": "connected",
            "tables_found": table_names,
        }
    except Exception as e:
        return {"status": "error", "dynamodb": str(e)}
from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum
import uuid
from datetime import datetime, timezone
from src.db.dynamodb import floats_to_decimal


class CropType(str, Enum):
    WHEAT = "wheat"
    RICE = "rice"
    MAIZE = "maize"
    COTTON = "cotton"
    SOYBEAN = "soybean"


class Language(str, Enum):
    HINDI = "hindi"
    TAMIL = "tamil"
    TELUGU = "telugu"
    MARATHI = "marathi"
    BENGALI = "bengali"
    ENGLISH = "english"


class FarmerCreate(BaseModel):
    """
    Registration form filled by farmer.
    No wallet_address needed — backend creates it automatically.
    """
    name: str
    phone: str                              # Must match the phone used for OTP
    crop_type: CropType
    farm_lat: float
    farm_lon: float
    farm_area_hectares: float
    language: Language = Language.HINDI


class FarmerDB(FarmerCreate):
    """Full farmer record as stored in DynamoDB."""
    farmer_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    wallet_address: Optional[str] = None   # Auto-assigned by wallet_service
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    baseline_ndvi: Optional[float] = None
    agro_polygon_id: Optional[str] = None

    def to_dynamo(self) -> dict:
        return floats_to_decimal(self.model_dump())
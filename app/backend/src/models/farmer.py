from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum
import uuid
from datetime import datetime, timezone


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
    """Request body for registering a new farmer."""
    name: str
    phone: str                              # E.164 format: +919876543210
    wallet_address: str                     # Farmer's MetaMask / Sepolia wallet
    crop_type: CropType
    farm_lat: float
    farm_lon: float
    farm_area_hectares: float
    language: Language = Language.HINDI     # For vernacular SMS/voice alerts


class FarmerDB(FarmerCreate):
    """Full farmer record as stored in DynamoDB."""
    farmer_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    baseline_ndvi: Optional[float] = None   # Captured at registration for fraud baseline
    agro_polygon_id: Optional[str] = None 

    def to_dynamo(self) -> dict:
        return self.model_dump()
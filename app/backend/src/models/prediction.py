from pydantic import BaseModel, Field
from typing import Optional
import uuid
from datetime import datetime, timezone
from src.db.dynamodb import floats_to_decimal


class PredictionInput(BaseModel):
    farm_id: str
    disease_type: str
    confidence_score: float
    affected_area_percent: float
    model_version: str = "v1"


class PredictionDB(PredictionInput):
    prediction_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    regional_consensus_pct: Optional[float] = None
    payout_multiplier: Optional[float] = None
    payout_triggered: bool = False
    payout_id: Optional[str] = None
    bedrock_assessment: Optional[str] = None

    def to_dynamo(self) -> dict:
        return floats_to_decimal(self.model_dump())


class PayoutLog(BaseModel):
    payout_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    farm_id: str
    farmer_id: str
    prediction_id: str
    farmer_wallet: str
    insured_amount_usdc: float
    payout_multiplier: float
    final_payout_usdc: float
    tx_hash: Optional[str] = None
    status: str = "pending"
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )

    def to_dynamo(self) -> dict:
        return floats_to_decimal(self.model_dump())
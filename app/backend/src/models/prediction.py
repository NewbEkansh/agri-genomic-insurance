from pydantic import BaseModel, Field
from typing import Optional
import uuid
from datetime import datetime, timezone


class PredictionInput(BaseModel):
    """
    Contract between AI pipeline and backend.
    The ML teammate POSTs this to POST /predictions/score after model inference.
    """
    farm_id: str
    disease_type: str               # e.g. "rice_blast", "wheat_rust", "cotton_boll_rot"
    confidence_score: float         # 0.0 – 1.0
    affected_area_percent: float    # fraction of farm visually affected (0.0 – 1.0)
    model_version: str = "v1"


class PredictionDB(PredictionInput):
    """Full prediction record as stored in DynamoDB."""
    prediction_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    # created_at is also the DynamoDB sort key on predictions table
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    # Populated after fraud check and payout decision
    regional_consensus_pct: Optional[float] = None
    payout_multiplier: Optional[float] = None
    payout_triggered: bool = False
    payout_id: Optional[str] = None
    bedrock_assessment: Optional[str] = None    # Haiku-generated explanation

    def to_dynamo(self) -> dict:
        return self.model_dump()


class PayoutLog(BaseModel):
    """Payout record written to yieldshield-payout-logs table."""
    payout_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    farm_id: str
    farmer_id: str
    prediction_id: str
    farmer_wallet: str
    insured_amount_usdc: float
    payout_multiplier: float
    final_payout_usdc: float
    tx_hash: Optional[str] = None
    status: str = "pending"         # pending → submitted → confirmed / failed
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )

    def to_dynamo(self) -> dict:
        return self.model_dump()
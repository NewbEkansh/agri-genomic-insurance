from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum
import uuid
from datetime import datetime, timezone
from src.db.dynamodb import floats_to_decimal


class PolicyStatus(str, Enum):
    ACTIVE = "active"
    TRIGGERED = "triggered"
    PAID = "paid"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class PolicyCreate(BaseModel):
    farmer_id: str
    insured_amount_usdc: float


class PolicyDB(PolicyCreate):
    policy_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    status: PolicyStatus = PolicyStatus.ACTIVE
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    triggered_at: Optional[str] = None
    payout_tx_hash: Optional[str] = None

    def to_dynamo(self) -> dict:
        return floats_to_decimal(self.model_dump())


class PolicyResponse(PolicyDB):
    pass
from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum
import uuid
from datetime import datetime, timezone


class PolicyStatus(str, Enum):
    ACTIVE = "active"
    TRIGGERED = "triggered"     # Payout has been initiated
    PAID = "paid"               # Payout confirmed on-chain
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class PolicyCreate(BaseModel):
    """Request body for creating a new insurance policy for a farmer."""
    farmer_id: str
    insured_amount_usdc: float      # Amount locked in the smart contract pool


class PolicyDB(PolicyCreate):
    """Full policy record as stored in DynamoDB."""
    policy_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    status: PolicyStatus = PolicyStatus.ACTIVE
    created_at: str = Field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    triggered_at: Optional[str] = None
    payout_tx_hash: Optional[str] = None

    def to_dynamo(self) -> dict:
        return self.model_dump()


class PolicyResponse(PolicyDB):
    """Response shape — same as DB record for now."""
    pass
"""
policy_service.py
-----------------
Business logic for insurance policies.
Kept thin for now — most logic lives in prediction_service.py since
policies are primarily read during the prediction pipeline.
"""

from src.db import schemas as db
from src.models.policy import PolicyDB


def get_active_policy_for_farmer(farmer_id: str) -> PolicyDB | None:
    """Returns the first active policy for a farmer, or None."""
    policies = db.get_policies_by_farmer(farmer_id)
    active = [p for p in policies if p.get("status") == "active"]
    if not active:
        return None
    return PolicyDB(**active[0])
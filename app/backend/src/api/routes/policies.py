from fastapi import APIRouter, HTTPException
from src.models.policy import PolicyCreate, PolicyDB, PolicyResponse
from src.db import schemas as db

router = APIRouter()


@router.post("/create", response_model=PolicyResponse, status_code=201)
def create_policy(payload: PolicyCreate):
    """
    Create an insurance policy for a registered farmer.
    In production, this would also call the smart contract to lock
    the insured_amount_usdc into the liquidity pool.
    """
    farmer = db.get_farmer_by_id(payload.farmer_id)
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer not found")

    # Check farmer doesn't already have an active policy
    existing = db.get_policies_by_farmer(payload.farmer_id)
    active = [p for p in existing if p.get("status") == "active"]
    if active:
        raise HTTPException(
            status_code=409,
            detail="Farmer already has an active policy. Cancel it before creating a new one."
        )

    policy = PolicyDB(**payload.model_dump())
    db.put_policy(policy.to_dynamo())
    return policy


@router.get("/{policy_id}", response_model=PolicyResponse)
def get_policy(policy_id: str):
    """Retrieve a policy by ID."""
    policy = db.get_policy_by_id(policy_id)
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")
    return policy


@router.patch("/{policy_id}/cancel")
def cancel_policy(policy_id: str):
    """Cancel an active policy."""
    policy = db.get_policy_by_id(policy_id)
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")
    if policy["status"] != "active":
        raise HTTPException(status_code=400, detail=f"Policy is already '{policy['status']}'")

    db.update_policy_status(policy_id, "cancelled")
    return {"policy_id": policy_id, "status": "cancelled"}
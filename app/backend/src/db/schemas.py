"""
schemas.py
----------
Low-level DynamoDB read/write helpers for each table.
Routes and services should call these instead of touching boto3 directly —
keeps all DynamoDB logic in one place and makes mocking in tests easy.
"""

from boto3.dynamodb.conditions import Key, Attr
from src.db.dynamodb import get_table
from src.core.config import settings
from typing import Optional
from decimal import Decimal


# ── Farmers ──────────────────────────────────────────────────────────────────

def put_farmer(farmer: dict) -> None:
    get_table(settings.TABLE_FARMERS).put_item(Item=farmer)


def get_farmer_by_id(farmer_id: str) -> Optional[dict]:
    resp = get_table(settings.TABLE_FARMERS).get_item(Key={"farmer_id": farmer_id})
    return resp.get("Item")


def scan_all_farmers() -> list[dict]:
    """Full scan — used only for regional fraud check. Acceptable at hackathon scale."""
    resp = get_table(settings.TABLE_FARMERS).scan()
    return resp.get("Items", [])


# ── Policies ─────────────────────────────────────────────────────────────────

def put_policy(policy: dict) -> None:
    get_table(settings.TABLE_POLICIES).put_item(Item=policy)


def get_policy_by_id(policy_id: str) -> Optional[dict]:
    resp = get_table(settings.TABLE_POLICIES).get_item(Key={"policy_id": policy_id})
    return resp.get("Item")


def get_policies_by_farmer(farmer_id: str) -> list[dict]:
    """Uses the farmer_id-index GSI created in the AWS console."""
    resp = get_table(settings.TABLE_POLICIES).query(
        IndexName="farmer_id-index",
        KeyConditionExpression=Key("farmer_id").eq(farmer_id),
    )
    return resp.get("Items", [])


def update_policy_status(policy_id: str, status: str) -> None:
    get_table(settings.TABLE_POLICIES).update_item(
        Key={"policy_id": policy_id},
        UpdateExpression="SET #s = :status",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={":status": status},
    )


# ── Predictions ───────────────────────────────────────────────────────────────

def put_prediction(prediction: dict) -> None:
    get_table(settings.TABLE_PREDICTIONS).put_item(Item=prediction)


def get_recent_predictions_for_farm(farm_id: str, limit: int = 10) -> list[dict]:
    """
    Returns the N most recent predictions for a farm.
    Table has composite key (farm_id PK, created_at SK) so this is an efficient query.
    """
    resp = get_table(settings.TABLE_PREDICTIONS).query(
        KeyConditionExpression=Key("farm_id").eq(farm_id),
        ScanIndexForward=False,   # descending by created_at
        Limit=limit,
    )
    return resp.get("Items", [])


def get_recent_predictions_for_farms(farm_ids: list[str], cutoff_iso: str) -> list[dict]:
    """
    Batch-fetch recent high-confidence predictions across multiple farms.
    Used by fraud detection to check regional consensus.
    One query per farm — acceptable for small regional sets (<50 farms).
    """
    flagged = []
    table = get_table(settings.TABLE_PREDICTIONS)
    for farm_id in farm_ids:
        resp = table.query(
            KeyConditionExpression=Key("farm_id").eq(farm_id) & Key("created_at").gte(cutoff_iso),
            FilterExpression=Attr("confidence_score").gte(Decimal(str(settings.PAYOUT_TRIGGER_THRESHOLD))),
            Limit=1,
        )
        if resp.get("Count", 0) > 0:
            flagged.append(farm_id)
    return flagged


# ── Payout Logs ───────────────────────────────────────────────────────────────

def put_payout_log(log: dict) -> None:
    get_table(settings.TABLE_PAYOUT_LOGS).put_item(Item=log)


def update_payout_log(payout_id: str, tx_hash: str, status: str) -> None:
    get_table(settings.TABLE_PAYOUT_LOGS).update_item(
        Key={"payout_id": payout_id},
        UpdateExpression="SET tx_hash = :tx, #s = :status",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={":tx": tx_hash, ":status": status},
    )


def get_payout_by_id(payout_id: str) -> Optional[dict]:
    resp = get_table(settings.TABLE_PAYOUT_LOGS).get_item(Key={"payout_id": payout_id})
    return resp.get("Item")


def get_payouts_by_farm(farm_id: str) -> list[dict]:
    """Uses the farm_id-index GSI on payout logs table."""
    resp = get_table(settings.TABLE_PAYOUT_LOGS).query(
        IndexName="farm_id-index",
        KeyConditionExpression=Key("farm_id").eq(farm_id),
        ScanIndexForward=False,
    )
    return resp.get("Items", [])
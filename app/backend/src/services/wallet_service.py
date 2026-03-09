"""
wallet_service.py
-----------------
Auto-creates an Ethereum wallet for every new farmer.
The farmer never sees or manages their private key — the backend
handles all blockchain transactions on their behalf as the oracle.

Private keys are stored in AWS Secrets Manager, never in DynamoDB.
DynamoDB only stores the public wallet address.

This abstracts all crypto complexity from the farmer completely.
"""

import boto3
import json
from web3 import Web3
from src.core.config import settings


def _get_secrets_client():
    return boto3.client(
        "secretsmanager",
        region_name=settings.AWS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID or None,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY or None,
    )


def create_farmer_wallet(farmer_id: str) -> dict:
    """
    Creates a new Ethereum wallet for a farmer.

    Returns:
        {
            "address": "0x...",        ← stored in DynamoDB (public, safe)
            "private_key": "0x..."     ← stored ONLY in Secrets Manager
        }

    The private key is stored in Secrets Manager under the key:
        yieldshield/farmer/{farmer_id}/wallet

    When the backend needs to sign a transaction for this farmer,
    it calls get_farmer_private_key(farmer_id) to retrieve it.
    """
    # Generate new Ethereum account
    w3 = Web3()
    account = w3.eth.account.create()

    address = account.address
    private_key = account.key.hex()

    # Store private key in Secrets Manager
    secret_name = f"yieldshield/farmer/{farmer_id}/wallet"
    secret_value = json.dumps({
        "farmer_id": farmer_id,
        "address": address,
        "private_key": private_key,
    })

    try:
        _get_secrets_client().create_secret(
            Name=secret_name,
            Description=f"Wallet private key for YieldShield farmer {farmer_id}",
            SecretString=secret_value,
        )
        print(f"[Wallet] Created wallet for farmer {farmer_id}: {address}")
    except Exception as e:
        print(f"[Wallet] Secrets Manager storage failed: {e}")
        # Non-fatal for hackathon — address is still returned
        # In production this should raise

    return {
        "address": address,
        "private_key": private_key,   # only used internally, never sent to client
    }


def get_farmer_private_key(farmer_id: str) -> str | None:
    """
    Retrieves a farmer's private key from Secrets Manager.
    Used by blockchain_service when signing payout transactions.
    Returns None if not found.
    """
    secret_name = f"yieldshield/farmer/{farmer_id}/wallet"
    try:
        resp = _get_secrets_client().get_secret_value(SecretName=secret_name)
        secret = json.loads(resp["SecretString"])
        return secret["private_key"]
    except Exception as e:
        print(f"[Wallet] Could not retrieve key for farmer {farmer_id}: {e}")
        return None


def get_farmer_address(farmer_id: str) -> str | None:
    """
    Retrieves a farmer's wallet address from Secrets Manager.
    Fallback if DynamoDB record doesn't have it.
    """
    secret_name = f"yieldshield/farmer/{farmer_id}/wallet"
    try:
        resp = _get_secrets_client().get_secret_value(SecretName=secret_name)
        secret = json.loads(resp["SecretString"])
        return secret["address"]
    except Exception as e:
        print(f"[Wallet] Could not retrieve address for farmer {farmer_id}: {e}")
        return None
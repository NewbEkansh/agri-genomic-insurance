"""
alert_service.py
----------------
Sends SMS alerts to farmers via AWS SNS.
"""

import boto3
from src.core.config import settings


def _get_sns():
    return boto3.client(
        "sns",
        region_name=settings.AWS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID or None,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY or None,
    )


def send_payout_alert(phone: str, name: str, final_payout: float, tx_hash: str, assessment: str) -> bool:
    """Notify farmer that a payout has been triggered."""
    message = (
        f"YieldShield Payout Alert\n"
        f"{assessment}\n\n"
        f"Amount: ${final_payout:.2f} USDC\n"
        f"Track: https://sepolia.etherscan.io/tx/{tx_hash}"
    )
    return _publish(phone, message)


def send_early_warning(phone: str, name: str, disease_type: str, confidence: float, crop_type: str) -> bool:
    """Early warning — high risk detected but below payout threshold."""
    message = (
        f"YieldShield Warning for {name}:\n"
        f"High risk of {disease_type.replace('_', ' ').title()} on your {crop_type} farm "
        f"({confidence:.0%} confidence). Take preventative action now. "
        f"Your policy remains active."
    )
    return _publish(phone, message)


def _publish(phone: str, message: str) -> bool:
    if not phone:
        return False
    try:
        _get_sns().publish(PhoneNumber=phone, Message=message)
        return True
    except Exception as e:
        print(f"[SNS] Failed to send to {phone}: {e}")
        return False
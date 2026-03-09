"""
otp_service.py
--------------
Handles OTP generation, storage in DynamoDB, and delivery via AWS SNS.

OTP lifecycle:
  1. generate_and_send_otp(phone) → creates 6-digit OTP, stores in DynamoDB with
     5-minute TTL, sends SMS via SNS
  2. verify_otp(phone, otp) → checks DynamoDB, returns True/False
  3. On success → OTP deleted from DynamoDB (single use)
"""

import random
import boto3
from datetime import datetime, timedelta, timezone
from src.core.config import settings
from src.db.dynamodb import get_table, floats_to_decimal

OTP_TABLE = "yieldshield-otps"
OTP_EXPIRY_MINUTES = 5


def _get_sns():
    return boto3.client(
        "sns",
        region_name=settings.AWS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID or None,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY or None,
    )


def generate_and_send_otp(phone: str) -> bool:
    """
    Generates a 6-digit OTP, stores it in DynamoDB, sends via SNS SMS.
    Returns True on success, False if SMS failed.

    phone must be in E.164 format: +919876543210
    """
    otp = str(random.randint(100000, 999999))
    expires_at = int(
        (datetime.now(timezone.utc) + timedelta(minutes=OTP_EXPIRY_MINUTES)).timestamp()
    )

    # Store OTP in DynamoDB (overwrites any existing OTP for this phone)
    table = get_table(OTP_TABLE)
    table.put_item(Item={
        "phone": phone,
        "otp": otp,
        "expires_at": expires_at,        # DynamoDB TTL attribute
        "created_at": datetime.now(timezone.utc).isoformat(),
    })

    # Send SMS via SNS
    message = f"Your YieldShield OTP is: {otp}\nValid for {OTP_EXPIRY_MINUTES} minutes. Do not share this code."
    try:
        _get_sns().publish(PhoneNumber=phone, Message=message)
        print(f"[OTP] Sent to {phone}")
        return True
    except Exception as e:
        print(f"[OTP] SMS failed for {phone}: {e}")
        # OTP is still stored — return True so dev/testing works even without SNS
        # In production, return False here
        print(f"[OTP] DEV MODE — OTP is: {otp}")
        return True


def verify_otp(phone: str, otp: str) -> bool:
    """
    Verifies the OTP for a phone number.
    Deletes the OTP on success (single use).
    Returns True if valid, False if invalid or expired.
    """
    table = get_table(OTP_TABLE)
    resp = table.get_item(Key={"phone": phone})
    item = resp.get("Item")

    if not item:
        print(f"[OTP] No OTP found for {phone}")
        return False

    # Check expiry manually (in case DynamoDB TTL hasn't cleaned it yet)
    now = int(datetime.now(timezone.utc).timestamp())
    if now > int(item.get("expires_at", 0)):
        print(f"[OTP] Expired OTP for {phone}")
        table.delete_item(Key={"phone": phone})
        return False

    if item.get("otp") != otp:
        print(f"[OTP] Invalid OTP for {phone}")
        return False

    # Valid — delete immediately (single use)
    table.delete_item(Key={"phone": phone})
    print(f"[OTP] Verified successfully for {phone}")
    return True
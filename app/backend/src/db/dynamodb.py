import boto3
from decimal import Decimal
from functools import lru_cache
from src.core.config import settings


@lru_cache()
def get_dynamodb_resource():
    return boto3.resource(
        "dynamodb",
        region_name=settings.AWS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID or None,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY or None,
    )


def get_table(table_name: str):
    return get_dynamodb_resource().Table(table_name)


def floats_to_decimal(obj):
    """
    Recursively convert all floats in a dict/list to Decimal.
    DynamoDB does not accept Python float types — Decimal is required.
    We use str(obj) as the intermediate to avoid floating point precision issues.
    """
    if isinstance(obj, float):
        return Decimal(str(obj))
    elif isinstance(obj, dict):
        return {k: floats_to_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [floats_to_decimal(i) for i in obj]
    return obj
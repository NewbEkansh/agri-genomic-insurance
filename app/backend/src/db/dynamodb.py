import boto3
from functools import lru_cache
from src.core.config import settings


@lru_cache()
def get_dynamodb_resource():
    """
    Returns a cached boto3 DynamoDB resource.
    Credentials are picked up automatically from:
      - .env (local dev via AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY)
      - Lambda execution role (production — no keys needed in env)
    """
    return boto3.resource(
        "dynamodb",
        region_name=settings.AWS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID or None,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY or None,
    )


def get_table(table_name: str):
    """Convenience wrapper — returns a DynamoDB Table object."""
    return get_dynamodb_resource().Table(table_name)
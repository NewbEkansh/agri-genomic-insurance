from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ── App ───────────────────────────────────────────────────────────────────
    APP_ENV: str = "development"
    DEBUG: bool = True

    # ── AWS ───────────────────────────────────────────────────────────────────
    AWS_REGION: str = "eu-north-1"
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""

    # DynamoDB tables
    TABLE_FARMERS: str = "yieldshield-farmers"
    TABLE_POLICIES: str = "yieldshield-policies"
    TABLE_PREDICTIONS: str = "yieldshield-predictions"
    TABLE_PAYOUT_LOGS: str = "yieldshield-payout-logs"
    TABLE_OTPS: str = "yieldshield-otps"

    # S3
    S3_BUCKET_CROPS: str = "yieldshield-crop-images"

    # SNS
    SNS_ALERT_TOPIC_ARN: str = ""

    # Bedrock
    BEDROCK_MODEL_ID: str = "anthropic.claude-3-haiku-20240307-v1:0"

    # ── Blockchain (Sepolia) ──────────────────────────────────────────────────
    SEPOLIA_RPC_URL: str = ""
    ORACLE_WALLET_ADDRESS: str = ""
    ORACLE_PRIVATE_KEY: str = ""
    CONTRACT_ADDRESS: str = ""

    # ── External APIs ─────────────────────────────────────────────────────────
    OPENWEATHER_API_KEY: str = ""
    AGROMONITORING_API_KEY: str = ""

    # ── Auth ──────────────────────────────────────────────────────────────────
    JWT_SECRET: str = "yieldshield-jwt-secret-change-in-production"
    INTERNAL_API_KEY: str = "yieldshield-dev-key"

    # ── Risk thresholds ───────────────────────────────────────────────────────
    PAYOUT_TRIGGER_THRESHOLD: float = 0.85
    EARLY_WARNING_THRESHOLD: float = 0.60
    REGIONAL_CONSENSUS_MIN: float = 0.30
    REGIONAL_RADIUS_KM: float = 5.0
    FRAUD_PAYOUT_MULTIPLIER: float = 0.65

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
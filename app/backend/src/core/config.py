from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ── App ───────────────────────────────────────────────────────────────────
    APP_ENV: str = "development"
    DEBUG: bool = True

    # ── AWS ───────────────────────────────────────────────────────────────────
    AWS_REGION: str = "ap-south-1"
    AWS_ACCESS_KEY_ID: str = ""
    AWS_SECRET_ACCESS_KEY: str = ""

    # DynamoDB table names
    TABLE_FARMERS: str = "yieldshield-farmers"
    TABLE_POLICIES: str = "yieldshield-policies"
    TABLE_PREDICTIONS: str = "yieldshield-predictions"
    TABLE_PAYOUT_LOGS: str = "yieldshield-payout-logs"

    # SNS
    SNS_ALERT_TOPIC_ARN: str = ""

    # Bedrock
    BEDROCK_MODEL_ID: str = "anthropic.claude-haiku-4-5-20251001"

    # ── Blockchain (Sepolia) ──────────────────────────────────────────────────
    SEPOLIA_RPC_URL: str = ""
    ORACLE_WALLET_ADDRESS: str = ""
    ORACLE_PRIVATE_KEY: str = ""          # Set via .env only — never hardcode
    CONTRACT_ADDRESS: str = ""

    # ── External APIs ─────────────────────────────────────────────────────────
    OPENWEATHER_API_KEY: str = ""
    AGROMONITORING_API_KEY: str = ""

    # ── Risk / Fraud Thresholds ───────────────────────────────────────────────
    PAYOUT_TRIGGER_THRESHOLD: float = 0.85   # AI confidence needed to trigger payout
    EARLY_WARNING_THRESHOLD: float = 0.60    # AI confidence for early warning SMS
    REGIONAL_CONSENSUS_MIN: float = 0.30     # Min % of nearby farms also flagged
    REGIONAL_RADIUS_KM: float = 5.0          # Radius for regional fraud check
    FRAUD_PAYOUT_MULTIPLIER: float = 0.65    # Payout % when consensus not met

    INTERNAL_API_KEY: str = "yieldshield-dev-key"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
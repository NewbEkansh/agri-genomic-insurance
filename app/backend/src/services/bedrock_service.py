"""
bedrock_service.py
------------------
Calls Amazon Bedrock (Claude Haiku) to generate a plain-language
insurance assessment for every payout event.
"""

import json
import boto3
from src.core.config import settings


def _get_client():
    return boto3.client(
        "bedrock-runtime",
        region_name=settings.AWS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID or None,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY or None,
    )


def generate_assessment(
    farmer_name: str,
    crop_type: str,
    disease_type: str,
    confidence: float,
    affected_area_pct: float,
    consensus_pct: float,
    payout_multiplier: float,
    insured_amount: float,
    final_payout: float,
) -> str:
    """
    Returns a 2-3 sentence insurance payout assessment in plain English.
    Non-fatal — if Bedrock fails the payout still proceeds.
    """
    outbreak_confirmed = payout_multiplier >= 1.0
    context = (
        f"Regional outbreak confirmed ({consensus_pct:.0%} of nearby farms affected)."
        if outbreak_confirmed
        else f"Isolated incident detected — only {consensus_pct:.0%} of nearby farms affected. "
             f"Payout adjusted to {payout_multiplier:.0%} as a fraud prevention measure."
    )

    prompt = f"""You are an agricultural insurance assessor writing a brief payout notification.
Write 2-3 clear, factual sentences suitable for sending to a farmer via SMS.
Use simple language. Do not use jargon.

Farmer: {farmer_name}
Crop: {crop_type}
Disease detected: {disease_type.replace("_", " ").title()}
AI confidence: {confidence:.0%}
Area affected: {affected_area_pct:.0%} of farm
{context}
Insured amount: ${insured_amount:.2f} USDC
Approved payout: ${final_payout:.2f} USDC

Write the assessment:"""

    try:
        client = _get_client()
        body = json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 150,
            "messages": [{"role": "user", "content": prompt}],
        })
        response = client.invoke_model(
            modelId=settings.BEDROCK_MODEL_ID,
            body=body,
            contentType="application/json",
            accept="application/json",
        )
        result = json.loads(response["body"].read())
        return result["content"][0]["text"].strip()
    except Exception as e:
        print(f"[Bedrock] Assessment generation failed: {e}")
        return (
            f"YieldShield has detected {disease_type.replace('_', ' ')} on your {crop_type} farm "
            f"with {confidence:.0%} confidence. A payout of ${final_payout:.2f} USDC has been approved."
        )
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum

from src.api.routes import farmers, policies, predictions, health

app = FastAPI(
    title="YieldShield API",
    description="Agri-Genomic Yield Forecaster & Smart Insurance Platform",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router,      prefix="/health",      tags=["Health"])
app.include_router(farmers.router,     prefix="/farmers",     tags=["Farmers"])
app.include_router(policies.router,    prefix="/policies",    tags=["Policies"])
app.include_router(predictions.router, prefix="/predictions", tags=["Predictions"])

# AWS Lambda entry point (Mangum wraps the ASGI app)
handler = Mangum(app, lifespan="off")
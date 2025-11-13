from pydantic_settings import BaseSettings
from typing import Optional
import logging

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str = "postgresql://crownborn:crownborn@localhost:5432/crownborn"
    REDIS_URL: str = "redis://localhost:6379"

    # JWT
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    # Payment
    STRIPE_SECRET_KEY: Optional[str] = None
    STRIPE_WEBHOOK_SECRET: Optional[str] = None
    GOOGLE_PLAY_SERVICE_ACCOUNT: Optional[str] = None
    APPLE_SHARED_SECRET: Optional[str] = None

    # Game
    GAME_CURRENCY_NAME: str = "Skycrowns"
    GAME_CURRENCY_SYMBOL: str = "SC"

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    DEBUG: bool = True

    # Logging
    LOG_LEVEL: int = logging.INFO  # DEBUG=10, INFO=20, WARNING=30, ERROR=40
    LOG_TO_FILE: bool = True
    LOG_TO_CONSOLE: bool = True

    class Config:
        env_file = ".env"

settings = Settings()

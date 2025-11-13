from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from models.database import get_db
from services.auth_service import create_user, authenticate_user, create_auth_token
from config.logging_config import setup_logger, log_error, log_security_event

router = APIRouter(prefix="/v1/auth", tags=["auth"])
logger = setup_logger("api.auth")

class UserCreateRequest(BaseModel):
    display_name: str
    gender: str  # "boy" or "girl"
    country_code: str = "US"
    platform_id: Optional[dict] = None

class TokenRequest(BaseModel):
    user_id: Optional[str] = None
    platform_id: Optional[dict] = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    display_name: str

@router.post("/register", response_model=TokenResponse)
async def register_user(request: UserCreateRequest, db: Session = Depends(get_db)):
    """Create new user account"""
    logger.info(f"Registration attempt - Display name: {request.display_name}, Gender: {request.gender}, Country: {request.country_code}")

    try:
        user = create_user(
            db=db,
            display_name=request.display_name,
            gender=request.gender,
            country_code=request.country_code,
            platform_ids=request.platform_id
        )

        logger.info(f"User created successfully - ID: {user.id}, Name: {user.display_name}")

        token = create_auth_token(db, user.id)

        logger.info(f"JWT token issued for user: {user.id}")
        log_security_event(logger, "USER_REGISTERED", str(user.id))

        return TokenResponse(
            access_token=token,
            user_id=str(user.id),
            display_name=user.display_name
        )

    except Exception as e:
        logger.error(f"Registration failed - Display name: {request.display_name}, Error: {str(e)}")
        log_error(logger, e, "user registration")
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/token", response_model=TokenResponse)
async def get_token(request: TokenRequest, db: Session = Depends(get_db)):
    """Get JWT token for existing user or guest"""
    logger.info(f"Token request - User ID: {request.user_id}, Platform ID present: {bool(request.platform_id)}")

    try:
        user = authenticate_user(db, request.user_id, request.platform_id)

        if not user:
            logger.warning(f"Authentication failed - User ID: {request.user_id}")
            log_security_event(logger, "AUTH_FAILED", request.user_id or "unknown")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or banned"
            )

        token = create_auth_token(db, user.id)

        logger.info(f"Token issued successfully for user: {user.id}")
        log_security_event(logger, "AUTH_SUCCESS", str(user.id))

        return TokenResponse(
            access_token=token,
            user_id=str(user.id),
            display_name=user.display_name
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Token generation error - User ID: {request.user_id}")
        log_error(logger, e, "token generation")
        raise HTTPException(status_code=500, detail="Internal server error")

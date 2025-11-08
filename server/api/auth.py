from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from models.database import get_db
from services.auth_service import create_user, authenticate_user, create_auth_token

router = APIRouter(prefix="/v1/auth", tags=["auth"])

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
    try:
        user = create_user(
            db=db,
            display_name=request.display_name,
            gender=request.gender,
            country_code=request.country_code,
            platform_ids=request.platform_id
        )

        token = create_auth_token(db, user.id)

        return TokenResponse(
            access_token=token,
            user_id=str(user.id),
            display_name=user.display_name
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/token", response_model=TokenResponse)
async def get_token(request: TokenRequest, db: Session = Depends(get_db)):
    """Get JWT token for existing user or guest"""
    user = authenticate_user(db, request.user_id, request.platform_id)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or banned"
        )

    token = create_auth_token(db, user.id)

    return TokenResponse(
        access_token=token,
        user_id=str(user.id),
        display_name=user.display_name
    )

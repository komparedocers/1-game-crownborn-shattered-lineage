from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session
import uuid

from models.database import User, AuthToken, Wallet
from config.settings import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode.update({"exp": expire, "jti": str(uuid.uuid4())})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt, to_encode["jti"], expire

def verify_token(token: str):
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        return None

def create_user(db: Session, display_name: str, gender: str, country_code: str = "US", platform_ids: dict = None):
    """Create a new user account"""
    user = User(
        display_name=display_name,
        gender=gender,
        country_code=country_code,
        platform_ids=platform_ids or {}
    )
    db.add(user)

    # Create wallet for user
    wallet = Wallet(user_id=user.id, sky_crowns=0)
    db.add(wallet)

    db.commit()
    db.refresh(user)
    return user

def authenticate_user(db: Session, user_id: str = None, platform_id: dict = None):
    """Authenticate existing user or create guest user"""
    if user_id:
        user = db.query(User).filter(User.id == user_id).first()
        if user and not user.banned:
            return user

    if platform_id:
        # Search by platform ID (Google Play Games, Apple Game Center)
        users = db.query(User).all()
        for user in users:
            if user.platform_ids and platform_id.items() <= user.platform_ids.items():
                if not user.banned:
                    return user

    return None

def create_auth_token(db: Session, user_id: uuid.UUID):
    """Create JWT token for user"""
    token, jti, expires_at = create_access_token(
        data={"sub": str(user_id)},
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )

    auth_token = AuthToken(
        user_id=user_id,
        jwt_id=jti,
        expires_at=expires_at
    )
    db.add(auth_token)
    db.commit()

    return token

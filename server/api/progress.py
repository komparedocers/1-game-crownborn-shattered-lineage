from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from models.database import get_db, User, Progress, Wallet
from services.auth_service import verify_token
from services.payment_service import grant_currency

router = APIRouter(prefix="/v1/progress", tags=["progress"])

class StageSubmitRequest(BaseModel):
    stage: int
    time_ms: int
    deaths: int
    stars: int
    completed: bool

class StageSubmitResponse(BaseModel):
    success: bool
    sc_earned: int
    new_balance: int
    is_best_time: bool

class ProgressResponse(BaseModel):
    stage: int
    best_time_ms: Optional[int]
    deaths: int
    stars: int
    completed: bool

def get_current_user(token: str, db: Session):
    """Get current user from token"""
    payload = verify_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(User).filter(User.id == payload["sub"]).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return user

def calculate_stage_reward(stage: int, time_ms: int, deaths: int, stars: int) -> int:
    """Calculate SC reward for stage completion"""
    # Base reward scales with stage (50-250 SC)
    base_reward = min(50 + (stage * 1.3), 250)

    # Bonus for performance
    time_bonus = 0
    if time_ms < 60000:  # Under 1 minute
        time_bonus = 50
    elif time_ms < 120000:  # Under 2 minutes
        time_bonus = 25

    death_penalty = deaths * 10
    star_bonus = stars * 20

    total = int(base_reward + time_bonus + star_bonus - death_penalty)
    return max(total, 10)  # Minimum 10 SC

@router.post("/stage", response_model=StageSubmitResponse)
async def submit_stage(
    request: StageSubmitRequest,
    token: str = Depends(lambda: ""),  # Would use proper dependency injection
    db: Session = Depends(get_db)
):
    """Submit stage completion and get reward"""
    # In production, extract user from JWT token
    # For now, using a mock user_id
    user = db.query(User).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    # Check for existing progress
    progress = db.query(Progress).filter(
        Progress.user_id == user.id,
        Progress.stage == request.stage
    ).first()

    is_best_time = False
    if progress:
        # Update if better time
        if not progress.best_time_ms or request.time_ms < progress.best_time_ms:
            progress.best_time_ms = request.time_ms
            is_best_time = True
        progress.deaths = min(progress.deaths, request.deaths)
        progress.stars = max(progress.stars, request.stars)
        progress.completed = request.completed or progress.completed
    else:
        # Create new progress
        progress = Progress(
            user_id=user.id,
            stage=request.stage,
            best_time_ms=request.time_ms,
            deaths=request.deaths,
            stars=request.stars,
            completed=request.completed
        )
        db.add(progress)
        is_best_time = True

    # Calculate reward
    sc_earned = calculate_stage_reward(
        request.stage,
        request.time_ms,
        request.deaths,
        request.stars
    )

    # Grant currency
    grant_currency(db, user.id, sc_earned, reason=f"stage_{request.stage}")

    # Get new balance
    wallet = db.query(Wallet).filter(Wallet.user_id == user.id).first()
    new_balance = wallet.sky_crowns if wallet else 0

    db.commit()

    return StageSubmitResponse(
        success=True,
        sc_earned=sc_earned,
        new_balance=new_balance,
        is_best_time=is_best_time
    )

@router.get("/user/{user_id}", response_model=List[ProgressResponse])
async def get_user_progress(user_id: str, db: Session = Depends(get_db)):
    """Get all progress for a user"""
    progress_list = db.query(Progress).filter(Progress.user_id == user_id).all()

    return [
        ProgressResponse(
            stage=p.stage,
            best_time_ms=p.best_time_ms,
            deaths=p.deaths,
            stars=p.stars,
            completed=p.completed
        )
        for p in progress_list
    ]

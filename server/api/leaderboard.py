from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from pydantic import BaseModel
from typing import List, Optional

from models.database import get_db, User, Progress, LeaderboardSnapshot

router = APIRouter(prefix="/v1/leaderboard", tags=["leaderboard"])

class LeaderboardEntry(BaseModel):
    rank: int
    user_id: str
    display_name: str
    country_code: str
    score: int
    stage: Optional[int] = None

class LeaderboardResponse(BaseModel):
    mode: str
    country_code: Optional[str]
    entries: List[LeaderboardEntry]
    total_count: int

@router.get("/global", response_model=LeaderboardResponse)
async def get_global_leaderboard(
    mode: str = Query("fastest_total", description="Leaderboard mode"),
    country: Optional[str] = Query(None, description="Filter by country code"),
    limit: int = Query(100, le=500),
    offset: int = Query(0),
    db: Session = Depends(get_db)
):
    """Get global leaderboard with optional country filter"""

    # Build query based on mode
    if mode == "fastest_total":
        # Sum of best times across all stages
        query = db.query(
            Progress.user_id,
            func.sum(Progress.best_time_ms).label("total_time")
        ).filter(
            Progress.completed == True
        ).group_by(
            Progress.user_id
        )

        if country:
            query = query.join(User).filter(User.country_code == country)

        query = query.order_by(desc("total_time")).limit(limit).offset(offset)
        results = query.all()

        entries = []
        for idx, (user_id, total_time) in enumerate(results, start=offset + 1):
            user = db.query(User).filter(User.id == user_id).first()
            entries.append(
                LeaderboardEntry(
                    rank=idx,
                    user_id=str(user_id),
                    display_name=user.display_name if user else "Unknown",
                    country_code=user.country_code if user else "XX",
                    score=total_time or 0
                )
            )

    elif mode == "highest_stage":
        # Highest completed stage
        query = db.query(
            Progress.user_id,
            func.max(Progress.stage).label("max_stage")
        ).filter(
            Progress.completed == True
        ).group_by(
            Progress.user_id
        )

        if country:
            query = query.join(User).filter(User.country_code == country)

        query = query.order_by(desc("max_stage")).limit(limit).offset(offset)
        results = query.all()

        entries = []
        for idx, (user_id, max_stage) in enumerate(results, start=offset + 1):
            user = db.query(User).filter(User.id == user_id).first()
            entries.append(
                LeaderboardEntry(
                    rank=idx,
                    user_id=str(user_id),
                    display_name=user.display_name if user else "Unknown",
                    country_code=user.country_code if user else "XX",
                    score=0,
                    stage=max_stage
                )
            )

    else:
        entries = []

    return LeaderboardResponse(
        mode=mode,
        country_code=country,
        entries=entries,
        total_count=len(entries)
    )

@router.get("/stage/{stage_number}", response_model=LeaderboardResponse)
async def get_stage_leaderboard(
    stage_number: int,
    country: Optional[str] = Query(None),
    limit: int = Query(100, le=500),
    offset: int = Query(0),
    db: Session = Depends(get_db)
):
    """Get leaderboard for specific stage (fastest times)"""

    query = db.query(Progress).filter(
        Progress.stage == stage_number,
        Progress.completed == True
    )

    if country:
        query = query.join(User).filter(User.country_code == country)

    query = query.order_by(Progress.best_time_ms).limit(limit).offset(offset)
    results = query.all()

    entries = []
    for idx, progress in enumerate(results, start=offset + 1):
        user = db.query(User).filter(User.id == progress.user_id).first()
        entries.append(
            LeaderboardEntry(
                rank=idx,
                user_id=str(progress.user_id),
                display_name=user.display_name if user else "Unknown",
                country_code=user.country_code if user else "XX",
                score=progress.best_time_ms or 0,
                stage=stage_number
            )
        )

    return LeaderboardResponse(
        mode=f"stage_{stage_number}",
        country_code=country,
        entries=entries,
        total_count=len(entries)
    )

@router.get("/user/{user_id}/rank")
async def get_user_rank(
    user_id: str,
    mode: str = Query("fastest_total"),
    db: Session = Depends(get_db)
):
    """Get specific user's rank"""

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return {"error": "User not found"}

    # Calculate user's score based on mode
    if mode == "fastest_total":
        user_score = db.query(
            func.sum(Progress.best_time_ms)
        ).filter(
            Progress.user_id == user_id,
            Progress.completed == True
        ).scalar() or 0

        # Count how many users have better scores
        better_scores = db.query(
            func.count(func.distinct(Progress.user_id))
        ).filter(
            Progress.completed == True
        ).group_by(
            Progress.user_id
        ).having(
            func.sum(Progress.best_time_ms) < user_score
        ).scalar() or 0

        rank = better_scores + 1

    elif mode == "highest_stage":
        user_stage = db.query(
            func.max(Progress.stage)
        ).filter(
            Progress.user_id == user_id,
            Progress.completed == True
        ).scalar() or 0

        better_stages = db.query(
            func.count(func.distinct(Progress.user_id))
        ).filter(
            Progress.completed == True
        ).group_by(
            Progress.user_id
        ).having(
            func.max(Progress.stage) > user_stage
        ).scalar() or 0

        rank = better_stages + 1
        user_score = user_stage

    else:
        rank = 0
        user_score = 0

    return {
        "user_id": user_id,
        "display_name": user.display_name,
        "country_code": user.country_code,
        "mode": mode,
        "rank": rank,
        "score": user_score
    }

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from models.database import init_db, Base, engine, SessionLocal
from api import auth, progress, economy, leaderboard
from config.settings import settings
from services.catalog_init import initialize_catalog

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("Initializing database...")
    init_db()

    # Initialize catalog with default items
    db = SessionLocal()
    try:
        initialize_catalog(db)
    finally:
        db.close()

    print("Server started successfully!")
    yield
    # Shutdown
    print("Server shutting down...")

app = FastAPI(
    title="Crownborn: Shattered Lineage API",
    description="Game server API for Crownborn game",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router)
app.include_router(progress.router)
app.include_router(economy.router)
app.include_router(leaderboard.router)

@app.get("/")
async def root():
    return {
        "game": "Crownborn: Shattered Lineage",
        "version": "1.0.0",
        "status": "online"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )

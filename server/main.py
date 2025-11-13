from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from contextlib import asynccontextmanager
import time
import traceback

from models.database import init_db, Base, engine, SessionLocal
from api import auth, progress, economy, leaderboard
from config.settings import settings
from services.catalog_init import initialize_catalog
from config.logging_config import setup_logger, log_error

# Setup logger
logger = setup_logger("main", settings.LOG_LEVEL if hasattr(settings, 'LOG_LEVEL') else 20)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("=" * 80)
    logger.info("CROWNBORN: SHATTERED LINEAGE - SERVER STARTING")
    logger.info("=" * 80)

    try:
        logger.info("Initializing database...")
        init_db()
        logger.info("Database initialized successfully")

        # Initialize catalog with default items
        db = SessionLocal()
        try:
            logger.info("Initializing shop catalog...")
            initialize_catalog(db)
            logger.info("Shop catalog initialized successfully")
        except Exception as e:
            log_error(logger, e, "catalog initialization")
            raise
        finally:
            db.close()

        logger.info("Server started successfully!")
        logger.info(f"Environment: {'DEBUG' if settings.DEBUG else 'PRODUCTION'}")
        logger.info(f"Host: {settings.HOST}:{settings.PORT}")

    except Exception as e:
        logger.critical(f"Failed to start server: {str(e)}", exc_info=True)
        raise

    yield

    # Shutdown
    logger.info("Server shutting down...")
    logger.info("=" * 80)

app = FastAPI(
    title="Crownborn: Shattered Lineage API",
    description="Game server API for Crownborn game",
    version="1.0.0",
    lifespan=lifespan
)

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    request_id = f"{time.time()}"

    # Log incoming request
    logger.info(f"[{request_id}] {request.method} {request.url.path}")
    logger.debug(f"[{request_id}] Headers: {dict(request.headers)}")
    logger.debug(f"[{request_id}] Query params: {dict(request.query_params)}")

    start_time = time.time()

    try:
        response = await call_next(request)
        process_time = time.time() - start_time

        # Log response
        logger.info(f"[{request_id}] Status: {response.status_code} | Time: {process_time:.3f}s")

        response.headers["X-Process-Time"] = str(process_time)
        response.headers["X-Request-ID"] = request_id

        return response

    except Exception as e:
        process_time = time.time() - start_time
        logger.error(f"[{request_id}] ERROR after {process_time:.3f}s: {str(e)}", exc_info=True)

        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "Internal server error",
                "detail": str(e) if settings.DEBUG else "An error occurred",
                "request_id": request_id
            }
        )

# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled exception for {request.method} {request.url.path}", exc_info=True)

    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal server error",
            "detail": str(exc) if settings.DEBUG else "An error occurred",
            "path": str(request.url.path)
        }
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
logger.info("Registering API routers...")
app.include_router(auth.router)
app.include_router(progress.router)
app.include_router(economy.router)
app.include_router(leaderboard.router)
logger.info("API routers registered successfully")

@app.get("/")
async def root():
    logger.debug("Root endpoint called")
    return {
        "game": "Crownborn: Shattered Lineage",
        "version": "1.0.0",
        "status": "online"
    }

@app.get("/health")
async def health_check():
    logger.debug("Health check endpoint called")
    return {"status": "healthy", "timestamp": time.time()}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )

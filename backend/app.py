from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers.email_router import router as email_router
import uvicorn
from logger_config import logger

# Create FastAPI app
app = FastAPI(
    title="User Registration Email Service",
    description="API service for async email sending in user registration flow",
    version="1.0.0"
)

logger.info("Initializing FastAPI application")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(email_router)
logger.info("Registered email router")


@app.get("/")
async def root():
    """Root endpoint."""
    logger.debug("Root endpoint accessed")
    return {
        "message": "User Registration Email Service API",
        "version": "1.0.0",
        "docs": "/docs"
    }


if __name__ == '__main__':
    import sys
    from pathlib import Path
    # Add backend directory to path for imports
    backend_dir = Path(__file__).parent
    if str(backend_dir) not in sys.path:
        sys.path.insert(0, str(backend_dir))
    
    logger.info("Starting uvicorn server on 0.0.0.0:5001")
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=5001,
        reload=True,
        log_config=None  # Use our custom logger
    )

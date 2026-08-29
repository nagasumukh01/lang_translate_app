import os
import time
import shutil
import asyncio
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from backend.app.api import health, translation, voice

logger = logging.getLogger("uvicorn")

async def cleanup_old_files():
    """
    Background loop that deletes processed audio files older than 5 minutes.
    This ensures privacy and keeps disk usage bounded.
    """
    while True:
        try:
            now = time.time()
            threshold_seconds = 300  # 5 minutes
            for folder in ["temp_audio", "temp_processing"]:
                if os.path.exists(folder):
                    for filename in os.listdir(folder):
                        file_path = os.path.join(folder, filename)
                        if os.path.isfile(file_path):
                            file_age = now - os.path.getmtime(file_path)
                            if file_age > threshold_seconds:
                                try:
                                    os.remove(file_path)
                                    logger.info(f"Cleanup: Deleted old temp file {file_path}")
                                except Exception as ex:
                                    logger.error(f"Cleanup: Failed to delete {file_path}: {str(ex)}")
        except Exception as e:
            logger.error(f"Cleanup task failed: {str(e)}")
        await asyncio.sleep(120)  # Check every 2 minutes

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup logic
    logger.info("Starting BhashaBridge Backend...")
    # Make sure temporary folders are clean on boot
    for folder in ["temp_audio", "temp_processing"]:
        if os.path.exists(folder):
            try:
                shutil.rmtree(folder)
            except Exception as e:
                logger.error(f"Failed to clear folder {folder} on boot: {str(e)}")
        os.makedirs(folder, exist_ok=True)

    # Start background cleanup task
    cleanup_task = asyncio.create_task(cleanup_old_files())
    yield
    # Shutdown logic
    logger.info("Shutting down BhashaBridge Backend...")
    cleanup_task.cancel()

app = FastAPI(
    title="BhashaBridge Backend",
    description="Multilingual Voice-to-Voice Translation API",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for local testing from flutter apps
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount the static files directory to serve the synthesized text-to-speech audio files
app.mount("/static", StaticFiles(directory="temp_audio"), name="static")

# Mount API Routers
app.include_router(health.router, prefix="/api", tags=["Health"])
app.include_router(translation.router, prefix="/api", tags=["Translation"])
app.include_router(voice.router, prefix="/api", tags=["Voice Translation"])

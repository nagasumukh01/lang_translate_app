import logging
from backend.app.providers.stt.free_stt import FreeSTTProvider

logger = logging.getLogger("uvicorn")

class STTService:
    def __init__(self):
        logger.info("STTService: Initialized FreeSTTProvider (keyless).")
        self.provider = FreeSTTProvider()

    async def transcribe(self, audio_path: str, source_language: str) -> str:
        return await self.provider.transcribe(audio_path, source_language)

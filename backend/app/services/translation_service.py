import logging
from backend.app.providers.translation.free_translation import FreeTranslationProvider

logger = logging.getLogger("uvicorn")

class TranslationService:
    def __init__(self):
        logger.info("TranslationService: Initialized FreeTranslationProvider (keyless).")
        self.provider = FreeTranslationProvider()

    async def translate(self, text: str, source_language: str, target_language: str) -> str:
        return await self.provider.translate(text, source_language, target_language)

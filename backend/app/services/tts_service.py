import logging
from backend.app.providers.tts.edge_tts import EdgeTTSProvider, MockTTSProvider

logger = logging.getLogger("uvicorn")

class TTSService:
    def __init__(self):
        # EdgeTTS is free and requires no configuration. We can use it as the default.
        logger.info("TTSService: Initialized EdgeTTSProvider.")
        self.provider = EdgeTTSProvider()

    async def synthesize(self, text: str, target_language: str, output_path: str) -> str:
        try:
            return await self.provider.synthesize(text, target_language, output_path)
        except Exception as e:
            logger.error(f"TTS Synthesis error: {str(e)}. Falling back to mock synthesis.")
            mock_provider = MockTTSProvider()
            return await mock_provider.synthesize(text, target_language, output_path)

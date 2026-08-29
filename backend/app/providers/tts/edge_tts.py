import edge_tts
from backend.app.providers.tts.base import BaseTTSProvider

class EdgeTTSProvider(BaseTTSProvider):
    async def synthesize(self, text: str, target_language: str, output_path: str) -> str:
        if not text.strip():
            # Return empty file if text is empty
            with open(output_path, "wb") as f:
                f.write(b"")
            return output_path

        # Map language codes to natural sounding MS Edge voices
        # We prefer high-quality neural voices
        voice_map = {
            "en": "en-US-AriaNeural",       # English (US) female
            "kn": "kn-IN-SapnaNeural",      # Kannada (India) female
            "hi": "hi-IN-SwaraNeural",      # Hindi (India) female
            "te": "te-IN-ShrutiNeural"      # Telugu (India) female
        }
        
        voice = voice_map.get(target_language, "en-US-AriaNeural")

        try:
            # edge-tts is fully asynchronous
            communicate = edge_tts.Communicate(text, voice)
            await communicate.save(output_path)
            return output_path
        except Exception as e:
            raise Exception(f"Edge TTS synthesis failed: {str(e)}")

class MockTTSProvider(BaseTTSProvider):
    async def synthesize(self, text: str, target_language: str, output_path: str) -> str:
        # Creates a mock silent or simple WAV file for testing
        # To avoid issues, we write a small valid 1-second silent MP3 or empty bytes
        with open(output_path, "wb") as f:
            # Let's write an empty file or dummy bytes
            f.write(b"")
        return output_path

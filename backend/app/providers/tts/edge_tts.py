import edge_tts
from backend.app.providers.tts.base import BaseTTSProvider

class EdgeTTSProvider(BaseTTSProvider):
    async def synthesize(self, text: str, target_language: str, output_path: str) -> str:
        if not text.strip():
            # Return empty file if text is empty
            with open(output_path, "wb") as f:
                f.write(b"")
            return output_path

        # Check if the language is supported for Speech Synthesis.
        # We only synthesize voices for our supported list of languages:
        if target_language not in ["en", "kn", "hi", "te", "ta", "ml", "mr", "gu", "bn", "ur", "ja", "es", "fr", "de", "ko", "ar", "zh"]:
            with open(output_path, "wb") as f:
                f.write(b"")
            return output_path

        # Map language codes to natural sounding MS Edge voices
        # We prefer high-quality neural voices
        voice_map = {
            "en": "en-US-AriaNeural",       # English (US) female
            "kn": "kn-IN-SapnaNeural",      # Kannada (India) female
            "hi": "hi-IN-SwaraNeural",      # Hindi (India) female
            "te": "te-IN-ShrutiNeural",     # Telugu (India) female
            "ta": "ta-IN-PallaviNeural",    # Tamil (India) female
            "ml": "ml-IN-SobhanaNeural",    # Malayalam (India) female
            "mr": "mr-IN-AarohiNeural",     # Marathi (India) female
            "gu": "gu-IN-DhwaniNeural",     # Gujarati (India) female
            "bn": "bn-IN-TanishaaNeural",    # Bengali (India) female
            "ur": "ur-IN-NeelamNeural",     # Urdu (India) female
            "ja": "ja-JP-NanamiNeural",     # Japanese (Japan) female
            "es": "es-ES-ElviraNeural",     # Spanish (Spain) female
            "fr": "fr-FR-DeniseNeural",     # French (France) female
            "de": "de-DE-KatjaNeural",      # German (Germany) female
            "ko": "ko-KR-SunHiNeural",      # Korean (Korea) female
            "ar": "ar-AE-FatimaNeural",     # Arabic (UAE) female
            "zh": "zh-CN-XiaoxiaoNeural"    # Chinese (China) female
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

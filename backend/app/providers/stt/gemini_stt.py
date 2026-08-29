import google.generativeai as genai
from backend.app.providers.stt.base import BaseSTTProvider
from backend.app.config.settings import settings

class GeminiSTTProvider(BaseSTTProvider):
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        if self.api_key:
            genai.configure(api_key=self.api_key)

    async def transcribe(self, audio_path: str, source_language: str) -> str:
        if not self.api_key:
            raise Exception("Gemini API key is not configured in backend .env file.")

        # Map language codes to full names to improve model instruction quality
        lang_map = {
            "en": "English",
            "kn": "Kannada",
            "hi": "Hindi",
            "te": "Telugu"
        }
        language_name = lang_map.get(source_language, "English")

        try:
            # Upload the audio file to the GenAI files API
            # This is necessary because gemini-1.5-flash expects files API references for large multimedia
            audio_file = genai.upload_file(path=audio_path)
            
            # Use gemini-1.5-flash for fast and cost-effective transcribing
            model = genai.GenerativeModel("gemini-1.5-flash")
            
            prompt = (
                f"You are a professional transcriptionist. Transcribe the following speech audio "
                f"exactly as spoken in the {language_name} language. Do not translate it. "
                f"Provide ONLY the transcript text. Do not add any preamble, introductions, metadata, "
                f"or explanations. If no clear speech is detected, return an empty string."
            )
            
            response = model.generate_content([prompt, audio_file])
            
            # Clean up the file from GenAI servers immediately
            genai.delete_file(audio_file.name)
            
            text = response.text.strip()
            
            # If the response is empty or just quotes, clean it up
            if text.startswith('"') and text.endswith('"'):
                text = text[1:-1].strip()
                
            return text
        except Exception as e:
            raise Exception(f"Gemini Speech-to-Text failed: {str(e)}")
            
class MockSTTProvider(BaseSTTProvider):
    async def transcribe(self, audio_path: str, source_language: str) -> str:
        # Mock transcription for testing
        lang_map = {
            "en": "Hello, how are you?",
            "kn": "ನಮಸ್ಕಾರ, ನೀವು ಹೇಗಿದ್ದೀರಿ?",
            "hi": "नमस्ते, आप कैसे हैं?",
            "te": "నమస్కారం, మీరు ఎలా ఉన్నారు?"
        }
        return lang_map.get(source_language, "Hello!")

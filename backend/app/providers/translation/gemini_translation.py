import google.generativeai as genai
from backend.app.providers.translation.base import BaseTranslationProvider
from backend.app.config.settings import settings

class GeminiTranslationProvider(BaseTranslationProvider):
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        if self.api_key:
            genai.configure(api_key=self.api_key)

    async def translate(self, text: str, source_language: str, target_language: str) -> str:
        if not text.strip():
            return ""

        if source_language == target_language:
            return text

        if not self.api_key:
            raise Exception("Gemini API key is not configured in backend .env file.")

        lang_map = {
            "en": "English",
            "kn": "Kannada",
            "hi": "Hindi",
            "te": "Telugu"
        }
        src_name = lang_map.get(source_language, source_language)
        tgt_name = lang_map.get(target_language, target_language)

        try:
            model = genai.GenerativeModel("gemini-1.5-flash")
            
            prompt = (
                f"You are a professional translator. Translate the following text from {src_name} to {tgt_name}. "
                f"Ensure the translation is natural, grammatically correct, and maintains the original meaning and tone. "
                f"Do not include any footnotes, explanations, notes, pronunciation, or preamble. Return ONLY the translated text.\n\n"
                f"Text to translate:\n{text}"
            )
            
            response = model.generate_content(prompt)
            translated = response.text.strip()
            
            # Simple cleanup of quotes if model wraps response
            if translated.startswith('"') and translated.endswith('"'):
                translated = translated[1:-1].strip()
                
            return translated
        except Exception as e:
            raise Exception(f"Gemini translation failed: {str(e)}")

class MockTranslationProvider(BaseTranslationProvider):
    async def translate(self, text: str, source_language: str, target_language: str) -> str:
        # standard mock phrases
        phrases = {
            "en": "Hello, how are you?",
            "kn": "ನಮಸ್ಕಾರ, ನೀವು ಹೇಗಿದ್ದೀರಿ?",
            "hi": "नमस्ते, आप कैसे हैं?",
            "te": "నమస్కారం, మీరు ఎలా ఉన్నారు?"
        }
        
        # Check if the input text corresponds to our mock speech
        # (case-insensitive for English, and checking substring for other scripts)
        is_standard_mock_phrase = False
        for lang_code, phrase in phrases.items():
            if phrase.lower() in text.lower() or text.lower() in phrase.lower():
                is_standard_mock_phrase = True
                break

        if is_standard_mock_phrase:
            # Return the proper target language phrase from our map
            return phrases.get(target_language, f"Hello ({target_language})")

        # Fallback dictionary for "railway station" queries
        railway_mocks = {
            "en": "Where is the railway station?",
            "kn": "ರೈಲ್ವೆ ನಿಲ್ದಾಣ ಎಲ್ಲಿದೆ?",
            "hi": "रेलवे स्टेशन कहाँ है?",
            "te": "రైల్వే స్టేషన్ ఎక్కడ ఉంది?"
        }
        
        is_railway_query = "railway" in text.lower() or "ನಿಲ್ದಾಣ" in text or "स्टेशन" in text or "స్టేషన్" in text
        if is_railway_query:
            return railway_mocks.get(target_language, "Where is the station?")
            
        return f"[Translated from {source_language} to {target_language}]: {text}"

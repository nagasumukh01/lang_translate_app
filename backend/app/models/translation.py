from pydantic import BaseModel
from typing import Optional

class TranslationRequest(BaseModel):
    text: str
    source_language: str
    target_language: str

class TranslationResponse(BaseModel):
    source_text: str
    translated_text: str
    source_language: str
    target_language: str

class VoiceTranslationResponse(BaseModel):
    source_text: str
    translated_text: str
    source_language: str
    target_language: str
    audio_url: str

from fastapi import APIRouter, Depends, HTTPException
from backend.app.models.translation import TranslationRequest, TranslationResponse
from backend.app.services.translation_service import TranslationService

router = APIRouter()

# Dependency injection for the translation service
def get_translation_service() -> TranslationService:
    return TranslationService()

@router.post("/translate", response_model=TranslationResponse)
async def translate_text(
    request: TranslationRequest,
    service: TranslationService = Depends(get_translation_service)
):
    try:
        translated = await service.translate(
            text=request.text,
            source_language=request.source_language,
            target_language=request.target_language
        )
        return TranslationResponse(
            source_text=request.text,
            translated_text=translated,
            source_language=request.source_language,
            target_language=request.target_language
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

import os
import uuid
import shutil
import logging
from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from backend.app.models.translation import VoiceTranslationResponse
from backend.app.services.stt_service import STTService
from backend.app.services.translation_service import TranslationService
from backend.app.services.tts_service import TTSService

router = APIRouter()
logger = logging.getLogger("uvicorn")

# Dependencies
def get_stt_service() -> STTService:
    return STTService()

def get_translation_service() -> TranslationService:
    return TranslationService()

def get_tts_service() -> TTSService:
    return TTSService()

# Ensure directories exist
TEMP_DIR = "temp_processing"
AUDIO_OUT_DIR = "temp_audio"
os.makedirs(TEMP_DIR, exist_ok=True)
os.makedirs(AUDIO_OUT_DIR, exist_ok=True)

@router.post("/voice/translate", response_model=VoiceTranslationResponse)
async def translate_voice(
    audio: UploadFile = File(...),
    source_language: str = Form(...),
    target_language: str = Form(...),
    stt: STTService = Depends(get_stt_service),
    translation: TranslationService = Depends(get_translation_service),
    tts: TTSService = Depends(get_tts_service)
):
    # Create a unique temporary filename for the uploaded file
    file_ext = os.path.splitext(audio.filename)[1] or ".m4a"
    temp_input_path = os.path.join(TEMP_DIR, f"{uuid.uuid4()}{file_ext}")
    
    try:
        # 1. Save uploaded file to temp directory
        with open(temp_input_path, "wb") as buffer:
            shutil.copyfileobj(audio.file, buffer)
            
        file_size = os.path.getsize(temp_input_path)
        logger.info(f"Voice API: Received audio file '{audio.filename}', size: {file_size} bytes")
            
        # 2. Convert Speech-to-Text
        logger.info(f"STT: Transcribing {source_language} audio...")
        transcribed_text = await stt.transcribe(temp_input_path, source_language)
        
        if not transcribed_text.strip():
            raise HTTPException(
                status_code=400, 
                detail="We couldn't detect any speech. Please try again."
            )
            
        logger.info(f"STT Result: '{transcribed_text}'")
        
        # 3. Translate the text
        logger.info(f"Translation: Translating '{transcribed_text}' from {source_language} to {target_language}...")
        translated_text = await translation.translate(transcribed_text, source_language, target_language)
        logger.info(f"Translation Result: '{translated_text}'")
        
        # 4. Convert Text-to-Speech
        logger.info(f"TTS: Synthesizing target audio in {target_language}...")
        output_filename = f"tts_{uuid.uuid4()}.mp3"
        temp_output_path = os.path.join(AUDIO_OUT_DIR, output_filename)
        await tts.synthesize(translated_text, target_language, temp_output_path)
        
        # 5. Return response with relative URL
        audio_url = f"/static/{output_filename}"
        
        return VoiceTranslationResponse(
            source_text=transcribed_text,
            translated_text=translated_text,
            source_language=source_language,
            target_language=target_language,
            audio_url=audio_url
        )
        
    except HTTPException as he:
        # Re-raise HTTP exceptions (e.g. no speech detected)
        raise he
    except Exception as e:
        logger.error(f"Voice pipeline error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Voice translation failed: {str(e)}")
    finally:
        # Clean up temporary input file immediately to respect privacy
        if os.path.exists(temp_input_path):
            try:
                os.remove(temp_input_path)
            except Exception as e:
                logger.error(f"Failed to delete temp file {temp_input_path}: {str(e)}")

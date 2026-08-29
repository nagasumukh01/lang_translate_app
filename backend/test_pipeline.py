import asyncio
import os
import sys

# Add project root to path so we can import app modules
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.app.providers.tts.edge_tts import EdgeTTSProvider
from backend.app.providers.stt.free_stt import FreeSTTProvider
from backend.app.providers.translation.free_translation import FreeTranslationProvider

async def test_all():
    tts = EdgeTTSProvider()
    stt = FreeSTTProvider()
    translator = FreeTranslationProvider()
    
    test_dir = "test_run"
    os.makedirs(test_dir, exist_ok=True)
    
    print("==================================================")
    print("STARTING BHASHABRIDGE KEYLESS PIPELINE INTEGRATION TEST")
    print("==================================================")
    
    # 1. Synthesize some English speech to WAV using EdgeTTS
    text_to_speak = "Hello, how are you today?"
    input_audio_path = os.path.join(test_dir, "input_speech.wav")
    print(f"1. Synthesizing input speech: '{text_to_speak}'...")
    
    try:
        await tts.synthesize(text=text_to_speak, target_language="en", output_path=input_audio_path)
        size = os.path.getsize(input_audio_path)
        print(f"   -> Generated input audio file size: {size} bytes")
    except Exception as e:
        print(f"   [ERROR] TTS synthesis failed: {str(e)}")
        return

    # 2. Transcribe it back to text using FreeSTT
    print("2. Transcribing audio back to text...")
    try:
        transcribed_text = await stt.transcribe(audio_path=input_audio_path, source_language="en")
        print(f"   -> Transcribed text: '{transcribed_text}'")
        if not transcribed_text:
            print("   [ERROR] Transcribed text is empty!")
            return
    except Exception as e:
        print(f"   [ERROR] Speech-to-Text failed: {str(e)}")
        return

    # 3. Translate it to Kannada using FreeTranslation
    print("3. Translating transcribed text to Kannada...")
    try:
        translated_text = await translator.translate(text=transcribed_text, source_language="en", target_language="kn")
        safe_print = translated_text.encode('ascii', errors='backslashreplace').decode('ascii')
        print(f"   -> Translated text (Kannada): '{safe_print}'")
    except Exception as e:
        print(f"   [ERROR] Translation failed: {str(e)}")
        return

    # 4. Synthesize the translated Kannada text back to audio
    output_audio_path = os.path.join(test_dir, "translated_speech.wav")
    print("4. Synthesizing translated speech to Kannada audio...")
    try:
        await tts.synthesize(text=translated_text, target_language="kn", output_path=output_audio_path)
        out_size = os.path.getsize(output_audio_path)
        print(f"   -> Generated output audio file size: {out_size} bytes")
    except Exception as e:
        print(f"   [ERROR] Target TTS synthesis failed: {str(e)}")
        return

    print("==================================================")
    print("TEST PASSED SUCCESSFULLY! ALL PROVIDERS WORKING FINE.")
    print("==================================================")

if __name__ == "__main__":
    asyncio.run(test_all())

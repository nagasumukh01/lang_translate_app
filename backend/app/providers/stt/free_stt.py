import speech_recognition as sr
import logging
import os
import subprocess
import wave

logger = logging.getLogger("uvicorn")

class FreeSTTProvider:
    async def transcribe(self, audio_path: str, source_language: str) -> str:
        # Map language codes to Google Web STT language codes
        lang_map = {
            "en": "en-IN",  # English (India)
            "kn": "kn-IN",  # Kannada (India)
            "hi": "hi-IN",  # Hindi (India)
            "te": "te-IN",  # Telugu (India)
            "ta": "ta-IN"   # Tamil (India)
        }

        if source_language not in lang_map:
            name_map = {"kok": "Konkani", "tcy": "Tulu"}
            lang_name = name_map.get(source_language, source_language.upper())
            raise Exception(f"Speech recognition is not supported for {lang_name} yet. Please speak in English, Kannada, Hindi, Telugu, or Tamil.")

        language_locale = lang_map[source_language]

        # Check if the file is a standard WAV file (starts with RIFF)
        is_wav = False
        try:
            with open(audio_path, 'rb') as f:
                header = f.read(4)
                if header == b'RIFF':
                    is_wav = True
        except Exception as e:
            logger.error(f"FreeSTT: Failed to read file header: {str(e)}")

        # If it's not a WAV file (e.g., it is M4A or WebM), use local FFmpeg to convert it
        actual_audio_path = audio_path
        if not is_wav:
            logger.info("FreeSTT: Non-WAV file detected. Converting to WAV using local FFmpeg...")
            converted_path = audio_path + "_converted.wav"
            
            # Locate local ffmpeg.exe
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
            ffmpeg_path = os.path.join(base_dir, "bin", "ffmpeg.exe")
            
            if not os.path.exists(ffmpeg_path):
                # Fallback to system PATH binary if local bin/ffmpeg.exe is missing
                ffmpeg_path = "ffmpeg"
                logger.warning(f"FreeSTT: Local ffmpeg.exe not found. Falling back to system 'ffmpeg'.")

            cmd = [
                ffmpeg_path,
                "-y",                   # Overwrite output file
                "-i", audio_path,       # Input file path
                "-acodec", "pcm_s16le", # Convert to 16-bit linear PCM
                "-ac", "1",             # Force mono channel
                "-ar", "16000",         # Set sampling rate to 16000Hz
                converted_path
            ]
            
            try:
                # Prevent popup CMD windows on Windows systems
                startupinfo = None
                if os.name == 'nt':
                    startupinfo = subprocess.STARTUPINFO()
                    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW

                result = subprocess.run(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    startupinfo=startupinfo,
                    timeout=10
                )
                
                if result.returncode != 0:
                    err_msg = result.stderr.decode('utf-8', errors='ignore')
                    logger.error(f"FreeSTT: FFmpeg failed with exit code {result.returncode}: {err_msg}")
                    raise Exception("FFmpeg execution failed")
                    
                actual_audio_path = converted_path
                logger.info("FreeSTT: File successfully converted to standard WAV format.")
            except Exception as e:
                logger.warning(f"FreeSTT: FFmpeg conversion failed ({str(e)}). Trying raw PCM wrapper fallback...")
                # Last resort fallback: Wrap raw bytes into a WAV container
                actual_audio_path = audio_path + "_wrapped.wav"
                try:
                    with open(audio_path, 'rb') as pcm_file:
                        pcm_data = pcm_file.read()
                    with wave.open(actual_audio_path, 'wb') as wav_file:
                        wav_file.setnchannels(1)
                        wav_file.setsampwidth(2)  # 16-bit
                        wav_file.setframerate(16000)
                        wav_file.writeframes(pcm_data)
                except Exception as ex:
                    logger.error(f"FreeSTT: Raw PCM wrapper fallback failed: {str(ex)}")
                    raise Exception(f"Failed to process audio file: {str(ex)}")

        recognizer = sr.Recognizer()
        
        try:
            # Read the WAV audio file
            with sr.AudioFile(actual_audio_path) as source:
                audio_data = recognizer.record(source)
                
            logger.info(f"FreeSTT: Contacting Google free web speech API for {language_locale}...")
            # Use Google's free keyless Web speech API
            text = recognizer.recognize_google(audio_data, language=language_locale)
            return text.strip()
        except sr.UnknownValueError:
            logger.warning("FreeSTT: Google Speech Recognition could not understand the audio.")
            return ""
        except sr.RequestError as e:
            logger.error(f"FreeSTT: Google Speech Recognition service error: {str(e)}")
            raise Exception("Could not reach Speech Recognition service. Please check network connection.")
        except Exception as e:
            logger.error(f"FreeSTT: Unexpected error: {str(e)}")
            raise Exception(f"Speech transcription failed: {str(e)}")
        finally:
            # Clean up the converted file if we created it
            if actual_audio_path != audio_path:
                if os.path.exists(actual_audio_path):
                    try:
                        os.remove(actual_audio_path)
                        logger.info("FreeSTT: Cleaned up temporary converted WAV file.")
                    except Exception as e:
                        logger.error(f"FreeSTT: Failed to delete temporary file: {str(e)}")

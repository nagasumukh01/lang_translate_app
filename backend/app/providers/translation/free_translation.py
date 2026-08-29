import logging
import urllib.request
import urllib.parse
import re
import asyncio
from html import unescape
from backend.app.providers.translation.base import BaseTranslationProvider

logger = logging.getLogger("uvicorn")

class FreeTranslationProvider(BaseTranslationProvider):
    async def translate(self, text: str, source_language: str, target_language: str) -> str:
        if not text.strip():
            return ""

        if source_language == target_language:
            return text

        try:
            logger.info(f"FreeTranslation: Translating '{text}' from {source_language} to {target_language} using Google Mobile API...")
            
            url = "https://translate.google.com/m"
            params = {
                "sl": source_language,
                "tl": target_language,
                "q": text
            }
            query_string = urllib.parse.urlencode(params)
            full_url = f"{url}?{query_string}"
            
            req = urllib.request.Request(
                full_url,
                headers={
                    "User-Agent": "Mozilla/5.0 (Linux; Android 10; SM-A102U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
                }
            )
            
            # Execute blocking urlopen in executor to keep the event loop responsive
            def fetch():
                with urllib.request.urlopen(req, timeout=10) as res:
                    return res.read().decode('utf-8')
            
            loop = asyncio.get_event_loop()
            html = await loop.run_in_executor(None, fetch)
            
            # Extract result using regex from mobile layout
            match = re.search(r'<div[^>]*class="result-container"[^>]*>(.*?)</div>', html, re.DOTALL)
            if match:
                translated_text = unescape(match.group(1).strip())
                logger.info(f"FreeTranslation: Translation successful: '{translated_text}'")
                return translated_text
            else:
                raise Exception("Translation result container not found in HTML response")
        except Exception as e:
            logger.error(f"FreeTranslation: Translation failed: {str(e)}")
            raise Exception(f"Translation failed: {str(e)}")

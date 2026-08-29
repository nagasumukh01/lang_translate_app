from abc import ABC, abstractmethod

class BaseSTTProvider(ABC):
    @abstractmethod
    async def transcribe(self, audio_path: str, source_language: str) -> str:
        """
        Transcribes the given audio file to text.
        
        Args:
            audio_path (str): The absolute path to the local audio file.
            source_language (str): The language code (e.g. 'en', 'kn', 'hi', 'te').
            
        Returns:
            str: The transcribed text.
        """
        pass

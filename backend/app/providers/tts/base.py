from abc import ABC, abstractmethod

class BaseTTSProvider(ABC):
    @abstractmethod
    async def synthesize(self, text: str, target_language: str, output_path: str) -> str:
        """
        Synthesizes text into speech and saves it as an audio file.
        
        Args:
            text (str): The text to convert to speech.
            target_language (str): The target language code (e.g. 'en', 'kn', 'hi', 'te').
            output_path (str): The local path where the generated audio file should be saved.
            
        Returns:
            str: The path to the generated audio file.
        """
        pass

from abc import ABC, abstractmethod

class BaseTranslationProvider(ABC):
    @abstractmethod
    async def translate(self, text: str, source_language: str, target_language: str) -> str:
        """
        Translates text from source language to target language.
        
        Args:
            text (str): The text to translate.
            source_language (str): The source language code.
            target_language (str): The target language code.
            
        Returns:
            str: The translated text.
        """
        pass

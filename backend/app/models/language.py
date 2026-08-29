from pydantic import BaseModel

class LanguageModel(BaseModel):
    code: str
    name: str
    native_name: str
    flag: str

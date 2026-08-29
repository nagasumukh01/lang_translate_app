import pytest
from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_text_translate_endpoint():
    payload = {
        "text": "Where is the railway station?",
        "source_language": "en",
        "target_language": "kn"
    }
    response = client.post("/api/translate", json=payload)
    assert response.status_code == 200
    
    data = response.json()
    assert data["source_text"] == "Where is the railway station?"
    assert "translated_text" in data
    assert data["source_language"] == "en"
    assert data["target_language"] == "kn"

def test_voice_translate_validation_error():
    # If we call /api/voice/translate without arguments, it should return 422 Unprocessable Entity
    response = client.post("/api/voice/translate")
    assert response.status_code == 422

def test_voice_translate_mock_success():
    # Test with a dummy file upload using the mock provider flow (or actual provider if key is present)
    # We pass mock data
    import io
    dummy_wav = io.BytesIO(b"RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00\x22\x56\x00\x00\x44\xac\x00\x00\x02\x00\x10\x00data\x00\x00\x00\x00")
    
    files = {"audio": ("test.wav", dummy_wav, "audio/wav")}
    data = {
        "source_language": "en",
        "target_language": "kn"
    }
    
    response = client.post("/api/voice/translate", files=files, data=data)
    
    # If the API key is not configured, it will use MockSTTProvider, which transcribes to a mock text,
    # translates it, and EdgeTTS generates an audio response. It should be successful.
    if response.status_code == 200:
        json_data = response.json()
        assert "source_text" in json_data
        assert "translated_text" in json_data
        assert json_data["source_language"] == "en"
        assert json_data["target_language"] == "kn"
        assert "audio_url" in json_data
        assert json_data["audio_url"].startswith("/static/")
    else:
        # If Speech-to-Text returns empty transcript, it will raise 400
        assert response.status_code == 400
        assert "speech" in response.json()["detail"].lower()

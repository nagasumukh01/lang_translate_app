# BhashaBridge — Multilingual Voice-to-Voice Translation App

BhashaBridge is a production-quality, Clean Architecture Flutter mobile application integrated with a Python FastAPI backend that enables real-time, two-way vocal communication between people speaking different languages.

It converts speech in a source language to text, translates it to a target language, generates synthesized audio, and automatically handles conversation direction reversal when the second party speaks.

---

## 1. Project Architecture

The system is decoupled using clear service and provider boundaries, ensuring API credentials remain on the backend and language configuration is centralized.

```
                  ┌───────────────────────┐
                  │  Flutter Mobile App   │
                  └───────────┬───────────┘
                              │
                              │ (HTTPS POST /api/voice/translate)
                              ▼
                  ┌───────────────────────┐
                  │    FastAPI Backend    │
                  └───────────┬───────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌───────────┐   ┌───────────┐   ┌───────────┐
        │    STT    │   │Translate  │   │    TTS    │
        │  Service  │   │  Service  │   │  Service  │
        └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
              │               │               │
              ▼               ▼               ▼
        ┌───────────┐   ┌───────────┐   ┌───────────┐
        │  Gemini   │   │  Gemini   │   │ Microsoft │
        │    STT    │   │Translate  │   │ Edge TTS  │
        │ Provider  │   │ Provider  │   │ Provider  │
        └───────────┘   └───────────┘   └───────────┘
```

### Components
1. **Flutter App**: Implements Clean Architecture with layers:
   - **Presentation**: Riverpod providers for state machines (Sealed State patterns), GoRouter paths, and Hold-to-Talk gestures.
   - **Domain**: Pure business logic entities like `ConversationMessage` and central language configurations.
   - **Data**: Hive for storing local history database and HTTP network adapters.
2. **FastAPI Backend**: Hosts the translation pipeline. Decoupled using base abstract classes (`BaseSTTProvider`, `BaseTranslationProvider`, `BaseTTSProvider`) so providers can be swapped (e.g. Gemini, OpenAI, Mock).
   - **Speech-to-Text**: Utilizes **Gemini-1.5-Flash** file uploads for transcription.
   - **Translation**: Utilizes **Gemini-1.5-Flash** for context-aware translations.
   - **Text-to-Speech**: Utilizes Microsoft **Edge-TTS** (a free, natural-sounding service requiring no API key).

---

## 2. Supported Languages

The application includes a centralized configuration located at `lib/core/constants/languages.dart`.
Initial supported languages:
- 🇺🇸 **English** (`en`)
- 🇮🇳 **Kannada** (`kn`)
- 🇮🇳 **Hindi** (`hi`)
- 🇮🇳 **Telugu** (`te`)

---

## 3. Backend Setup

### Prerequisites
- Python 3.10+ installed

### Configuration
1. Go to the `backend/` directory:
   ```bash
   cd backend
   ```
2. Create a virtual environment:
   ```bash
   python -m venv .venv
   ```
3. Activate the virtual environment:
   - **Windows (PowerShell)**: `.venv\Scripts\Activate.ps1`
   - **macOS / Linux**: `source .venv/bin/activate`
4. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
5. Copy the configuration template:
   ```bash
   copy .env.example .env
   ```
   *(On macOS/Linux, run `cp .env.example .env`)*
6. Open `.env` and fill in your Gemini API Key:
   ```env
   GEMINI_API_KEY=AIzaSyYourKeyHere...
   ```
   *Note: If no API key is set, the backend will run using warning-logged Mock providers, allowing UI testing without API charges.*

### Running the Backend
Run the backend using uvicorn:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
Verify the server starts and check health at: `http://localhost:8000/api/health`.

---

## 4. Flutter Setup

### Prerequisites
- Flutter SDK (Ensure `flutter` command is on your PATH)
- A connected Android / iOS device or emulator

### Running the App
1. Get the package dependencies:
   ```bash
   flutter pub get
   ```
2. Run the application:
   ```bash
   flutter run
   ```

### Debugging on Physical Devices
If you run the app on a physical phone, the phone needs to communicate with the PC hosting your FastAPI server:
1. Ensure both your computer and your phone are on the **same Wi-Fi network**.
2. Find your computer's local IP address (e.g. `192.168.1.50`).
3. Tap the **Settings (Gear)** icon in the top right corner of the **Conversation Screen** inside the app.
4. Input your PC's server address (e.g. `http://192.168.1.50:8000`) and click **Save**.

---

## 5. Adding a New Language

Adding a new language is designed to be highly extensible:

### Step 1: Update Flutter Configuration
Open `lib/core/constants/languages.dart` and append the new language to the `supportedLanguages` list:
```dart
  AppLanguage(
    code: 'ml',
    name: 'Malayalam',
    nativeName: 'മലയാളം',
    flag: '🇮🇳',
  )
```

### Step 2: Configure Backend Voice Voices
Open `backend/app/providers/tts/edge_tts.py` and map the new language code to an Edge-TTS voice in the `voice_map` dictionary:
```python
        voice_map = {
            "en": "en-US-AriaNeural",
            "kn": "kn-IN-SapnaNeural",
            "hi": "hi-IN-SwaraNeural",
            "te": "te-IN-ShrutiNeural",
            "ml": "ml-IN-SobhanaNeural"  # Added Malayalam voice
        }
```

---

## 6. Troubleshooting

1. **"We couldn't detect any speech. Please try again."**
   - Verify that your microphone has permission.
   - Verify that your recording has sound and is not a silent input.
2. **Backend is unavailable / Connection Timeout**
   - Check if uvicorn is running.
   - If running on Android emulator, ensure the client is pointing to `http://10.0.2.2:8000` (which refers to local PC's localhost).
   - If running on a physical phone, verify the IP settings via the Gear Settings icon.
3. **Microsoft Edge-TTS synthesis failed**
   - Microsoft Edge TTS requires an active internet connection. Ensure the backend server is connected to the web.

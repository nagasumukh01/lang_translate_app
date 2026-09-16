import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';

/// Standalone translation service that runs entirely on-device + Google Translate.
/// No backend server needed.
class StandaloneTranslationService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttInitialized = false;
  bool _sttAvailable = false;

  // STT locale mapping
  static const Map<String, String> sttLocales = {
    'en': 'en_US',
    'kn': 'kn_IN',
    'hi': 'hi_IN',
    'te': 'te_IN',
    'ta': 'ta_IN',
    'ml': 'ml_IN',
    'mr': 'mr_IN',
    'gu': 'gu_IN',
    'bn': 'bn_IN',
    'ur': 'ur_PK',
    'ja': 'ja_JP',
    'es': 'es_ES',
    'fr': 'fr_FR',
    'de': 'de_DE',
    'ko': 'ko_KR',
    'ar': 'ar_SA',
    'zh': 'zh_CN',
  };

  // TTS language mapping
  static const Map<String, String> ttsLanguages = {
    'en': 'en-US',
    'kn': 'kn-IN',
    'hi': 'hi-IN',
    'te': 'te-IN',
    'ta': 'ta-IN',
    'ml': 'ml-IN',
    'mr': 'mr-IN',
    'gu': 'gu-IN',
    'bn': 'bn-IN',
    'ur': 'ur-PK',
    'ja': 'ja-JP',
    'es': 'es-ES',
    'fr': 'fr-FR',
    'de': 'de-DE',
    'ko': 'ko-KR',
    'ar': 'ar-SA',
    'zh': 'zh-CN',
  };

  /// Initialize STT engine. Returns true if available.
  /// Can be called multiple times safely — retries if previous init failed.
  Future<bool> initStt() async {
    if (_sttInitialized && _sttAvailable) return true;

    try {
      _sttAvailable = await _stt.initialize(
        onError: (error) {
          debugPrint('STT error: ${error.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('STT status: $status');
        },
      );
      _sttInitialized = true;
      debugPrint('STT initialized: available=$_sttAvailable');
    } catch (e) {
      debugPrint('STT init exception: $e');
      _sttAvailable = false;
      _sttInitialized = false;
    }

    return _sttAvailable;
  }

  /// Initialize TTS engine with default settings
  Future<void> initTts() async {
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    // Ensure TTS engine is ready on Android
    if (!kIsWeb) {
      await _tts.awaitSpeakCompletion(true);
    }
  }

  /// Start listening for speech input.
  /// Throws if STT is not available.
  Future<void> startListening({
    required String languageCode,
    required Function(String text, bool isFinal) onResult,
    required Function(String error) onError,
    Function(String status)? onStatus,
  }) async {
    // Always try to init (retries if failed before)
    final available = await initStt();
    if (!available) {
      onError('Speech recognition is not available. Please check that Google Speech Services is installed on your device.');
      return;
    }

    // Stop any existing listening session
    if (_stt.isListening) {
      await _stt.stop();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final locale = sttLocales[languageCode] ?? 'en_US';

    try {
      await _stt.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          final isFinal = result.finalResult;
          debugPrint('STT result: "$text" (final=$isFinal, confidence=${result.confidence})');
          onResult(text, isFinal);
        },
        localeId: locale,
        listenMode: ListenMode.dictation,
        cancelOnError: false,  // Don't cancel on temporary errors
        partialResults: true,
        listenFor: const Duration(seconds: 30),  // Max listen time
        pauseFor: const Duration(seconds: 3),    // Auto-stop after 3s silence
      );
      debugPrint('STT listening started with locale: $locale');
    } catch (e) {
      debugPrint('STT listen error: $e');
      onError('Could not start speech recognition: ${e.toString()}');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_stt.isListening) {
        await _stt.stop();
      }
    } catch (e) {
      debugPrint('STT stop error: $e');
    }
  }

  /// Check if currently listening
  bool get isListening => _stt.isListening;

  /// Translate text using Google Translate API (free, no API key needed)
  /// Uses the same endpoint as Google Translate app/extension (client=gtx)
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) return '';
    if (sourceLanguage == targetLanguage) return text;

    // Try multiple endpoints for reliability
    final endpoints = [
      'https://translate.googleapis.com/translate_a/single',
      'https://translate.google.com/translate_a/single',
    ];

    Exception? lastError;

    for (final endpoint in endpoints) {
      try {
        final url = Uri.parse(endpoint).replace(
          queryParameters: {
            'client': 'gtx',
            'sl': sourceLanguage,
            'tl': targetLanguage,
            'dt': 't',
            'q': text,
          },
        );

        final response = await http.get(
          url,
          headers: {
            'User-Agent': 'GoogleTranslate/6.28.0',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          // Response is a JSON array: [[[translated_text, source_text, ...]]]
          final decoded = jsonDecode(response.body);
          if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
            final StringBuffer translated = StringBuffer();
            for (final segment in decoded[0]) {
              if (segment is List && segment.isNotEmpty && segment[0] is String) {
                translated.write(segment[0]);
              }
            }
            final result = translated.toString().trim();
            if (result.isNotEmpty) {
              debugPrint('Translation: "$text" → "$result"');
              return result;
            }
          }
          throw Exception('Could not parse translation response');
        } else if (response.statusCode == 403 || response.statusCode == 429) {
          lastError = Exception('Translation service temporarily unavailable. Trying fallback...');
          continue;
        } else {
          lastError = Exception('Translation failed (HTTP ${response.statusCode})');
          continue;
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (e.toString().contains('TimeoutException')) {
          lastError = Exception('Translation timed out. Check your internet connection.');
        }
        continue;
      }
    }

    throw lastError ?? Exception('Translation failed. Please try again.');
  }

  /// Speak translated text using device TTS
  Future<void> speak({
    required String text,
    required String languageCode,
  }) async {
    if (text.trim().isEmpty) return;

    final ttsLang = ttsLanguages[languageCode] ?? 'en-US';
    await _tts.setLanguage(ttsLang);
    debugPrint('TTS speaking in $ttsLang: "$text"');
    await _tts.speak(text);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  /// Set a completion handler for when TTS finishes speaking
  void setTtsCompletionHandler(Function() onComplete) {
    _tts.setCompletionHandler(onComplete);
  }

  /// Dispose resources
  void dispose() {
    _stt.stop();
    _tts.stop();
  }
}

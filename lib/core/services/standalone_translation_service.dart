import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';

/// Standalone translation service that runs entirely on-device + Google Translate.
/// No backend server needed.
class StandaloneTranslationService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttInitialized = false;

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

  /// Initialize STT engine
  Future<bool> initStt() async {
    if (_sttInitialized) return true;
    _sttInitialized = await _stt.initialize(
      onError: (error) {
        // Handle error silently
      },
    );
    return _sttInitialized;
  }

  /// Initialize TTS engine with default settings
  Future<void> initTts() async {
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// Start listening for speech input
  Future<void> startListening({
    required String languageCode,
    required Function(String text, bool isFinal) onResult,
    required Function(String error) onError,
  }) async {
    final available = await initStt();
    if (!available) {
      onError('Speech recognition is not available on this device.');
      return;
    }

    final locale = sttLocales[languageCode] ?? 'en_US';

    await _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      localeId: locale,
      listenMode: ListenMode.dictation,
      cancelOnError: true,
      partialResults: true,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _stt.stop();
  }

  /// Check if currently listening
  bool get isListening => _stt.isListening;

  /// Translate text using Google Translate mobile API (free, no API key)
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.trim().isEmpty) return '';
    if (sourceLanguage == targetLanguage) return text;

    try {
      final url = Uri.parse('https://translate.google.com/m').replace(
        queryParameters: {
          'sl': sourceLanguage,
          'tl': targetLanguage,
          'q': text,
        },
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; SM-A102U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Parse the translated text from the HTML response
        final body = response.body;
        final regex = RegExp(r'class="result-container">(.*?)</div>', dotAll: true);
        final match = regex.firstMatch(body);
        if (match != null) {
          String translated = match.group(1) ?? '';
          // Decode HTML entities
          translated = _decodeHtmlEntities(translated);
          return translated.trim();
        }

        // Fallback: try alternative pattern
        final altRegex = RegExp(r'class="t0">(.*?)</div>', dotAll: true);
        final altMatch = altRegex.firstMatch(body);
        if (altMatch != null) {
          String translated = altMatch.group(1) ?? '';
          translated = _decodeHtmlEntities(translated);
          return translated.trim();
        }

        throw Exception('Could not parse translation response');
      } else {
        throw Exception('Translation request failed (HTTP ${response.statusCode})');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Translation timed out. Check your internet connection.');
      }
      rethrow;
    }
  }

  /// Speak translated text using device TTS
  Future<void> speak({
    required String text,
    required String languageCode,
  }) async {
    if (text.trim().isEmpty) return;

    final ttsLang = ttsLanguages[languageCode] ?? 'en-US';
    await _tts.setLanguage(ttsLang);
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

  /// Decode common HTML entities
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll(RegExp(r'<[^>]*>'), ''); // Strip any remaining HTML tags
  }

  /// Dispose resources
  void dispose() {
    _stt.stop();
    _tts.stop();
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import 'conversation_provider.dart';
import 'translation_state.dart';

class TranslationNotifier extends StateNotifier<TranslationState> {
  final Ref _ref;
  String _recognizedText = '';
  bool _isFinalResult = false;

  TranslationNotifier(this._ref) : super(const TranslationInitial());

  /// Start listening for speech
  Future<void> startListening() async {
    final service = _ref.read(translationServiceProvider);
    final direction = _ref.read(activeDirectionProvider);

    _recognizedText = '';
    _isFinalResult = false;
    state = const TranslationRecording();

    try {
      await service.initStt();
      await service.initTts();

      await service.startListening(
        languageCode: direction.source.code,
        onResult: (text, isFinal) {
          _recognizedText = text;
          _isFinalResult = isFinal;

          // Update state to show live recognized text
          state = TranslationRecording(liveText: text);

          // If final result, automatically proceed to translation
          if (isFinal && text.trim().isNotEmpty) {
            _processTranslation();
          }
        },
        onError: (error) {
          state = TranslationError('Speech recognition error: $error');
        },
      );
    } catch (e) {
      state = TranslationError('Could not start listening: ${e.toString()}');
    }
  }

  /// Stop listening and process whatever we have
  Future<void> stopListening() async {
    final service = _ref.read(translationServiceProvider);
    await service.stopListening();

    // If we already got a final result, translation is already processing
    if (_isFinalResult) return;

    // If we have partial text, process it
    if (_recognizedText.trim().isNotEmpty) {
      await _processTranslation();
    } else {
      state = const TranslationError('No speech detected. Please try again.');
    }
  }

  /// Core pipeline: translate recognized text → speak translation
  Future<void> _processTranslation() async {
    final service = _ref.read(translationServiceProvider);
    final direction = _ref.read(activeDirectionProvider);
    final sourceText = _recognizedText.trim();

    if (sourceText.isEmpty) {
      state = const TranslationError('No speech detected. Please try again.');
      return;
    }

    try {
      // Step 1: Translate
      state = const TranslationTranslating();
      final translatedText = await service.translate(
        text: sourceText,
        sourceLanguage: direction.source.code,
        targetLanguage: direction.target.code,
      );

      if (translatedText.isEmpty) {
        state = const TranslationError('Translation returned empty. Please try again.');
        return;
      }

      // Step 2: Speak the translation
      state = const TranslationPlayingAudio();

      // Set completion handler before speaking
      final completer = Completer<void>();
      service.setTtsCompletionHandler(() {
        if (!completer.isCompleted) completer.complete();
      });

      await service.speak(
        text: translatedText,
        languageCode: direction.target.code,
      );

      // Wait for TTS to finish (with timeout)
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {},
      );

      // Step 3: Save to conversation history
      final currentSpeaker = _ref.read(activeSpeakerProvider);
      final speakerName = currentSpeaker == Speaker.you ? 'You' : 'Receiver';

      await _ref.read(conversationMessagesProvider.notifier).addMessage(
            speakerName: speakerName,
            sourceLanguage: direction.source.code,
            targetLanguage: direction.target.code,
            sourceText: sourceText,
            translatedText: translatedText,
          );

      state = TranslationSuccess(
        sourceText: sourceText,
        translatedText: translatedText,
      );

      // Auto-swap speaker for next turn
      _swapActiveSpeaker();
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('TimeoutException')) {
        errorMsg = 'Translation timed out. Check your internet connection.';
      }
      state = TranslationError(errorMsg);
    }
  }

  void _swapActiveSpeaker() {
    final current = _ref.read(activeSpeakerProvider);
    _ref.read(activeSpeakerProvider.notifier).state =
        current == Speaker.you ? Speaker.receiver : Speaker.you;
  }

  void reset() {
    final service = _ref.read(translationServiceProvider);
    service.stopListening();
    service.stopSpeaking();
    _recognizedText = '';
    state = const TranslationInitial();
  }
}

final translationNotifierProvider = StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  return TranslationNotifier(ref);
});

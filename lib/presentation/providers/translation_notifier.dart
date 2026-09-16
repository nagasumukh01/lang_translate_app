import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import 'conversation_provider.dart';
import 'translation_state.dart';

class TranslationNotifier extends StateNotifier<TranslationState> {
  final Ref _ref;
  String _recognizedText = '';
  bool _isProcessing = false;  // Guard against double-processing

  TranslationNotifier(this._ref) : super(const TranslationInitial());

  /// Start listening for speech
  Future<void> startListening() async {
    if (_isProcessing) return;  // Don't start if already processing

    final service = _ref.read(translationServiceProvider);
    final direction = _ref.read(activeDirectionProvider);

    _recognizedText = '';
    _isProcessing = false;

    try {
      // Initialize engines first
      await service.initStt();
      await service.initTts();

      // Only set recording state AFTER successful init
      state = const TranslationRecording();

      await service.startListening(
        languageCode: direction.source.code,
        onResult: (text, isFinal) {
          if (_isProcessing) return;  // Ignore results after processing started

          _recognizedText = text;

          // Update state to show live recognized text
          if (state is TranslationRecording) {
            state = TranslationRecording(liveText: text);
          }

          // If final result, automatically proceed to translation
          if (isFinal && text.trim().isNotEmpty) {
            _processTranslation();
          }
        },
        onError: (error) {
          if (!_isProcessing) {
            // If we have some text, try to translate it despite the error
            if (_recognizedText.trim().isNotEmpty) {
              debugPrint('STT error but have text, processing: "$_recognizedText"');
              _processTranslation();
            } else {
              state = TranslationError('Speech recognition error: $error');
            }
          }
        },
      );
    } catch (e) {
      state = TranslationError('Could not start listening: ${e.toString()}');
    }
  }

  /// Stop listening and process whatever we have
  Future<void> stopListening() async {
    if (_isProcessing) return;  // Already processing, don't interfere

    final service = _ref.read(translationServiceProvider);
    await service.stopListening();

    // Small delay to let any final result callback fire
    await Future.delayed(const Duration(milliseconds: 300));

    // If already processing (final result callback already fired), skip
    if (_isProcessing) return;

    // If we have text, process it
    if (_recognizedText.trim().isNotEmpty) {
      await _processTranslation();
    } else {
      state = const TranslationError('No speech detected. Please speak clearly and try again.');
    }
  }

  /// Core pipeline: translate recognized text → speak translation
  Future<void> _processTranslation() async {
    // Guard: prevent double-processing
    if (_isProcessing) return;
    _isProcessing = true;

    final service = _ref.read(translationServiceProvider);
    final direction = _ref.read(activeDirectionProvider);
    final sourceText = _recognizedText.trim();

    if (sourceText.isEmpty) {
      _isProcessing = false;
      state = const TranslationError('No speech detected. Please try again.');
      return;
    }

    // Make sure STT is stopped
    await service.stopListening();

    try {
      // Step 1: Translate
      state = const TranslationTranslating();
      debugPrint('Translating: "$sourceText" (${direction.source.code} → ${direction.target.code})');

      final translatedText = await service.translate(
        text: sourceText,
        sourceLanguage: direction.source.code,
        targetLanguage: direction.target.code,
      );

      if (translatedText.isEmpty) {
        _isProcessing = false;
        state = const TranslationError('Translation returned empty. Please try again.');
        return;
      }

      debugPrint('Translated: "$translatedText"');

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
      try {
        await completer.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('TTS timeout, proceeding');
          },
        );
      } catch (_) {
        // TTS completion timeout, proceed anyway
      }

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
    } finally {
      _isProcessing = false;
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
    _isProcessing = false;
    state = const TranslationInitial();
  }
}

final translationNotifierProvider = StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  return TranslationNotifier(ref);
});

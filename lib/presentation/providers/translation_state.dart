import 'package:flutter/foundation.dart';

@immutable
sealed class TranslationState {
  const TranslationState();
}

class TranslationInitial extends TranslationState {
  const TranslationInitial();
}

class TranslationRecording extends TranslationState {
  final String? liveText;
  const TranslationRecording({this.liveText});
}

class TranslationTranslating extends TranslationState {
  const TranslationTranslating();
}

class TranslationPlayingAudio extends TranslationState {
  const TranslationPlayingAudio();
}

class TranslationSuccess extends TranslationState {
  final String sourceText;
  final String translatedText;

  const TranslationSuccess({
    required this.sourceText,
    required this.translatedText,
  });
}

class TranslationError extends TranslationState {
  final String message;
  const TranslationError(this.message);
}

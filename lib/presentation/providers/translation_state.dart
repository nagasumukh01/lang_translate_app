import 'package:flutter/foundation.dart';

@immutable
sealed class TranslationState {
  const TranslationState();
}

class TranslationInitial extends TranslationState {
  const TranslationInitial();
}

class TranslationRecording extends TranslationState {
  const TranslationRecording();
}

class TranslationUploading extends TranslationState {
  const TranslationUploading();
}

class TranslationTranscribing extends TranslationState {
  const TranslationTranscribing();
}

class TranslationTranslating extends TranslationState {
  const TranslationTranslating();
}

class TranslationGeneratingSpeech extends TranslationState {
  const TranslationGeneratingSpeech();
}

class TranslationPlayingAudio extends TranslationState {
  const TranslationPlayingAudio();
}

class TranslationSuccess extends TranslationState {
  final String sourceText;
  final String translatedText;
  final String? audioPath;

  const TranslationSuccess({
    required this.sourceText,
    required this.translatedText,
    this.audioPath,
  });
}

class TranslationError extends TranslationState {
  final String message;
  const TranslationError(this.message);
}

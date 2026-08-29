import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';
import '../../core/utils/audio_helper.dart';
import 'conversation_provider.dart';
import 'translation_state.dart';

final audioHelperProvider = Provider<AudioHelper>((ref) {
  final helper = AudioHelper();
  ref.onDispose(() => helper.dispose());
  return helper;
});

class TranslationNotifier extends StateNotifier<TranslationState> {
  final ApiService _api;
  final AudioHelper _audio;
  final Ref _ref;
  String? _recordedPath;
  Timer? _stateTimer;
  bool _isRecording = false;
  bool _pendingStop = false;

  TranslationNotifier(this._api, this._audio, this._ref) : super(const TranslationInitial());

  Future<void> startRecording() async {
    _pendingStop = false;
    state = const TranslationInitial();
    final hasPermission = await _audio.requestMicrophonePermission();
    if (!hasPermission) {
      state = const TranslationError('Microphone permission is required to translate your speech.');
      return;
    }

    final path = await _audio.startRecording();
    if (path != null) {
      _recordedPath = path;
      _isRecording = true;
      state = const TranslationRecording();

      // If user already released the button while we were starting up
      if (_pendingStop) {
        _pendingStop = false;
        await stopAndTranslate();
      }
    } else {
      state = const TranslationError('Could not start recording. Please try again.');
    }
  }

  Future<void> stopAndTranslate() async {
    // If recording hasn't started yet, mark pending stop
    if (!_isRecording) {
      _pendingStop = true;
      return;
    }

    _isRecording = false;
    _pendingStop = false;

    final path = await _audio.stopRecording();
    if (path == null) {
      state = const TranslationError('Could not save recording. Please try again.');
      return;
    }
    _recordedPath = path;

    // A tiny delay to ensure file write completes
    await Future.delayed(const Duration(milliseconds: 300));

    // Start pipeline
    state = const TranslationUploading();
    _startProcessingAnimations();

    try {
      final direction = _ref.read(activeDirectionProvider);

      final response = await _api.translateVoice(
        audioPath: _recordedPath!,
        sourceLang: direction.source.code,
        targetLang: direction.target.code,
      );

      _stateTimer?.cancel();

      // Play audio automatically
      state = const TranslationPlayingAudio();
      try {
        await _audio.playAudio(response.localAudioPath);
      } catch (e) {
        // Fallback if playback fails, keep going
      }

      // Add to conversation history
      final currentSpeaker = _ref.read(activeSpeakerProvider);
      final speakerName = currentSpeaker == Speaker.you ? 'You' : 'Receiver';

      await _ref.read(conversationMessagesProvider.notifier).addMessage(
            speakerName: speakerName,
            sourceLanguage: direction.source.code,
            targetLanguage: direction.target.code,
            sourceText: response.sourceText,
            translatedText: response.translatedText,
            audioPath: response.localAudioPath,
          );

      state = TranslationSuccess(
        sourceText: response.sourceText,
        translatedText: response.translatedText,
        audioPath: response.localAudioPath,
      );

      // Centrally swap the active speaker for the next turn
      _swapActiveSpeaker();

    } catch (e) {
      _stateTimer?.cancel();
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('SocketException') || errorMsg.contains('TimeoutException')) {
        errorMsg = 'Backend server is unavailable. Please check connection and try again.';
      }
      state = TranslationError(errorMsg);
    }
  }

  void _startProcessingAnimations() {
    _stateTimer?.cancel();
    int stage = 0;

    _stateTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (state is TranslationSuccess || state is TranslationError) {
        timer.cancel();
        return;
      }

      stage++;
      if (stage == 1) {
        state = const TranslationTranscribing();
      } else if (stage == 2) {
        state = const TranslationTranslating();
      } else if (stage >= 3) {
        state = const TranslationGeneratingSpeech();
        timer.cancel();
      }
    });
  }

  void _swapActiveSpeaker() {
    final current = _ref.read(activeSpeakerProvider);
    _ref.read(activeSpeakerProvider.notifier).state =
        current == Speaker.you ? Speaker.receiver : Speaker.you;
  }

  Future<void> replayAudio(String? path) async {
    if (path == null) return;
    try {
      await _audio.playAudio(path);
    } catch (e) {
      // Handle playback error
    }
  }

  void reset() {
    _stateTimer?.cancel();
    _isRecording = false;
    _pendingStop = false;
    state = const TranslationInitial();
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    super.dispose();
  }
}

final translationNotifierProvider = StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  final api = ref.watch(apiServiceProvider);
  final audio = ref.watch(audioHelperProvider);
  return TranslationNotifier(api, audio, ref);
});

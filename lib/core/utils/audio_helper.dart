import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioHelper {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  AudioHelper() {
    // Listen to playback state changes if needed
  }

  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) return true;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> hasMicrophonePermission() async {
    if (kIsWeb) return true;
    return await Permission.microphone.isGranted;
  }

  Future<bool> isPermanentlyDenied() async {
    if (kIsWeb) return false;
    return await Permission.microphone.isPermanentlyDenied;
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<String?> startRecording() async {
    try {
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        throw Exception('Microphone permission not granted');
      }

      // Ensure player is stopped
      if (_player.playing) {
        await _player.stop();
      }

      if (kIsWeb) {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.opus,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: '',
        );
        return 'web_audio';
      } else {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );

        return path;
      }
    } catch (e) {
      // Log or handle error
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path;
    } catch (e) {
      return null;
    }
  }

  Future<void> playAudio(String path) async {
    try {
      if (_player.playing) {
        await _player.stop();
      }

      // Check if file is local or remote url
      if (path.startsWith('http://') || path.startsWith('https://')) {
        await _player.setUrl(path);
      } else {
        final file = File(path);
        if (!await file.exists()) {
          throw Exception('File does not exist: $path');
        }
        await _player.setFilePath(path);
      }
      await _player.play();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopPlayback() async {
    if (_player.playing) {
      await _player.stop();
    }
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}

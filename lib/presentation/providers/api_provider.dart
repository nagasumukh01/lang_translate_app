import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

final apiBaseUrlProvider = StateProvider<String>((ref) {
  // Default to the current PC local IP for seamless Wi-Fi hotspot testing
  return 'http://172.20.10.5:8000';
});

class VoiceTranslateResponse {
  final String sourceText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final String localAudioPath;

  VoiceTranslateResponse({
    required this.sourceText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.localAudioPath,
  });
}

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> translateText({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'source_language': sourceLang,
        'target_language': targetLang,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to translate text: ${response.body}');
    }
  }

  Future<VoiceTranslateResponse> translateVoice({
    required String audioPath,
    required String sourceLang,
    required String targetLang,
  }) async {
    final uri = Uri.parse('$baseUrl/api/voice/translate');
    final request = http.MultipartRequest('POST', uri);

    request.fields['source_language'] = sourceLang;
    request.fields['target_language'] = targetLang;

    if (kIsWeb) {
      final response = await http.get(Uri.parse(audioPath));
      final fileBytes = response.bodyBytes;
      final file = http.MultipartFile.fromBytes(
        'audio',
        fileBytes,
        filename: 'recorded_audio.webm',
      );
      request.files.add(file);
    } else {
      final file = await http.MultipartFile.fromPath('audio', audioPath);
      request.files.add(file);
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final sourceText = data['source_text'] as String;
      final translatedText = data['translated_text'] as String;
      final returnedSourceLang = data['source_language'] as String;
      final returnedTargetLang = data['target_language'] as String;
      final audioUrl = data['audio_url'] as String;

      // Ensure audio URL is absolute
      String fullAudioUrl = audioUrl;
      if (!audioUrl.startsWith('http')) {
        fullAudioUrl = '$baseUrl$audioUrl';
      }

      if (kIsWeb) {
        return VoiceTranslateResponse(
          sourceText: sourceText,
          translatedText: translatedText,
          sourceLanguage: returnedSourceLang,
          targetLanguage: returnedTargetLang,
          localAudioPath: fullAudioUrl,
        );
      } else {
        // Download the translated audio file to local temporary storage immediately
        // to avoid playback issues and respect local caching.
        final audioResponse = await http.get(Uri.parse(fullAudioUrl));
        if (audioResponse.statusCode != 200) {
          throw Exception('Failed to download translated audio');
        }

        final tempDir = await getTemporaryDirectory();
        final localPath = '${tempDir.path}/translated_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final localFile = File(localPath);
        await localFile.writeAsBytes(audioResponse.bodyBytes);

        return VoiceTranslateResponse(
          sourceText: sourceText,
          translatedText: translatedText,
          sourceLanguage: returnedSourceLang,
          targetLanguage: returnedTargetLang,
          localAudioPath: localPath,
        );
      }
    } else {
      final errorMsg = jsonDecode(response.body)['detail'] ?? 'Voice translation failed';
      throw Exception(errorMsg);
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return ApiService(baseUrl);
});

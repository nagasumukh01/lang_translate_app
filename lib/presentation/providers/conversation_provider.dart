import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/languages.dart';
import '../../domain/entities/conversation_message.dart';
import 'language_providers.dart';

enum Speaker {
  you,
  receiver,
}

final activeSpeakerProvider = StateProvider<Speaker>((ref) {
  return Speaker.you;
});

class ActiveDirection {
  final AppLanguage source;
  final AppLanguage target;
  ActiveDirection({required this.source, required this.target});
}

final activeDirectionProvider = Provider<ActiveDirection>((ref) {
  final speaker = ref.watch(activeSpeakerProvider);
  final langA = ref.watch(sourceLanguageProvider);
  final langB = ref.watch(targetLanguageProvider);

  if (speaker == Speaker.you) {
    return ActiveDirection(source: langA, target: langB);
  } else {
    return ActiveDirection(source: langB, target: langA);
  }
});

class ConversationMessagesNotifier extends StateNotifier<List<ConversationMessage>> {
  final Box _box;

  ConversationMessagesNotifier(this._box) : super([]) {
    _loadMessages();
  }

  void _loadMessages() {
    final list = _box.get('messages', defaultValue: []);
    state = list.map((item) => ConversationMessage.fromMap(Map<dynamic, dynamic>.from(item))).toList().cast<ConversationMessage>();
  }

  Future<void> addMessage({
    required String speakerName,
    required String sourceLanguage,
    required String targetLanguage,
    required String sourceText,
    required String translatedText,
    String? audioPath,
  }) async {
    final newMessage = ConversationMessage(
      id: const Uuid().v4(),
      speaker: speakerName,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      sourceText: sourceText,
      translatedText: translatedText,
      timestamp: DateTime.now(),
      audioPath: audioPath,
    );

    state = [...state, newMessage];
    await _saveToHive();
  }

  Future<void> clearHistory() async {
    state = [];
    await _box.delete('messages');
  }

  Future<void> _saveToHive() async {
    final maps = state.map((msg) => msg.toMap()).toList();
    await _box.put('messages', maps);
  }
}

// Will be overridden in main.dart
final conversationMessagesProvider = StateNotifierProvider<ConversationMessagesNotifier, List<ConversationMessage>>((ref) {
  throw UnimplementedError('box must be initialized');
});

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhashabridge/core/constants/languages.dart';
import 'package:bhashabridge/presentation/providers/language_providers.dart';
import 'package:bhashabridge/presentation/providers/conversation_provider.dart';
import 'package:bhashabridge/domain/entities/conversation_message.dart';

void main() {
  group('Language Configuration and Providers Tests', () {
    test('Initial languages should default to English and Kannada', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final source = container.read(sourceLanguageProvider);
      final target = container.read(targetLanguageProvider);

      expect(source.code, 'en');
      expect(target.code, 'kn');
    });

    test('Swapping languages should correctly invert source and target', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialSource = container.read(sourceLanguageProvider);
      final initialTarget = container.read(targetLanguageProvider);

      // Perform swap
      container.read(sourceLanguageProvider.notifier).state = initialTarget;
      container.read(targetLanguageProvider.notifier).state = initialSource;

      expect(container.read(sourceLanguageProvider).code, 'kn');
      expect(container.read(targetLanguageProvider).code, 'en');
    });
  });

  group('Conversation Direction Reversal Logic Tests', () {
    test('Should reverse source and target based on active speaker', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When speaker is YOU, source is en, target is kn
      final directionBefore = container.read(activeDirectionProvider);
      expect(directionBefore.source.code, 'en');
      expect(directionBefore.target.code, 'kn');

      // Swap speaker to Receiver
      container.read(activeSpeakerProvider.notifier).state = Speaker.receiver;

      // Now source should be kn, target should be en
      final directionAfter = container.read(activeDirectionProvider);
      expect(directionAfter.source.code, 'kn');
      expect(directionAfter.target.code, 'en');
    });
  });

  group('Conversation Message Entity Tests', () {
    test('toMap and fromMap serialization should work correctly', () {
      final date = DateTime.now();
      final msg = ConversationMessage(
        id: '123',
        speaker: 'You',
        sourceLanguage: 'en',
        targetLanguage: 'kn',
        sourceText: 'Hello',
        translatedText: 'ನಮಸ್ಕಾರ',
        timestamp: date,
        audioPath: 'temp/audio.mp3',
      );

      final map = msg.toMap();
      final decoded = ConversationMessage.fromMap(map);

      expect(decoded.id, '123');
      expect(decoded.speaker, 'You');
      expect(decoded.sourceLanguage, 'en');
      expect(decoded.targetLanguage, 'kn');
      expect(decoded.sourceText, 'Hello');
      expect(decoded.translatedText, 'ನಮಸ್ಕಾರ');
      expect(decoded.audioPath, 'temp/audio.mp3');
      expect(decoded.timestamp.toIso8601String(), date.toIso8601String());
    });
  });
}

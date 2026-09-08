import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/standalone_translation_service.dart';

/// Provider for the standalone translation service.
/// No backend server needed — everything runs on-device + Google Translate.
final translationServiceProvider = Provider<StandaloneTranslationService>((ref) {
  final service = StandaloneTranslationService();
  ref.onDispose(() => service.dispose());
  return service;
});

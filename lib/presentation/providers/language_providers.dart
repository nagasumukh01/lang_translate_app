import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/languages.dart';

final sourceLanguageProvider = StateProvider<AppLanguage>((ref) {
  // Default to English
  return supportedLanguages.firstWhere((lang) => lang.code == 'en');
});

final targetLanguageProvider = StateProvider<AppLanguage>((ref) {
  // Default to Kannada
  return supportedLanguages.firstWhere((lang) => lang.code == 'kn');
});

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'nativeName': nativeName,
      'flag': flag,
    };
  }

  factory AppLanguage.fromMap(Map<dynamic, dynamic> map) {
    return AppLanguage(
      code: map['code'] as String,
      name: map['name'] as String,
      nativeName: map['nativeName'] as String,
      flag: map['flag'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLanguage &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

const List<AppLanguage> supportedLanguages = [
  AppLanguage(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
  ),
  AppLanguage(
    code: 'kn',
    name: 'Kannada',
    nativeName: 'ಕನ್ನಡ',
    flag: '🇮🇳',
  ),
  AppLanguage(
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिन्दी',
    flag: '🇮🇳',
  ),
  AppLanguage(
    code: 'te',
    name: 'Telugu',
    nativeName: 'తెలుగు',
    flag: '🇮🇳',
  ),
  AppLanguage(
    code: 'ta',
    name: 'Tamil',
    nativeName: 'தமிழ்',
    flag: '🇮🇳',
  ),
  AppLanguage(
    code: 'ml',
    name: 'Malayalam',
    nativeName: 'മലയാളം',
    flag: '🇮🇳',
  ),
  AppLanguage(
    code: 'mr',
    name: 'Marathi',
    nativeName: 'मराठी',
    flag: '🇮🇳',
  ),
  AppLanguage(
    code: 'gu',
    name: 'Gujarati',
    nativeName: 'ગુજરાતી',
    flag: '🇮🇳',
  ),
  AppLanguage(
    code: 'bn',
    name: 'Bengali',
    nativeName: 'বাংলা',
    flag: '🇮🇳',
  ),
  AppLanguage(
    code: 'ur',
    name: 'Urdu',
    nativeName: 'اردو',
    flag: '🇵🇰',
  ),
  AppLanguage(
    code: 'ja',
    name: 'Japanese',
    nativeName: '日本語',
    flag: '🇯🇵',
  ),
  AppLanguage(
    code: 'es',
    name: 'Spanish',
    nativeName: 'Español',
    flag: '🇪🇸',
  ),
  AppLanguage(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
    flag: '🇫🇷',
  ),
  AppLanguage(
    code: 'de',
    name: 'German',
    nativeName: 'Deutsch',
    flag: '🇩🇪',
  ),
  AppLanguage(
    code: 'ko',
    name: 'Korean',
    nativeName: '한국어',
    flag: '🇰🇷',
  ),
  AppLanguage(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
    flag: '🇸🇦',
  ),
  AppLanguage(
    code: 'zh',
    name: 'Chinese',
    nativeName: '中文',
    flag: '🇨🇳',
  ),
];

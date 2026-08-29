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
    code: 'ja',
    name: 'Japanese',
    nativeName: '日本語',
    flag: '🇯🇵',
  ),
];

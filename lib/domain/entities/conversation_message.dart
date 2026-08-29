class ConversationMessage {
  final String id;
  final String speaker; // 'You' or 'Receiver'
  final String sourceLanguage;
  final String targetLanguage;
  final String sourceText;
  final String translatedText;
  final DateTime timestamp;
  final String? audioPath;

  const ConversationMessage({
    required this.id,
    required this.speaker,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.sourceText,
    required this.translatedText,
    required this.timestamp,
    this.audioPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'speaker': speaker,
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'sourceText': sourceText,
      'translatedText': translatedText,
      'timestamp': timestamp.toIso8601String(),
      'audioPath': audioPath,
    };
  }

  factory ConversationMessage.fromMap(Map<dynamic, dynamic> map) {
    return ConversationMessage(
      id: map['id'] as String,
      speaker: map['speaker'] as String,
      sourceLanguage: map['sourceLanguage'] as String,
      targetLanguage: map['targetLanguage'] as String,
      sourceText: map['sourceText'] as String,
      translatedText: map['translatedText'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      audioPath: map['audioPath'] as String?,
    );
  }
}

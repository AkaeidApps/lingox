import 'language_model.dart';

class TranslationModel {
  final String? id;
  final String sourceText;
  final String translatedText;
  final LanguageModel sourceLanguage;
  final LanguageModel targetLanguage;
  final DateTime timestamp;
  final bool isFavorite;

  const TranslationModel({
    this.id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.timestamp,
    this.isFavorite = false,
  });

  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    return TranslationModel(
      id: json['id'] as String?,
      sourceText: json['sourceText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLanguage: LanguageModel.fromJson(
        json['sourceLanguage'] as Map<String, dynamic>,
      ),
      targetLanguage: LanguageModel.fromJson(
        json['targetLanguage'] as Map<String, dynamic>,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceText': sourceText,
      'translatedText': translatedText,
      'sourceLanguage': sourceLanguage.toJson(),
      'targetLanguage': targetLanguage.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  TranslationModel copyWith({
    String? id,
    String? sourceText,
    String? translatedText,
    LanguageModel? sourceLanguage,
    LanguageModel? targetLanguage,
    DateTime? timestamp,
    bool? isFavorite,
  }) {
    return TranslationModel(
      id: id ?? this.id,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Sample data for UI preview (Phase 1 - UI only)
class SampleTranslations {
  SampleTranslations._();

  static List<TranslationModel> get recentTranslations => [
    TranslationModel(
      id: '1',
      sourceText: 'Hello, how are you?',
      translatedText: 'Hola, ¿cómo estás?',
      sourceLanguage: const LanguageModel(
        code: 'en',
        name: 'English',
        flagEmoji: '🇬🇧',
      ),
      targetLanguage: const LanguageModel(
        code: 'es',
        name: 'Spanish',
        flagEmoji: '🇪🇸',
      ),
      timestamp: DateTime(2026, 11, 7, 10, 30),
      isFavorite: true,
    ),
    TranslationModel(
      id: '2',
      sourceText: 'Good morning',
      translatedText: 'Bonjour',
      sourceLanguage: const LanguageModel(
        code: 'en',
        name: 'English',
        flagEmoji: '🇬🇧',
      ),
      targetLanguage: const LanguageModel(
        code: 'fr',
        name: 'French',
        flagEmoji: '🇫🇷',
      ),
      timestamp: DateTime(2026, 11, 7, 9, 15),
      isFavorite: false,
    ),
    TranslationModel(
      id: '3',
      sourceText: 'Thank you very much',
      translatedText: 'Arigatou gozaimasu',
      sourceLanguage: const LanguageModel(
        code: 'en',
        name: 'English',
        flagEmoji: '🇬🇧',
      ),
      targetLanguage: const LanguageModel(
        code: 'ja',
        name: 'Japanese',
        flagEmoji: '🇯🇵',
      ),
      timestamp: DateTime(2026, 11, 6, 18, 45),
      isFavorite: true,
    ),
    TranslationModel(
      id: '4',
      sourceText: 'Where is the nearest restaurant?',
      translatedText: 'Wo ist das nächste Restaurant?',
      sourceLanguage: const LanguageModel(
        code: 'en',
        name: 'English',
        flagEmoji: '🇬🇧',
      ),
      targetLanguage: const LanguageModel(
        code: 'de',
        name: 'German',
        flagEmoji: '🇩🇪',
      ),
      timestamp: DateTime(2026, 11, 6, 14, 20),
      isFavorite: false,
    ),
    TranslationModel(
      id: '5',
      sourceText: 'I love learning new languages',
      translatedText: 'J\'aime apprendre de nouvelles langues',
      sourceLanguage: const LanguageModel(
        code: 'en',
        name: 'English',
        flagEmoji: '🇬🇧',
      ),
      targetLanguage: const LanguageModel(
        code: 'fr',
        name: 'French',
        flagEmoji: '🇫🇷',
      ),
      timestamp: DateTime(2026, 11, 5, 20, 0),
      isFavorite: false,
    ),
  ];
}

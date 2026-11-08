class LanguageModel {
  final String code;
  final String name;
  final String flagEmoji;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.flagEmoji,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) {
    return LanguageModel(
      code: json['code'] as String,
      name: json['name'] as String,
      flagEmoji: json['flagEmoji'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'name': name, 'flagEmoji': flagEmoji};
  }

  @override
  String toString() => '$name ($code)';
}

/// Sample languages for UI preview (Phase 1 - UI only)
class LanguagesRepository {
  LanguagesRepository._();

  static const List<LanguageModel> allLanguages = [
    LanguageModel(code: 'auto', name: 'Auto-detect', flagEmoji: '🔍'),
    LanguageModel(code: 'en', name: 'English', flagEmoji: '🇬🇧'),
    LanguageModel(code: 'bn', name: 'Bengali', flagEmoji: '🇧🇩'),
    LanguageModel(code: 'es', name: 'Spanish', flagEmoji: '🇪🇸'),
    LanguageModel(code: 'fr', name: 'French', flagEmoji: '🇫🇷'),
    LanguageModel(code: 'de', name: 'German', flagEmoji: '🇩🇪'),
    LanguageModel(code: 'it', name: 'Italian', flagEmoji: '🇮🇹'),
    LanguageModel(code: 'pt', name: 'Portuguese', flagEmoji: '🇵🇹'),
    LanguageModel(code: 'ru', name: 'Russian', flagEmoji: '🇷🇺'),
    LanguageModel(code: 'ja', name: 'Japanese', flagEmoji: '🇯🇵'),
    LanguageModel(code: 'ko', name: 'Korean', flagEmoji: '🇰🇷'),
    LanguageModel(code: 'zh', name: 'Chinese', flagEmoji: '🇨🇳'),
    LanguageModel(code: 'ar', name: 'Arabic', flagEmoji: '🇸🇦'),
    LanguageModel(code: 'hi', name: 'Hindi', flagEmoji: '🇮🇳'),
    LanguageModel(code: 'tr', name: 'Turkish', flagEmoji: '🇹🇷'),
    LanguageModel(code: 'nl', name: 'Dutch', flagEmoji: '🇳🇱'),
    LanguageModel(code: 'pl', name: 'Polish', flagEmoji: '🇵🇱'),
    LanguageModel(code: 'sv', name: 'Swedish', flagEmoji: '🇸🇪'),
    LanguageModel(code: 'da', name: 'Danish', flagEmoji: '🇩🇰'),
    LanguageModel(code: 'fi', name: 'Finnish', flagEmoji: '🇫🇮'),
    LanguageModel(code: 'no', name: 'Norwegian', flagEmoji: '🇳🇴'),
    LanguageModel(code: 'cs', name: 'Czech', flagEmoji: '🇨🇿'),
    LanguageModel(code: 'el', name: 'Greek', flagEmoji: '🇬🇷'),
    LanguageModel(code: 'he', name: 'Hebrew', flagEmoji: '🇮🇱'),
    LanguageModel(code: 'th', name: 'Thai', flagEmoji: '🇹🇭'),
    LanguageModel(code: 'vi', name: 'Vietnamese', flagEmoji: '🇻🇳'),
    LanguageModel(code: 'id', name: 'Indonesian', flagEmoji: '🇮🇩'),
    LanguageModel(code: 'ms', name: 'Malay', flagEmoji: '🇲🇾'),
    LanguageModel(code: 'uk', name: 'Ukrainian', flagEmoji: '🇺🇦'),
    LanguageModel(code: 'ro', name: 'Romanian', flagEmoji: '🇷🇴'),
    LanguageModel(code: 'hu', name: 'Hungarian', flagEmoji: '🇭🇺'),
  ];

  static LanguageModel getByCode(String code) {
    try {
      return allLanguages.firstWhere((lang) => lang.code == code);
    } catch (_) {
      return const LanguageModel(
        code: 'en',
        name: 'English',
        flagEmoji: '🇬🇧',
      );
    }
  }

  /// Extra search terms for languages whose common name differs from the
  /// English label shown in the picker.
  static const Map<String, List<String>> _searchAliases = {
    'bn': ['bangla', 'bengali', 'বাংলা'],
  };

  static List<LanguageModel> search(String query) {
    if (query.isEmpty) return allLanguages;
    final lower = query.toLowerCase();
    return allLanguages.where((lang) {
      final aliases = _searchAliases[lang.code] ?? const <String>[];
      return lang.name.toLowerCase().contains(lower) ||
          lang.code.contains(lower) ||
          aliases.any((alias) => alias.contains(lower));
    }).toList();
  }
}

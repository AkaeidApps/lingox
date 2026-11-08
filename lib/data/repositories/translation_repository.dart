import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/translation_service.dart';
import '../../core/network/translation_service_router.dart';
import '../../data/models/language_model.dart';
import '../../data/models/translation_model.dart';

/// Repository that bridges the translation API with the UI layer.
///
/// Handles:
/// - Translation requests via the configured engine
/// - Local history storage using SharedPreferences
/// - Favorites management
/// - Language detection
class TranslationRepository {
  final TranslationService _apiService;

  TranslationRepository({TranslationService? apiService})
    : _apiService = apiService ?? TranslationServiceRouter();

  /// Translate text and save to history
  Future<TranslationModel> translateAndSave({
    required String text,
    required LanguageModel targetLanguage,
    LanguageModel? sourceLanguage,
  }) async {
    final translatedText = await _apiService.translate(
      text: text,
      targetLanguage: targetLanguage.code,
      sourceLanguage: sourceLanguage?.code,
    );

    // Determine actual source language
    final actualSource =
        sourceLanguage ??
        const LanguageModel(code: 'auto', name: 'Auto-detect', flagEmoji: '🔍');

    final model = TranslationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceText: text,
      translatedText: translatedText,
      sourceLanguage: actualSource,
      targetLanguage: targetLanguage,
      timestamp: DateTime.now(),
    );

    // Save to history
    await addToHistory(model);

    return model;
  }

  /// Translate text without saving to history
  Future<String> translateOnly({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    return _apiService.translate(
      text: text,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
    );
  }

  /// Detect the language of given text
  Future<String> detectLanguage(String text) async {
    return _apiService.detectLanguage(text);
  }

  /// Get supported languages from the API
  Future<List<Map<String, String>>> getSupportedLanguages() async {
    return _apiService.getSupportedLanguages();
  }

  /// Check internet connectivity
  Future<bool> hasInternetConnection() async {
    return _apiService.hasInternetConnection();
  }

  // ---- Local Storage Methods ----

  static const String _historyKey = 'translation_history';
  static const String _favoritesKey = 'translation_favorites';

  /// Add a translation to history
  Future<void> addToHistory(TranslationModel translation) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    final history = historyJson
        .map((json) => TranslationModel.fromJson(jsonDecode(json)))
        .toList();

    // Add to beginning
    history.insert(0, translation);

    // Keep only last 100 entries
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }

    await prefs.setStringList(
      _historyKey,
      history.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  /// Get translation history
  Future<List<TranslationModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];

    try {
      return historyJson
          .map((json) => TranslationModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Search history by query
  Future<List<TranslationModel>> searchHistory(String query) async {
    final history = await getHistory();
    if (query.isEmpty) return history;

    final lower = query.toLowerCase();
    return history.where((t) {
      return t.sourceText.toLowerCase().contains(lower) ||
          t.translatedText.toLowerCase().contains(lower);
    }).toList();
  }

  /// Delete a translation from history
  Future<void> deleteFromHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.removeWhere((t) => t.id == id);
    await prefs.setStringList(
      _historyKey,
      history.map((t) => jsonEncode(t.toJson())).toList(),
    );
  }

  /// Clear all history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(TranslationModel translation) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    final favorites = favoritesJson
        .map((json) => TranslationModel.fromJson(jsonDecode(json)))
        .toList();

    final exists = favorites.any((f) => f.id == translation.id);
    if (exists) {
      favorites.removeWhere((f) => f.id == translation.id);
    } else {
      final withFavorite = translation.copyWith(isFavorite: true);
      favorites.insert(0, withFavorite);
    }

    await prefs.setStringList(
      _favoritesKey,
      favorites.map((f) => jsonEncode(f.toJson())).toList(),
    );
  }

  /// Get favorites
  Future<List<TranslationModel>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];

    try {
      return favoritesJson
          .map((json) => TranslationModel.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Search favorites by query
  Future<List<TranslationModel>> searchFavorites(String query) async {
    final favorites = await getFavorites();
    if (query.isEmpty) return favorites;

    final lower = query.toLowerCase();
    return favorites.where((t) {
      return t.sourceText.toLowerCase().contains(lower) ||
          t.translatedText.toLowerCase().contains(lower);
    }).toList();
  }

  /// Remove from favorites
  Future<void> removeFromFavorites(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    favorites.removeWhere((f) => f.id == id);
    await prefs.setStringList(
      _favoritesKey,
      favorites.map((f) => jsonEncode(f.toJson())).toList(),
    );
  }

  /// Check if a translation is favorited
  Future<bool> isFavorite(String id) async {
    final favorites = await getFavorites();
    return favorites.any((f) => f.id == id);
  }
}

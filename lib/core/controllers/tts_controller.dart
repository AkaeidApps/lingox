import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../errors/tts_exceptions.dart';
import '../services/text_to_speech_service.dart';

/// Controller for Text-to-Speech functionality.
///
/// Handles synthesizing text to speech and playing the resulting audio.
class TtsController extends GetxController {
  final TextToSpeechService _ttsService = Get.find<TextToSpeechService>();
  final AudioPlayer _player = AudioPlayer();

  final RxBool isSpeaking = false.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _player.onPlayerComplete.listen((_) {
      isSpeaking.value = false;
    });
  }

  @override
  void onClose() {
    _player.stop();
    _player.release();
    super.onClose();
  }

  /// Speak the given text in the specified language.
  ///
  /// [text] - The text to speak
  /// [languageCode] - The language code (e.g. 'en', 'es')
  Future<void> speak({
    required String text,
    required String languageCode,
  }) async {
    if (text.trim().isEmpty) return;

    // Stop any current playback
    await _player.stop();

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Convert language code to TTS format
      final ttsLangCode = TextToSpeechService.toTtsLanguageCode(languageCode);

      // Synthesize speech
      final audioPath = await _ttsService.synthesize(
        text: text,
        languageCode: ttsLangCode,
      );

      // Play the audio
      await _player.play(DeviceFileSource(audioPath));
      isSpeaking.value = true;
      isLoading.value = false;
    } on TtsApiKeyException {
      errorMessage.value = 'TTS API key not configured.';
      isLoading.value = false;
      Get.snackbar(
        'Configuration Required',
        'Please set your Google Cloud Text-to-Speech API key.\n'
            'Run with: --dart-define=GOOGLE_TTS_API_KEY=YOUR_KEY',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE91E63),
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } on TtsNetworkException {
      errorMessage.value = 'No internet connection.';
      isLoading.value = false;
      Get.snackbar(
        'Network Error',
        'Check your internet connection and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE91E63),
        colorText: Colors.white,
      );
    } on TtsTimeoutException {
      errorMessage.value = 'TTS request timed out.';
      isLoading.value = false;
      Get.snackbar(
        'Timeout',
        'TTS request timed out. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE91E63),
        colorText: Colors.white,
      );
    } on TtsVoiceNotFoundException {
      errorMessage.value = 'No voice found for $languageCode.';
      isLoading.value = false;
      Get.snackbar(
        'Voice Not Found',
        'No voice available for the selected language.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE91E63),
        colorText: Colors.white,
      );
    } on TtsQuotaExceededException {
      errorMessage.value = 'TTS quota exceeded.';
      isLoading.value = false;
      Get.snackbar(
        'Quota Exceeded',
        'TTS API quota exceeded. Please try again later.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE91E63),
        colorText: Colors.white,
      );
    } on TtsException catch (e) {
      errorMessage.value = e.message;
      isLoading.value = false;
      Get.snackbar(
        'TTS Error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE91E63),
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = 'TTS failed: $e';
      isLoading.value = false;
      Get.snackbar(
        'TTS Error',
        'Failed to synthesize speech. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE91E63),
        colorText: Colors.white,
      );
    }
  }

  /// Stop the current playback.
  Future<void> stop() async {
    await _player.stop();
    isSpeaking.value = false;
  }

  /// Pause the current playback.
  Future<void> pause() async {
    await _player.pause();
    isSpeaking.value = false;
  }

  /// Resume the current playback.
  Future<void> resume() async {
    await _player.resume();
    isSpeaking.value = true;
  }
}

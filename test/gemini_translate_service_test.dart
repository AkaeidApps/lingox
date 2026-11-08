import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingox/core/errors/translation_exceptions.dart';
import 'package:lingox/core/network/gemini_translate_service.dart';

const _jsonHeaders = {
  'content-type': ['application/json; charset=utf-8'],
};

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options, Stream<Uint8List>? body)
  handler;

  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: _jsonHeaders,
  );
}

ResponseBody _translationResponse(String text) {
  return _jsonResponse({
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': text},
          ],
        },
        'finishReason': 'STOP',
      },
    ],
  });
}

GeminiTranslateService _serviceWith(_FakeAdapter adapter, {String? model}) {
  return GeminiTranslateService(
    dio: Dio(BaseOptions(baseUrl: 'https://example.test/v1beta'))
      ..httpClientAdapter = adapter,
    apiKey: 'test-key',
    model: model ?? 'gemini-3.1-flash-lite',
    connectivityCheck: () async => true,
  );
}

void main() {
  group('GeminiTranslateService', () {
    test('translates using generateContent', () async {
      final adapter = _FakeAdapter(
        (options, body) => _translationResponse('Hola mundo'),
      );
      final service = _serviceWith(adapter);

      final result = await service.translate(
        text: 'Hello world',
        sourceLanguage: 'en',
        targetLanguage: 'es',
      );

      expect(result, 'Hola mundo');
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(
        request.uri.path,
        '/v1beta/models/gemini-3.1-flash-lite:generateContent',
      );
      expect(request.uri.queryParameters['key'], 'test-key');

      final data = request.data as Map<String, dynamic>;
      final prompt =
          ((data['contents'] as List).first as Map)['parts'][0]['text']
              as String;
      expect(prompt, contains('Hello world'));
      expect(prompt, contains('Spanish'));

      final generationConfig = data['generationConfig'] as Map;
      expect(generationConfig['thinkingConfig'], {'thinkingBudget': 0});
    });

    test('falls back to the next model when one is unavailable', () async {
      final adapter = _FakeAdapter((options, body) {
        if (options.uri.path.contains('gemini-3.1-flash-lite')) {
          return _jsonResponse({
            'error': {'code': 404, 'message': 'not available'},
          }, statusCode: 404);
        }
        return _translationResponse('Hola mundo');
      });
      final service = _serviceWith(adapter);

      final result = await service.translate(
        text: 'Hello',
        targetLanguage: 'es',
      );

      expect(result, 'Hola mundo');
      expect(adapter.requests, hasLength(2));
      expect(
        adapter.requests.last.uri.path,
        contains('gemini-3-flash-preview'),
      );
    });

    test('detects a language code', () async {
      final adapter = _FakeAdapter(
        (options, body) => _translationResponse('bn'),
      );
      final service = _serviceWith(adapter);

      expect(await service.detectLanguage('আমি ভালো আছি'), 'bn');
    });

    test('maps an invalid key to ApiKeyException', () async {
      final adapter = _FakeAdapter(
        (options, body) => _jsonResponse({
          'error': {
            'code': 400,
            'message': 'API key not valid. Please pass a valid API key.',
            'status': 'INVALID_ARGUMENT',
          },
        }, statusCode: 400),
      );
      final service = _serviceWith(adapter);

      await expectLater(
        service.translate(text: 'Hello', targetLanguage: 'es'),
        throwsA(isA<ApiKeyException>()),
      );
    });

    test('maps quota errors to QuotaExceededException', () async {
      final adapter = _FakeAdapter(
        (options, body) => _jsonResponse({
          'error': {
            'code': 429,
            'message': 'Resource exhausted',
            'status': 'RESOURCE_EXHAUSTED',
          },
        }, statusCode: 429),
      );
      final service = _serviceWith(adapter);

      await expectLater(
        service.translate(text: 'Hello', targetLanguage: 'es'),
        throwsA(isA<QuotaExceededException>()),
      );
    });

    test('throws ApiKeyException when no key is configured', () async {
      final adapter = _FakeAdapter(
        (options, body) => _translationResponse('Hola'),
      );
      final service = GeminiTranslateService(
        dio: Dio(BaseOptions(baseUrl: 'https://example.test/v1beta'))
          ..httpClientAdapter = adapter,
        apiKey: '',
        connectivityCheck: () async => true,
      );

      await expectLater(
        service.translate(text: 'Hello', targetLanguage: 'es'),
        throwsA(isA<ApiKeyException>()),
      );
      expect(adapter.requests, isEmpty);
    });
  });
}

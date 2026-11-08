import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingox/core/errors/translation_exceptions.dart';
import 'package:lingox/core/network/google_translate_service.dart';

const _jsonHeaders = {
  'content-type': ['application/json; charset=utf-8'],
};

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options, Stream<Uint8List>? body)
  handler;

  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return handler(options, requestStream);
  }

  @override
  void close({bool force = false}) {}
}

GoogleTranslateService _serviceWith(FakeHttpHandler handler) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://translation.googleapis.com/language/translate/v2',
    ),
  )..httpClientAdapter = _FakeAdapter(handler);

  return GoogleTranslateService(
    dio: dio,
    apiKey: 'test-key',
    connectivityCheck: () async => true,
  );
}

typedef FakeHttpHandler = ResponseBody Function(
  RequestOptions options,
  Stream<Uint8List>? body,
);

ResponseBody _jsonResponse(Object body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: _jsonHeaders,
  );
}

void main() {
  group('GoogleTranslateService', () {
    test('translates text with a Google v2 POST request', () async {
      late _FakeAdapter adapter;
      final service = GoogleTranslateService(
        dio:
            Dio(
                BaseOptions(
                  baseUrl: 'https://translation.googleapis.com/language/translate/v2',
                ),
              )
              ..httpClientAdapter = adapter = _FakeAdapter(
                (options, body) => _jsonResponse({
                  'data': {
                    'translations': [
                      {
                        'translatedText': 'Hola mundo',
                        'detectedSourceLanguage': 'en',
                      },
                    ],
                  },
                }),
              ),
        apiKey: 'test-key',
        connectivityCheck: () async => true,
      );

      final result = await service.translate(
        text: 'Hello world',
        targetLanguage: 'es',
      );

      expect(result, 'Hola mundo');
      expect(adapter.lastOptions!.method, 'POST');
      expect(
        adapter.lastOptions!.uri.toString(),
        startsWith(
          'https://translation.googleapis.com/language/translate/v2'
          '?key=test-key',
        ),
      );
      final data = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(data['q'], 'Hello world');
      expect(data['target'], 'es');
      expect(data['format'], 'text');
      expect(data.containsKey('source'), isFalse);
    });

    test('passes an explicit source language', () async {
      late _FakeAdapter adapter;
      final service = GoogleTranslateService(
        dio:
            Dio(
                BaseOptions(
                  baseUrl: 'https://translation.googleapis.com/language/translate/v2',
                ),
              )
              ..httpClientAdapter = adapter = _FakeAdapter(
                (options, body) => _jsonResponse({
                  'data': {
                    'translations': [
                      {'translatedText': 'नमस्ते'},
                    ],
                  },
                }),
              ),
        apiKey: 'test-key',
        connectivityCheck: () async => true,
      );

      await service.translate(
        text: 'Hello',
        sourceLanguage: 'en',
        targetLanguage: 'hi',
      );

      final data = adapter.lastOptions!.data as Map<String, dynamic>;
      expect(data['source'], 'en');
      expect(data['target'], 'hi');
    });

    test('detects language from a /detect response', () async {
      late _FakeAdapter adapter;
      final service = GoogleTranslateService(
        dio:
            Dio(
                BaseOptions(
                  baseUrl: 'https://translation.googleapis.com/language/translate/v2',
                ),
              )
              ..httpClientAdapter = adapter = _FakeAdapter(
                (options, body) => _jsonResponse({
                  'data': {
                    'detections': [
                      [
                        {'language': 'bn', 'confidence': 0.98},
                      ],
                    ],
                  },
                }),
              ),
        apiKey: 'test-key',
        connectivityCheck: () async => true,
      );

      final language = await service.detectLanguage('আমি ভালো আছি');

      expect(language, 'bn');
      expect(adapter.lastOptions!.uri.path, '/language/translate/v2/detect');
    });

    test('fetches supported languages', () async {
      final service = _serviceWith(
        (options, body) => _jsonResponse({
          'data': {
            'languages': [
              {'language': 'en', 'name': 'English'},
              {'language': 'es', 'name': 'Spanish'},
            ],
          },
        }),
      );

      final languages = await service.getSupportedLanguages();

      expect(languages, hasLength(2));
      expect(languages.first['language'], 'en');
      expect(languages.last['name'], 'Spanish');
    });

    test('maps an invalid API key to ApiKeyException', () async {
      final service = _serviceWith(
        (options, body) => _jsonResponse({
          'error': {
            'code': 400,
            'message': 'API key not valid. Please pass a valid API key.',
            'status': 'INVALID_ARGUMENT',
            'details': [
              {
                '@type': 'type.googleapis.com/google.rpc.ErrorInfo',
                'reason': 'API_KEY_INVALID',
              },
            ],
          },
        }, statusCode: 400),
      );

      await expectLater(
        service.translate(text: 'Hello', targetLanguage: 'es'),
        throwsA(isA<ApiKeyException>()),
      );
    });

    test('maps quota errors to QuotaExceededException', () async {
      final service = _serviceWith(
        (options, body) => _jsonResponse({
          'error': {
            'code': 429,
            'message': 'Quota exceeded for quota metric.',
            'status': 'RESOURCE_EXHAUSTED',
          },
        }, statusCode: 429),
      );

      await expectLater(
        service.translate(text: 'Hello', targetLanguage: 'es'),
        throwsA(isA<QuotaExceededException>()),
      );
    });

    test('throws ApiKeyException when no key is configured', () async {
      final dio =
          Dio(
              BaseOptions(
                baseUrl:
                    'https://translation.googleapis.com/language/translate/v2',
              ),
            )
            ..httpClientAdapter = _FakeAdapter(
              (options, body) => _jsonResponse({'unexpected': true}),
            );

      final service = GoogleTranslateService(
        dio: dio,
        apiKey: '',
        connectivityCheck: () async => true,
      );

      await expectLater(
        service.translate(text: 'Hello', targetLanguage: 'es'),
        throwsA(isA<ApiKeyException>()),
      );
    });

    test('rejects empty input before making a request', () async {
      final service = _serviceWith(
        (options, body) => _jsonResponse({
          'data': {'translations': []},
        }),
      );

      await expectLater(
        service.translate(text: '   ', targetLanguage: 'es'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

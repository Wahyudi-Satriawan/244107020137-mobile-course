import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../07-week-7-clean-architecture/campus_notify/lib/ai/ai_service.dart';
import '../07-week-7-clean-architecture/campus_notify/lib/features/ai_chat/presentation/providers/chat_providers.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> storage = {};

  FakeSecureStorage([Map<String, String>? initial]) {
    if (initial != null) {
      storage.addAll(initial);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return storage[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      storage[key] = value;
    } else {
      storage.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    storage.remove(key);
  }
}

class MockHttpClient extends http.BaseClient {
  final Future<http.StreamedResponse> Function(http.BaseRequest request)
      _handler;

  MockHttpClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

void main() {
  group('AiService Unit Tests', () {
    test('Gagal jika API Key belum tersedia di storage', () async {
      final fakeStorage = FakeSecureStorage();
      final mockClient = MockHttpClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('{}')),
          200,
        );
      });

      final service = AiService(
        storage: fakeStorage,
        client: mockClient,
      );

      expect(
        () => service.ask('Jadwal kuliah?'),
        throwsA(
          isA<AiServiceException>().having(
            (e) => e.message,
            'message',
            contains('API Key tidak tersedia'),
          ),
        ),
      );
    });

    test('Gagal jika pertanyaan kosong', () async {
      final fakeStorage = FakeSecureStorage({'ai_api_key': 'dummy_key'});
      final service = AiService(storage: fakeStorage);

      expect(
        () => service.ask('   '),
        throwsA(
          isA<AiServiceException>().having(
            (e) => e.message,
            'message',
            contains('Pertanyaan tidak boleh kosong'),
          ),
        ),
      );
    });

    test('Sukses parsing respon Gemini saat status 200', () async {
      final fakeStorage = FakeSecureStorage({'ai_api_key': 'test-gemini-key'});
      final mockResponseBody = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text':
                      'Perkuliahan hari ini dimulai pukul 08.00 WIB di Gedung Sipil. Tetap semangat!'
                }
              ]
            }
          }
        ]
      });

      final mockClient = MockHttpClient((request) async {
        expect(request.url.queryParameters['key'], equals('test-gemini-key'));
        return http.StreamedResponse(
          Stream.value(utf8.encode(mockResponseBody)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(
        storage: fakeStorage,
        client: mockClient,
      );

      final reply = await service.ask('Jadwal kuliah hari ini?');
      expect(
        reply,
        equals(
          'Perkuliahan hari ini dimulai pukul 08.00 WIB di Gedung Sipil. Tetap semangat!',
        ),
      );
    });

    test(
        'Melempar AiServiceException spesifik jika API mengembalikan status error (e.g. 500)',
        () async {
      final fakeStorage = FakeSecureStorage({'ai_api_key': 'test-gemini-key'});
      final errorJson = jsonEncode({
        'error': {
          'code': 503,
          'message': 'Model is overloaded. Please try again later.',
        }
      });

      final mockClient = MockHttpClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(errorJson)),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiService(
        storage: fakeStorage,
        client: mockClient,
      );

      expect(
        () => service.ask('Halo asisten'),
        throwsA(
          isA<AiServiceException>().having(
            (e) => e.message,
            'message',
            contains('Model is overloaded'),
          ),
        ),
      );
    });

    test(
        'Melempar AiServiceException jika terjadi kegagalan jaringan (offline)',
        () async {
      final fakeStorage = FakeSecureStorage({'ai_api_key': 'test-gemini-key'});
      final mockClient = MockHttpClient((request) async {
        throw http.ClientException('Failed to connect to host');
      });

      final service = AiService(
        storage: fakeStorage,
        client: mockClient,
      );

      expect(
        () => service.ask('Halo asisten'),
        throwsA(
          isA<AiServiceException>().having(
            (e) => e.message,
            'message',
            contains('Koneksi gagal atau offline'),
          ),
        ),
      );
    });

    test('Simpan dan baca API Key di Secure Storage berjalan dengan baik',
        () async {
      final fakeStorage = FakeSecureStorage();
      final service = AiService(storage: fakeStorage);

      await service.saveApiKey('my-secret-gemini-token');
      final savedKey = await service.getApiKey();
      expect(savedKey, equals('my-secret-gemini-token'));
    });
  });

  group('ChatNotifier & Fallback Logic Tests', () {
    test('Mengirim pesan sukses memperbarui list pesan dan status loading',
        () async {
      final fakeStorage = FakeSecureStorage({'ai_api_key': 'valid-key'});
      final mockResponse = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Ini adalah respons bantuan kampus.'}
              ]
            }
          }
        ]
      });

      final mockClient = MockHttpClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(mockResponse)),
          200,
        );
      });

      final customService = AiService(
        storage: fakeStorage,
        client: mockClient,
      );

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(customService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatNotifierProvider.notifier);
      final initial = container.read(chatNotifierProvider);
      expect(initial.messages, isEmpty);
      expect(initial.isLoading, isFalse);

      final success = await notifier.sendMessage('Info perpustakaan?');
      expect(success, isTrue);

      final updated = container.read(chatNotifierProvider);
      expect(updated.isLoading, isFalse);
      expect(updated.messages.length, equals(2));
      expect(updated.messages[0].isUser, isTrue);
      expect(updated.messages[0].text, equals('Info perpustakaan?'));
      expect(updated.messages[1].isUser, isFalse);
      expect(updated.messages[1].text,
          equals('Ini adalah respons bantuan kampus.'));
      expect(updated.errorMessage, isNull);
    });

    test(
        'Menangkap error dan mengisi errorMessage saat AI gagal merespons (Fallback)',
        () async {
      final fakeStorage = FakeSecureStorage({'ai_api_key': 'valid-key'});
      final mockClient = MockHttpClient((request) async {
        throw http.ClientException('Socket closed');
      });

      final customService = AiService(
        storage: fakeStorage,
        client: mockClient,
      );

      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(customService),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatNotifierProvider.notifier);
      final success = await notifier.sendMessage('Pertanyaan saat offline');
      expect(success, isFalse);

      final state = container.read(chatNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.messages.length, equals(1)); // Only user message
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('Koneksi gagal atau offline'));

      // Test clearError
      notifier.clearError();
      expect(container.read(chatNotifierProvider).errorMessage, isNull);
    });
  });
}

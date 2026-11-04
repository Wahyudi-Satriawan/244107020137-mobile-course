import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AiServiceException implements Exception {
  final String message;
  const AiServiceException(this.message);

  @override
  String toString() => message;
}

class AiService {
  final FlutterSecureStorage _storage;
  final http.Client _client;
  final String _apiUrl;

  static const String defaultSystemPrompt =
      'Kamu adalah asisten kampus ramah untuk aplikasi Campus Notify. '
      'Jawab singkat dalam Bahasa Indonesia, maksimal 2 kalimat. '
      'Jangan pernah meminta atau menyimpan data pribadi.';

  static const String apiKeyStorageKey = 'ai_api_key';

  AiService(
      {FlutterSecureStorage? storage, http.Client? client, String? apiUrl})
      : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client(),
        _apiUrl = apiUrl ??
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<String> ask(
    String question, {
    String systemPrompt = defaultSystemPrompt,
  }) async {
    if (question.trim().isEmpty) {
      throw const AiServiceException('Pertanyaan tidak boleh kosong.');
    }

    final apiKey = await _storage.read(key: apiKeyStorageKey);
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const AiServiceException(
        'API Key tidak tersedia. Silakan atur API Key terlebih dahulu.',
      );
    }

    final endpoint = Uri.parse('$_apiUrl?key=$apiKey');

    final requestBody = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': question},
          ],
        },
      ],
    });

    try {
      final response = await _client.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          throw const AiServiceException('Tidak ada jawaban dari AI.');
        }
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) {
          throw const AiServiceException('Format respons AI tidak valid.');
        }
        final answer = parts[0]['text'] as String?;
        if (answer == null || answer.trim().isEmpty) {
          throw const AiServiceException('Respons AI kosong.');
        }
        return answer.trim();
      } else {
        String detail = 'Status code: ${response.statusCode}';
        try {
          final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          if (errorJson.containsKey('error') &&
              errorJson['error'] is Map<String, dynamic>) {
            final errorMap = errorJson['error'] as Map<String, dynamic>;
            final errorMsg = errorMap['message'] as String?;
            if (errorMsg != null && errorMsg.isNotEmpty) {
              detail = errorMsg;
            }
          }
        } catch (_) {
          // If body is not JSON, retain default status code detail
        }
        throw AiServiceException('Gagal memanggil AI API ($detail).');
      }
    } on AiServiceException {
      rethrow;
    } on TimeoutException {
      throw const AiServiceException(
        'Waktu tunggu koneksi AI habis (Timeout).',
      );
    } catch (e) {
      throw AiServiceException('Koneksi gagal atau offline: $e');
    }
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: apiKeyStorageKey, value: key.trim());
  }

  Future<String?> getApiKey() async {
    return _storage.read(key: apiKeyStorageKey);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: apiKeyStorageKey);
  }
}

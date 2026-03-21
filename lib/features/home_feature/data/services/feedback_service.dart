import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/auth_service.dart';

class FeedbackService {
  FeedbackService({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<void> submitFeedback({
    required String userId,
    required String restaurantName,
    required String message,
  }) async {
    final normalizedUserId = _normalizeId(userId, key: 'userId');
    await _requestWithFallback(
      method: 'POST',
      path: '/api/users/${Uri.encodeComponent(normalizedUserId)}/feedback',
      body: {'restaurantName': restaurantName, 'message': message},
    );
  }

  Future<http.Response> _requestWithFallback({
    required String method,
    required String path,
    Map<String, dynamic>? body,
  }) async {
    for (final baseUrl in _authService.baseUrls) {
      try {
        final uri = _buildRequestUri(baseUrl: baseUrl, path: path);
        final request = http.Request(method, uri);
        request.headers['Content-Type'] = 'application/json; charset=utf-8';
        if (body != null) {
          final normalizedBody = _normalizeRequestBody(body);
          request.bodyBytes = utf8.encode(jsonEncode(normalizedBody));
        }
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 8),
        );
        final responseBytes = await streamedResponse.stream.toBytes();
        final responseBody = utf8.decode(responseBytes);
        final response = http.Response(
          responseBody,
          streamedResponse.statusCode,
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        if (kDebugMode) {
          debugPrint(
            'FeedbackService $method response error '
            '($baseUrl): ${response.statusCode} ${response.body}',
          );
        }
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('FeedbackService $method error ($baseUrl): $error');
        }
      }
    }

    throw AuthException(
      'Sunucuya baglanilamadi. Lutfen baglantinizi kontrol edin.',
    );
  }

  Uri _buildRequestUri({required String baseUrl, required String path}) {
    final normalizedBase = baseUrl.trim();
    if (normalizedBase.isEmpty) {
      throw ArgumentError('Base URL is empty.');
    }
    return Uri.parse(normalizedBase).resolve(path);
  }

  Map<String, dynamic> _normalizeRequestBody(Map<String, dynamic> body) {
    return body.map((key, value) => MapEntry(key, _normalizePayloadValue(value)));
  }

  dynamic _normalizePayloadValue(dynamic value) {
    if (value is String) {
      var text = value.trim();
      for (var i = 0; i < 2; i++) {
        final looksJsonString =
            (text.startsWith('"') && text.endsWith('"')) ||
            (text.startsWith('{') && text.endsWith('}')) ||
            (text.startsWith('[') && text.endsWith(']'));
        if (!looksJsonString) {
          break;
        }
        try {
          final decoded = jsonDecode(text);
          if (decoded is String) {
            text = decoded.trim();
            continue;
          }
          if (decoded is Map<String, dynamic>) {
            return decoded.map(
              (k, v) => MapEntry(k, _normalizePayloadValue(v)),
            );
          }
          if (decoded is List) {
            return decoded.map(_normalizePayloadValue).toList();
          }
          break;
        } catch (_) {
          break;
        }
      }
      return _sanitizeText(text);
    }

    if (value is Map<String, dynamic>) {
      return value.map(
        (key, nestedValue) => MapEntry(key, _normalizePayloadValue(nestedValue)),
      );
    }

    if (value is List) {
      return value.map(_normalizePayloadValue).toList();
    }

    return value;
  }

  String _sanitizeText(String input) {
    final compactWhitespace = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    return compactWhitespace.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '');
  }

  String _normalizeId(String raw, {required String key}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final data = jsonDecode(trimmed);
        if (data is Map<String, dynamic> && data[key] != null) {
          return data[key].toString().trim();
        }
      } catch (_) {}
    }
    return trimmed;
  }
}

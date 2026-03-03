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
        final request = http.Request(method, Uri.parse('$baseUrl$path'));
        request.headers['Content-Type'] = 'application/json';
        if (body != null) {
          request.body = jsonEncode(body);
        }
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 8),
        );
        final responseBody = await streamedResponse.stream.bytesToString();
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

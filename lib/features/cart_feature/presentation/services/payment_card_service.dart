import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/auth_service.dart';
import '../models/payment_saved_card.dart';

class PaymentCardService {
  PaymentCardService({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<List<PaymentSavedCard>> getCards({required String userId}) async {
    final normalizedUserId = _extractGuid(_normalizeId(userId, key: 'userId'));
    final response = await _requestWithFallback(
      method: 'GET',
      path: '/api/users/${Uri.encodeComponent(normalizedUserId)}/payment-cards',
    );
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .whereType<Map<String, dynamic>>()
        .map(PaymentSavedCard.fromJson)
        .toList();
  }

  Future<PaymentSavedCard> createCard({
    required String userId,
    required PaymentSavedCard card,
  }) async {
    final normalizedUserId = _extractGuid(_normalizeId(userId, key: 'userId'));
    final requestBody = <String, dynamic>{
      ...card.toRequestJson(),
      'createdAtUtc': DateTime.now().toUtc().toIso8601String(),
    };
    final response = await _requestWithFallback(
      method: 'POST',
      path: '/api/users/${Uri.encodeComponent(normalizedUserId)}/payment-cards',
      body: requestBody,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PaymentSavedCard.fromJson(data);
  }

  Future<PaymentSavedCard> updateCard({
    required String userId,
    required String paymentCardId,
    required PaymentSavedCard card,
  }) async {
    final normalizedUserId = _extractGuid(_normalizeId(userId, key: 'userId'));
    final normalizedCardId = _extractGuid(
      _normalizeId(paymentCardId, key: 'paymentCardId'),
    );
    final response = await _requestWithFallback(
      method: 'PUT',
      path:
          '/api/users/${Uri.encodeComponent(normalizedUserId)}/payment-cards/'
          '${Uri.encodeComponent(normalizedCardId)}',
      body: card.toRequestJson(),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PaymentSavedCard.fromJson(data);
  }

  Future<void> deleteCard({
    required String userId,
    required String paymentCardId,
  }) async {
    final normalizedUserId = _extractGuid(_normalizeId(userId, key: 'userId'));
    final normalizedCardId = _extractGuid(
      _normalizeId(paymentCardId, key: 'paymentCardId'),
    );
    await _requestWithFallback(
      method: 'DELETE',
      path:
          '/api/users/${Uri.encodeComponent(normalizedUserId)}/payment-cards/'
          '${Uri.encodeComponent(normalizedCardId)}',
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
        request.headers['Content-Type'] = 'application/json; charset=UTF-8';
        if (body != null) {
          final encodedBody = jsonEncode(body);
          if (kDebugMode) {
            debugPrint('PaymentCardService $method encoded body: $encodedBody');
          }
          request.bodyBytes = utf8.encode(encodedBody);
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
        if (kDebugMode) {
          debugPrint(
            'PaymentCardService $method response status: ${response.statusCode}',
          );
          debugPrint('PaymentCardService $method response body: ${response.body}');
        }
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        if (kDebugMode) {
          debugPrint(
            'PaymentCardService $method response error '
            '($baseUrl): ${response.statusCode} ${response.body}',
          );
        }
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('PaymentCardService $method error ($baseUrl): $error');
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

    dynamic candidate = trimmed;

    // Some call sites send IDs as deeply wrapped JSON strings.
    for (var i = 0; i < 3; i++) {
      if (candidate is String) {
        final text = candidate.trim();
        if (text.isEmpty) {
          return text;
        }

        final looksJson =
            (text.startsWith('"') && text.endsWith('"')) ||
            (text.startsWith('{') && text.endsWith('}')) ||
            (text.startsWith('[') && text.endsWith(']'));
        if (!looksJson) {
          candidate = text;
          break;
        }

        try {
          candidate = jsonDecode(text);
          continue;
        } catch (_) {
          candidate = text;
          break;
        }
      }

      if (candidate is Map<String, dynamic>) {
        final value = candidate[key];
        if (value != null) {
          return value.toString().trim();
        }
        break;
      }

      if (candidate is List) {
        for (final item in candidate) {
          if (item is Map<String, dynamic> && item[key] != null) {
            return item[key].toString().trim();
          }
        }
        break;
      }

      break;
    }

    final asString = candidate.toString().trim();
    final guidMatch = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(asString);
    if (guidMatch != null) {
      return guidMatch.group(0)!;
    }

    return asString;
  }

  String _extractGuid(String source) {
    final guidMatch = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    ).firstMatch(source);
    if (guidMatch == null) {
      throw ArgumentError('Invalid id format: $source');
    }
    return guidMatch.group(0)!;
  }
}

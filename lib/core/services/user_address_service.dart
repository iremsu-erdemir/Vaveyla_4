import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user_address.dart';
import 'auth_service.dart';

class UserAddressService {
  UserAddressService({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<List<UserAddress>> getAddresses({required String userId}) async {
    final normalizedUserId = _normalizeId(userId, key: 'userId');
    final response = await _getWithFallback(
      path: '/api/users/${Uri.encodeComponent(normalizedUserId)}/addresses',
    );
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(UserAddress.fromJson)
          .toList();
    }

    throw AuthException(_extractMessage(response));
  }

  Future<UserAddress> createAddress({
    required String userId,
    required String label,
    required String addressLine,
    String? addressDetail,
    bool isSelected = true,
  }) async {
    final normalizedUserId = _normalizeId(userId, key: 'userId');
    final response = await _requestWithFallback(
      method: 'POST',
      path: '/api/users/${Uri.encodeComponent(normalizedUserId)}/addresses',
      body: {
        'label': label,
        'addressLine': addressLine,
        'addressDetail': addressDetail,
        'isSelected': isSelected,
      },
    );
    return _decodeAddress(response);
  }

  Future<UserAddress> updateAddress({
    required String userId,
    required String addressId,
    required String label,
    required String addressLine,
    String? addressDetail,
    required bool isSelected,
  }) async {
    final normalizedAddressId = _normalizeId(addressId, key: 'addressId');
    final response = await _requestWithFallback(
      method: 'PUT',
      path:
          '/api/users/${Uri.encodeComponent(_normalizeId(userId, key: 'userId'))}'
          '/addresses/${Uri.encodeComponent(normalizedAddressId)}',
      body: {
        'label': label,
        'addressLine': addressLine,
        'addressDetail': addressDetail,
        'isSelected': isSelected,
      },
    );
    return _decodeAddress(response);
  }

  Future<void> deleteAddress({
    required String userId,
    required String addressId,
  }) async {
    final normalizedAddressId = _normalizeId(addressId, key: 'addressId');
    final response = await _requestWithFallback(
      method: 'DELETE',
      path:
          '/api/users/${Uri.encodeComponent(_normalizeId(userId, key: 'userId'))}'
          '/addresses/${Uri.encodeComponent(normalizedAddressId)}',
    );
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      return;
    }

    throw AuthException(_extractMessage(response));
  }

  Future<http.Response> _getWithFallback({required String path}) async {
    for (final baseUrl in _authService.baseUrls) {
      try {
        final uri = _buildRequestUri(baseUrl: baseUrl, path: path);
        return await http
            .get(uri, headers: const {'Content-Type': 'application/json; charset=utf-8'})
            .timeout(const Duration(seconds: 8));
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('UserAddressService GET hata ($baseUrl): $error');
        }
      }
    }
    throw AuthException(
      'Sunucuya baglanilamadi. Lutfen baglantinizi kontrol edin.',
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
        final response = http.Response(responseBody, streamedResponse.statusCode);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        if (kDebugMode) {
          debugPrint(
            'UserAddressService $method cevap hata ($baseUrl): ${response.statusCode} ${response.body}',
          );
        }
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('UserAddressService $method hata ($baseUrl): $error');
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

  UserAddress _decodeAddress(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserAddress.fromJson(data);
    }

    throw AuthException(_extractMessage(response));
  }

  String _extractMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}
    if (response.body.isNotEmpty) {
      return response.body;
    }
    return 'Islem sirasinda bir hata olustu.';
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

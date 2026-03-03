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
        return await http
            .get(Uri.parse('$baseUrl$path'))
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
        final request = http.Request(method, Uri.parse('$baseUrl$path'));
        request.headers['Content-Type'] = 'application/json';
        if (body != null) {
          request.body = jsonEncode(body);
        }
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 8),
        );
        final responseBody = await streamedResponse.stream.bytesToString();
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

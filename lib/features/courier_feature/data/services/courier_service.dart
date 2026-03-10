import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/auth_service.dart'
    show AuthException, AuthService;
import 'package:http/http.dart' as http;

import 'package:flutter_sweet_shop_app_ui/features/courier_feature/data/models/courier_order_model.dart';

class CourierService {
  CourierService({
    required this.authService,
    String? baseUrl,
    List<String>? baseUrls,
  }) : _baseUrls =
            baseUrl != null || (baseUrls != null && baseUrls.isNotEmpty)
                ? AuthService(baseUrl: baseUrl, baseUrls: baseUrls).baseUrls
                : authService.baseUrls;

  final AuthService authService;
  final List<String> _baseUrls;

  /// Kuryeye atanmış siparişleri getirir.
  Future<List<CourierOrderModel>> getOrders({
    required String courierUserId,
  }) async {
    final response = await _getWithFallback(
      path: '/api/courier/orders?courierUserId=$courierUserId',
    );
    final data = _decodeJson(response);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => CourierOrderModel.fromJson(item.cast<String, dynamic>()))
          .toList();
    }
    return [];
  }

  Future<CourierOrderModel> acceptOrder({
    required String courierUserId,
    required String id,
  }) async {
    final response = await _putWithFallback(
      path: '/api/courier/orders/$id/accept?courierUserId=$courierUserId',
      body: const {},
    );
    final data = _decodeJson(response) as Map<String, dynamic>;
    return CourierOrderModel.fromJson(data);
  }

  Future<CourierOrderModel> updateOrderStatus({
    required String courierUserId,
    required String id,
    required CourierOrderStatus status,
  }) async {
    try {
      final response = await _putWithFallback(
        path: '/api/courier/orders/$id/status?courierUserId=$courierUserId',
        body: {'status': status.name},
      );
      final data = _decodeJson(response) as Map<String, dynamic>;
      return CourierOrderModel.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CourierService updateOrderStatus: $e');
      }
      rethrow;
    }
  }

  /// Kurye konumunu günceller (canlı takip için)
  Future<void> updateCourierLocation({
    required String courierUserId,
    required String orderId,
    required double lat,
    required double lng,
    required DateTime timestampUtc,
  }) async {
    try {
      await _putWithFallback(
        path: '/api/courier/orders/$orderId/location?courierUserId=$courierUserId',
        body: {
          'lat': lat,
          'lng': lng,
          'timestampUtc': timestampUtc.toUtc().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CourierService updateCourierLocation: $e');
      }
    }
  }

  Future<http.Response> _getWithFallback({required String path}) async {
    for (final baseUrl in _baseUrls) {
      try {
        return await http
            .get(Uri.parse('$baseUrl$path'))
            .timeout(const Duration(seconds: 8));
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('CourierService GET hata ($baseUrl): $error');
        }
      }
    }
    throw AuthException('Sunucuya bağlanılamadı.');
  }

  Future<http.Response> _putWithFallback({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    for (final baseUrl in _baseUrls) {
      try {
        return await http
            .put(
              Uri.parse('$baseUrl$path'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 8));
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('CourierService PUT hata ($baseUrl): $error');
        }
      }
    }
    throw AuthException('Sunucuya bağlanılamadı.');
  }

  dynamic _decodeJson(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
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
    return response.body.isNotEmpty ? response.body : 'İşlem sırasında bir hata oluştu.';
  }
}

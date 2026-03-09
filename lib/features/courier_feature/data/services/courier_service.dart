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
  /// Backend'de /api/courier/orders endpoint'i yoksa mock data döner.
  Future<List<CourierOrderModel>> getOrders({
    required String courierUserId,
  }) async {
    try {
      final response = await _getWithFallback(
        path: '/api/courier/orders?courierUserId=$courierUserId',
      );
      final data = _decodeJson(response);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) =>
                CourierOrderModel.fromJson(item.cast<String, dynamic>()))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CourierService getOrders: $e - mock data kullanılıyor');
      }
      return _getMockOrders();
    }
    return _getMockOrders();
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
  }) async {
    try {
      await _putWithFallback(
        path: '/api/courier/orders/$orderId/location?courierUserId=$courierUserId',
        body: {'lat': lat, 'lng': lng},
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('CourierService updateCourierLocation: $e');
      }
    }
  }

  List<CourierOrderModel> _getMockOrders() {
    return [
      CourierOrderModel(
        id: '1',
        time: '14:30',
        date: '03.03.2025',
        imagePath: '',
        preparationMinutes: 25,
        items: '2x Donut, 1x Kahve',
        total: 85,
        status: CourierOrderStatus.assigned,
        customerAddress: 'Muaffıklarhane Sk., Sabuni Mh., Edirne',
        customerLat: 41.6757164,
        customerLng: 26.5547864,
        restaurantAddress: 'Balık Pazarı Cd., Dilaverbey Mh., Edirne',
        restaurantLat: 41.6740066,
        restaurantLng: 26.5528021,
        customerName: 'Ahmet Yılmaz',
        customerPhone: '0532 123 4567',
      ),
      CourierOrderModel(
        id: '2',
        time: '14:45',
        date: '03.03.2025',
        imagePath: '',
        preparationMinutes: 20,
        items: '1x Baklava, 2x Lokum',
        total: 120,
        status: CourierOrderStatus.inTransit,
        customerAddress: 'Atatürk Blv., Abdurrahman Mh., Edirne',
        customerLat: 41.6681158,
        customerLng: 26.5702769,
        restaurantAddress: 'Balık Pazarı Cd., Dilaverbey Mh., Edirne',
        restaurantLat: 41.6741273,
        restaurantLng: 26.5529304,
        customerName: 'Ayşe Demir',
        customerPhone: '0533 987 6543',
      ),
      CourierOrderModel(
        id: '3',
        time: '13:15',
        date: '03.03.2025',
        imagePath: '',
        preparationMinutes: 15,
        items: '3x Cupcake, 1x Çay',
        total: 65,
        status: CourierOrderStatus.delivered,
        customerAddress: 'Saraçlar Cd., Edirne',
        customerLat: 41.6771089,
        customerLng: 26.5556832,
        restaurantAddress: 'Muaffıklarhane Sk., Edirne',
        restaurantLat: 41.6757164,
        restaurantLng: 26.5547864,
        customerName: 'Mehmet Kaya',
        customerPhone: '0534 555 1234',
      ),
    ];
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

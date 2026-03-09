import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/auth_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/cart_item_model.dart';
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/product_model.dart';
import 'package:http/http.dart' as http;

class CustomerCartService {
  CustomerCartService({
    AuthService? authService,
    String? baseUrl,
    List<String>? baseUrls,
  }) : _baseUrls =
           baseUrl != null || (baseUrls != null && baseUrls.isNotEmpty)
               ? AuthService(baseUrl: baseUrl, baseUrls: baseUrls).baseUrls
               : (authService ?? AuthService()).baseUrls;

  final List<String> _baseUrls;

  Future<List<CartItemModel>> getCart({required String customerUserId}) async {
    final response = await _getWithFallback(
      path: '/api/customer/cart?customerUserId=$customerUserId',
    );
    final data = _decodeJson(response);
    if (data is! List) {
      return [];
    }

    return data.whereType<Map>().map((item) {
      final map = item.cast<String, dynamic>();
      final unitPrice = _parseDouble(map['unitPrice']);
      final weightKg = _parseDouble(map['weightKg'], fallback: 1);
      final product = ProductModel(
        id: map['productId']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        price: unitPrice * weightKg,
        weight: weightKg,
        imageUrl: map['imagePath']?.toString() ?? '',
        restaurantId: map['restaurantId']?.toString(),
      );
      return CartItemModel(
        cartItemId: map['id']?.toString(),
        product: product,
        quantity: _parseInt(map['quantity'], fallback: 1),
      );
    }).toList();
  }

  Future<void> addItem({
    required String customerUserId,
    required String productId,
    required int quantity,
    required double weightKg,
  }) async {
    await _postWithFallback(
      path: '/api/customer/cart/items?customerUserId=$customerUserId',
      body: {
        'productId': productId,
        'quantity': quantity,
        'weightKg': weightKg,
      },
    );
  }

  Future<void> updateItemQuantity({
    required String customerUserId,
    required String cartItemId,
    required int quantity,
  }) async {
    await _putWithFallback(
      path: '/api/customer/cart/items/$cartItemId?customerUserId=$customerUserId',
      body: {'quantity': quantity},
    );
  }

  Future<void> removeItem({
    required String customerUserId,
    required String cartItemId,
  }) async {
    await _deleteWithFallback(
      path: '/api/customer/cart/items/$cartItemId?customerUserId=$customerUserId',
    );
  }

  Future<void> clearCart({required String customerUserId}) async {
    await _deleteWithFallback(
      path: '/api/customer/cart/clear?customerUserId=$customerUserId',
    );
  }

  Future<http.Response> _getWithFallback({required String path}) async {
    for (final baseUrl in _baseUrls) {
      try {
        return await http
            .get(Uri.parse('$baseUrl$path'))
            .timeout(const Duration(seconds: 8));
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('CustomerCartService GET hata ($baseUrl): $error');
        }
      }
    }
    throw AuthException('Sunucuya bağlanılamadı.');
  }

  Future<http.Response> _postWithFallback({
    required String path,
    required Map<String, dynamic> body,
  }) async {
    for (final baseUrl in _baseUrls) {
      try {
        return await http
            .post(
              Uri.parse('$baseUrl$path'),
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 8));
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('CustomerCartService POST hata ($baseUrl): $error');
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
          debugPrint('CustomerCartService PUT hata ($baseUrl): $error');
        }
      }
    }
    throw AuthException('Sunucuya bağlanılamadı.');
  }

  Future<http.Response> _deleteWithFallback({required String path}) async {
    for (final baseUrl in _baseUrls) {
      try {
        return await http
            .delete(Uri.parse('$baseUrl$path'))
            .timeout(const Duration(seconds: 8));
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('CustomerCartService DELETE hata ($baseUrl): $error');
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
    return response.body.isNotEmpty ? response.body : 'Sepet işlemi başarısız.';
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _parseDouble(dynamic value, {double fallback = 0}) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

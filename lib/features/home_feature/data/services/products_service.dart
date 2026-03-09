import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/auth_service.dart'
    show AuthException, AuthService;
import 'package:flutter_sweet_shop_app_ui/features/cart_feature/data/models/product_model.dart';
import 'package:http/http.dart' as http;

class ProductsService {
  ProductsService({
    AuthService? authService,
    String? baseUrl,
    List<String>? baseUrls,
  }) : _baseUrls =
            baseUrl != null || (baseUrls != null && baseUrls.isNotEmpty)
                ? AuthService(baseUrl: baseUrl, baseUrls: baseUrls).baseUrls
                : (authService ?? AuthService()).baseUrls;

  final List<String> _baseUrls;

  Future<List<ProductModel>> getProducts({
    String? type,
    String? category,
    String? restaurantId,
  }) async {
    final query = <String>[];
    if (type != null && type.isNotEmpty) query.add('type=$type');
    if (category != null && category.isNotEmpty) {
      query.add('category=${Uri.encodeComponent(category)}');
    }
    if (restaurantId != null && restaurantId.isNotEmpty) {
      query.add('restaurantId=${Uri.encodeComponent(restaurantId)}');
    }
    final qs = query.isEmpty ? '' : '?${query.join('&')}';
    final response = await _getWithFallback(path: '/api/products$qs');
    final data = _decodeJson(response);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map((m) => ProductModel.fromApiJson(m))
          .toList();
    }
    return [];
  }

  Future<List<ProductModel>> getFeatured() => getProducts(type: 'featured');
  Future<List<ProductModel>> getNew() => getProducts(type: 'new');
  Future<List<ProductModel>> getPopular() => getProducts(type: 'popular');

  Future<http.Response> _getWithFallback({required String path}) async {
    for (final baseUrl in _baseUrls) {
      try {
        return await http
            .get(Uri.parse('$baseUrl$path'))
            .timeout(const Duration(seconds: 8));
      } on Exception catch (error) {
        if (kDebugMode) {
          debugPrint('ProductsService GET hata ($baseUrl): $error');
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
    throw AuthException('Ürünler yüklenemedi.');
  }
}

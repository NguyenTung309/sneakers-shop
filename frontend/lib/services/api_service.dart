import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';
import '../models/shoe_model.dart';

class ApiService {
  static const String _tokenKey = 'token';
  static const String _roleKey = 'role';
  static const String _emailKey = 'email';
  static const String _fullNameKey = 'fullName';
  static const String _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const int _devPort = 5299;

  static String get baseUrl {
    if (_baseUrlOverride.trim().isNotEmpty) {
      return _baseUrlOverride.endsWith('/api')
          ? _baseUrlOverride
          : '${_baseUrlOverride.replaceAll(RegExp(r"/+$"), "")}/api';
    }

    if (kIsWeb) {
      return 'http://localhost:$_devPort/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:$_devPort/api';
      default:
        return 'http://localhost:$_devPort/api';
    }
  }

  // ── Session ────────────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fullNameKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, (data['token'] ?? '') as String);
    await prefs.setString(_roleKey, (data['role'] ?? 'User') as String);
    await prefs.setString(_emailKey, (data['email'] ?? '') as String);
    await prefs.setString(_fullNameKey, (data['fullName'] ?? '') as String);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_fullNameKey);
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────

  static Future<Map<String, String>> _buildHeaders({
    bool withJson = false,
    bool withAuth = false,
  }) async {
    final headers = <String, String>{};
    if (withJson) headers['Content-Type'] = 'application/json';
    if (withAuth) {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Vui long dang nhap de tiep tuc.');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Exception _requestException(String action, http.Response response) {
    String message = response.reasonPhrase ?? 'Unknown error';
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          message = decoded['message'] as String;
        } else {
          message = response.body;
        }
      } catch (_) {
        message = response.body;
      }
    }
    return Exception('$action failed (${response.statusCode}): $message');
  }

  static Future<http.Response> _get(String path,
      {bool withAuth = false}) async {
    return http
        .get(
          Uri.parse('$baseUrl$path'),
          headers: await _buildHeaders(withAuth: withAuth),
        )
        .timeout(const Duration(seconds: 20));
  }

  static Future<http.Response> _post(String path,
      {Map<String, dynamic>? body, bool withAuth = false}) async {
    return http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: await _buildHeaders(withJson: true, withAuth: withAuth),
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 20));
  }

  static Future<http.Response> _put(String path,
      {Map<String, dynamic>? body, bool withAuth = false}) async {
    return http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: await _buildHeaders(withJson: true, withAuth: withAuth),
          body: jsonEncode(body ?? <String, dynamic>{}),
        )
        .timeout(const Duration(seconds: 20));
  }

  static Future<http.Response> _delete(String path,
      {bool withAuth = false}) async {
    return http
        .delete(
          Uri.parse('$baseUrl$path'),
          headers: await _buildHeaders(withAuth: withAuth),
        )
        .timeout(const Duration(seconds: 20));
  }

  // ── Auth ───────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await _post('/auth/login',
        body: {'email': email.trim(), 'password': password});

    if (response.statusCode != 200) {
      throw _requestException('Login', response);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await saveSession(data);
    return data;
  }

  static Future<Map<String, dynamic>> register(
      String email, String password, String fullName) async {
    final response = await _post('/auth/register', body: {
      'email': email.trim(),
      'password': password,
      'fullName': fullName.trim(),
    });

    if (response.statusCode != 200) {
      throw _requestException('Register', response);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await saveSession(data);
    return data;
  }

  // ── Products ───────────────────────────────────────────────────────────────

  static Future<List<ShoeModel>> getShoes({
    String? name,
    String? brand,
    String? size,
    double? minPrice,
    double? maxPrice,
  }) async {
    final queryParams = <String, String>{};
    if (name != null && name.trim().isNotEmpty) queryParams['name'] = name.trim();
    if (brand != null && brand.trim().isNotEmpty) queryParams['brand'] = brand.trim();
    if (size != null && size.trim().isNotEmpty) queryParams['size'] = size.trim();
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();

    final uri = Uri.parse('$baseUrl/products').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams);
    final response =
        await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw _requestException('Load products', response);
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ShoeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ShoeModel> getShoe(int id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/products/$id'))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw _requestException('Load product', response);
    }
    return ShoeModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static Future<void> createProduct(Map<String, dynamic> product) async {
    final response = await _post('/products', withAuth: true, body: product);
    if (response.statusCode != 201) {
      throw _requestException('Create product', response);
    }
  }

  static Future<void> updateProduct(
      int id, Map<String, dynamic> product) async {
    final response =
        await _put('/products/$id', withAuth: true, body: product);
    if (response.statusCode != 204) {
      throw _requestException('Update product', response);
    }
  }

  // FIX: Thêm deleteProduct khớp với BE DELETE /products/{id}
  static Future<void> deleteProduct(int id) async {
    final response = await _delete('/products/$id', withAuth: true);
    if (response.statusCode != 204) {
      throw _requestException('Delete product', response);
    }
  }

  // ── Cart ───────────────────────────────────────────────────────────────────

  static Future<List<CartItem>> getCart() async {
    final response = await _get('/cart', withAuth: true);
    if (response.statusCode != 200) {
      throw _requestException('Load cart', response);
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addToCart(
      int shoeId, int productVariantId, int quantity) async {
    final response = await _post('/cart', withAuth: true, body: {
      'shoeId': shoeId,
      'productVariantId': productVariantId,
      'quantity': quantity,
    });
    if (response.statusCode != 200) {
      throw _requestException('Add to cart', response);
    }
  }

  static Future<void> removeFromCart(int cartItemId) async {
    final response = await _delete('/cart/$cartItemId', withAuth: true);
    if (response.statusCode != 204) {
      throw _requestException('Remove cart item', response);
    }
  }

  // ── Orders ─────────────────────────────────────────────────────────────────

  static Future<int> createOrder(List<Map<String, dynamic>> items) async {
    final response = await _post('/orders', withAuth: true, body: {'items': items});
    if (response.statusCode != 200) {
      throw _requestException('Create order', response);
    }
    return jsonDecode(response.body) as int;
  }

  static Future<List<Order>> getOrders() async {
    final response = await _get('/orders', withAuth: true);
    if (response.statusCode != 200) {
      throw _requestException('Load orders', response);
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Order>> getAllOrders() async {
    final response = await _get('/orders/all', withAuth: true);
    if (response.statusCode != 200) {
      throw _requestException('Load all orders', response);
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateOrderStatus(int orderId, String status) async {
    final response = await _put('/orders/$orderId/status',
        withAuth: true, body: {'status': status});
    if (response.statusCode != 204) {
      throw _requestException('Update order status', response);
    }
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  // FIX: Bỏ shoeId trong body vì BE lấy từ route {id} rồi
  static Future<void> addReview(
      int shoeId, int rating, String comment) async {
    final response = await _post('/products/$shoeId/review',
        withAuth: true,
        body: {
          'rating': rating,
          'comment': comment.trim(),
        });
    if (response.statusCode != 200) {
      throw _requestException('Add review', response);
    }
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStats() async {
    final response = await _get('/admin/stats', withAuth: true);
    if (response.statusCode != 200) {
      throw _requestException('Load statistics', response);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
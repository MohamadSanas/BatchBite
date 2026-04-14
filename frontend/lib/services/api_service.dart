import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/delivery_location.dart';
import '../models/food_item.dart';
import '../models/order_models.dart';
import '../models/seller_summary.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _u(String path, [Map<String, String>? query]) {
    final base = kApiBase.endsWith('/') ? kApiBase.substring(0, kApiBase.length - 1) : kApiBase;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<dynamic> _decode(http.Response r) async {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      return jsonDecode(utf8.decode(r.bodyBytes));
    }
    throw ApiException(r.statusCode, utf8.decode(r.bodyBytes));
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String university,
  }) async {
    final r = await _client.post(
      _u('/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'university': university,
      }),
    );
    final j = await _decode(r) as Map<String, dynamic>;
    return UserModel.fromJson(j);
  }

  Future<String> login({required String email, required String password}) async {
    final r = await _client.post(
      _u('/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final j = await _decode(r) as Map<String, dynamic>;
    return j['access_token'] as String;
  }

  Future<UserModel> me() async {
    final r = await _client.get(_u('/auth/me'), headers: _headers);
    final j = await _decode(r) as Map<String, dynamic>;
    return UserModel.fromJson(j);
  }

  Future<List<SellerSummary>> listSellers(String university) async {
    final r = await _client.get(_u('/sellers', {'university': university}), headers: _headers);
    final j = await _decode(r) as List<dynamic>;
    return j.map((e) => SellerSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FoodItem>> listFood(int sellerId) async {
    final r = await _client.get(_u('/food/$sellerId'), headers: _headers);
    final j = await _decode(r) as List<dynamic>;
    return j.map((e) => FoodItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<DeliveryLocation>> listDelivery(int sellerId, {bool approvedOnly = true, bool? asOwner}) async {
    final q = <String, String>{'approved_only': '$approvedOnly'};
    final r = await _client.get(_u('/delivery-location/$sellerId', q), headers: _headers);
    final j = await _decode(r) as List<dynamic>;
    return j.map((e) => DeliveryLocation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DeliveryLocation> createDelivery({
    required String name,
    double? lat,
    double? lng,
  }) async {
    final r = await _client.post(
      _u('/delivery-location'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'latitude': lat,
        'longitude': lng,
      }),
    );
    final j = await _decode(r) as Map<String, dynamic>;
    return DeliveryLocation.fromJson(j);
  }

  Future<FoodItem> createFood({required String name, required double price, bool available = true}) async {
    final r = await _client.post(
      _u('/food'),
      headers: _headers,
      body: jsonEncode({'name': name, 'price': price, 'available': available}),
    );
    final j = await _decode(r) as Map<String, dynamic>;
    return FoodItem.fromJson(j);
  }

  Future<OrderModel> createOrder({
    required int sellerId,
    required int deliveryLocationId,
    required DateTime deadline,
    required List<Map<String, dynamic>> items,
  }) async {
    final r = await _client.post(
      _u('/orders'),
      headers: _headers,
      body: jsonEncode({
        'seller_id': sellerId,
        'delivery_location_id': deliveryLocationId,
        'deadline_time': deadline.toUtc().toIso8601String(),
        'items': items,
      }),
    );
    final j = await _decode(r) as Map<String, dynamic>;
    return OrderModel.fromJson(j);
  }

  Future<List<OrderModel>> buyerOrders() async {
    final r = await _client.get(_u('/orders'), headers: _headers);
    final j = await _decode(r) as List<dynamic>;
    return j.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OrderModel>> sellerOrders() async {
    final r = await _client.get(_u('/seller/orders'), headers: _headers);
    final j = await _decode(r) as List<dynamic>;
    return j.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrderModel> getOrder(int id) async {
    final r = await _client.get(_u('/orders/$id'), headers: _headers);
    final j = await _decode(r) as Map<String, dynamic>;
    return OrderModel.fromJson(j);
  }

  Future<OrderModel> updateOrderStatus(int id, String status, {String? reason}) async {
    final r = await _client.patch(
      _u('/orders/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status, if (reason != null) 'reason': reason}),
    );
    final j = await _decode(r) as Map<String, dynamic>;
    return OrderModel.fromJson(j);
  }

  Future<OrderModel> confirmDelivery(int id) async {
    final r = await _client.post(_u('/orders/$id/confirm-delivery'), headers: _headers);
    final j = await _decode(r) as Map<String, dynamic>;
    return OrderModel.fromJson(j);
  }

  Future<OrderModel> cancelOrder(int id, {String? reason}) async {
    final r = await _client.post(
      _u('/orders/$id/cancel'),
      headers: _headers,
      body: jsonEncode({'reason': reason}),
    );
    final j = await _decode(r) as Map<String, dynamic>;
    return OrderModel.fromJson(j);
  }

  Future<Map<String, dynamic>> ordersSummary() async {
    final r = await _client.get(_u('/orders/summary'), headers: _headers);
    return await _decode(r) as Map<String, dynamic>;
  }

  Future<void> sellerRequest({required String kitchenName, String? description}) async {
    final r = await _client.post(
      _u('/seller/request'),
      headers: _headers,
      body: jsonEncode({'kitchen_name': kitchenName, 'description': description}),
    );
    await _decode(r);
  }

  Future<void> updateKitchen({String? kitchenName, String? description}) async {
    final r = await _client.patch(
      _u('/seller/profile'),
      headers: _headers,
      body: jsonEncode({
        if (kitchenName != null) 'kitchen_name': kitchenName,
        if (description != null) 'description': description,
      }),
    );
    await _decode(r);
  }

  Future<List<dynamic>> adminSellerRequests() async {
    final r = await _client.get(_u('/admin/seller-requests'), headers: _headers);
    return await _decode(r) as List<dynamic>;
  }

  Future<void> adminApproveSeller(int userId, bool approve) async {
    final r = await _client.post(
      _u('/admin/seller-approve'),
      headers: _headers,
      body: jsonEncode({'user_id': userId, 'approve': approve}),
    );
    await _decode(r);
  }

  Future<List<dynamic>> adminPendingLocations() async {
    final r = await _client.get(_u('/admin/delivery-locations/pending'), headers: _headers);
    return await _decode(r) as List<dynamic>;
  }

  Future<void> adminApproveLocation(int locationId, bool approve) async {
    final r = await _client.post(
      _u('/admin/delivery-location-approve'),
      headers: _headers,
      body: jsonEncode({'location_id': locationId, 'approve': approve}),
    );
    await _decode(r);
  }

  Future<Map<String, dynamic>> adminTxSummary() async {
    final r = await _client.get(_u('/reports/admin/summary'), headers: _headers);
    return await _decode(r) as Map<String, dynamic>;
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_item.dart';
import '../models/order_models.dart';
import '../models/seller_summary.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

const _kToken = 'jwt';
const _kUniversity = 'university';

class CartLine {
  CartLine({required this.item, required this.quantity});
  final FoodItem item;
  int quantity;
}

class AppState extends ChangeNotifier {
  AppState(this._api);

  final ApiService _api;
  String? token;
  UserModel? user;
  String? university;
  SellerSummary? browsingSeller;
  final Map<int, CartLine> cart = {};
  OrderModel? trackingOrder;

  bool get isLoggedIn => token != null;
  bool get hasUniversity => university != null && university!.isNotEmpty;

  Future<void> loadPersisted() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString(_kToken);
    university = p.getString(_kUniversity);
    _api.setToken(token);
    if (token != null) {
      try {
        user = await _api.me();
      } catch (_) {
        token = null;
        user = null;
        _api.setToken(null);
        await p.remove(_kToken);
      }
    }
    notifyListeners();
  }

  Future<void> clearUniversity() async {
    university = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kUniversity);
    notifyListeners();
  }

  Future<void> setUniversity(String u) async {
    university = u;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUniversity, u);
    if (user != null && user!.university != u) {
      user = UserModel(
        id: user!.id,
        name: user!.name,
        email: user!.email,
        university: u,
        role: user!.role,
        isVerifiedSeller: user!.isVerifiedSeller,
      );
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final t = await _api.login(email: email, password: password);
    token = t;
    _api.setToken(t);
    user = await _api.me();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, t);
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String uni,
  }) async {
    await _api.register(name: name, email: email, password: password, university: uni);
    await login(email, password);
  }

  Future<void> logout() async {
    token = null;
    user = null;
    cart.clear();
    browsingSeller = null;
    _api.setToken(null);
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (token == null) return;
    user = await _api.me();
    notifyListeners();
  }

  void openSeller(SellerSummary s) {
    browsingSeller = s;
    cart.clear();
    notifyListeners();
  }

  void addToCart(FoodItem item) {
    if (browsingSeller == null || item.sellerId != browsingSeller!.sellerId) return;
    cart.putIfAbsent(item.id, () => CartLine(item: item, quantity: 0));
    cart[item.id]!.quantity += 1;
    notifyListeners();
  }

  void removeFromCart(int foodId) {
    final line = cart[foodId];
    if (line == null) return;
    line.quantity -= 1;
    if (line.quantity <= 0) cart.remove(foodId);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  double cartTotal() {
    var t = 0.0;
    for (final c in cart.values) {
      t += c.item.price * c.quantity;
    }
    return t;
  }
}

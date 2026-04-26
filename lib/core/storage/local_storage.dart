import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _cartKey = 'anonymous_cart';

  // Anonymous cart (guest mode)
  Future<List<Map<String, dynamic>>> getAnonymousCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    if (cartJson == null) return [];
    final List decoded = jsonDecode(cartJson);
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> saveAnonymousCart(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(items));
  }

  Future<void> clearAnonymousCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}
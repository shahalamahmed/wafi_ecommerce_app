import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wafi_ecommerce_app/core/errors/error_handler.dart';
import 'package:wafi_ecommerce_app/core/network/api_endpoints.dart';
import 'package:wafi_ecommerce_app/core/network/dio_client.dart';
import 'package:wafi_ecommerce_app/core/network/dio_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/orders/payment_model.dart';

class PaymentService {
  PaymentService(this._dioClient);

  static const String _pendingSessionKey = 'pending_sslcommerz_session';

  final DioClient _dioClient;

  Future<PaymentSession> initiateSslCommerzPayment(OrderDraft draft) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.sslCommerzInitiate,
        data: {
          'draft': draft.toPaymentPayload(gateway: PaymentGateway.sslcommerz),
        },
      );

      final data = Map<String, dynamic>.from(
        response.data as Map? ?? <String, dynamic>{},
      );
      final session = PaymentSession.fromMap(data);
      await savePendingSession(session);
      return session;
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<PaymentStatusSnapshot> fetchPaymentStatus(String attemptId) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.paymentStatus(attemptId),
      );
      final data = Map<String, dynamic>.from(
        response.data as Map? ?? <String, dynamic>{},
      );
      return PaymentStatusSnapshot.fromMap(data);
    } catch (error) {
      throw ErrorHandler.handle(error);
    }
  }

  Future<void> savePendingSession(PaymentSession session) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _pendingSessionKey,
      jsonEncode(session.toMap()),
    );
  }

  Future<PaymentSession?> readPendingSession() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_pendingSessionKey);
    if (raw == null || raw.trim().isEmpty) return null;

    final normalized = _decodeStoredMap(raw);
    if (normalized.isEmpty) return null;
    return PaymentSession.fromMap(normalized);
  }

  Future<void> clearPendingSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingSessionKey);
  }

  Map<String, dynamic> _decodeStoredMap(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService(ref.read(dioClientProvider));
});

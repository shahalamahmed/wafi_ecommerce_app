import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';

import 'order_model.dart';
import 'order_service.dart';

class OrderState {
  const OrderState({
    this.isSubmitting = false,
    this.isLoading = false,
    this.errorMessage,
    this.lastSuccessMessage,
    this.orders = const [],
  });

  final bool isSubmitting;
  final bool isLoading;
  final String? errorMessage;
  final String? lastSuccessMessage;
  final List<CustomerOrder> orders;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  OrderState copyWith({
    bool? isSubmitting,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? lastSuccessMessage,
    bool clearSuccess = false,
    List<CustomerOrder>? orders,
  }) {
    return OrderState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastSuccessMessage: clearSuccess
          ? null
          : lastSuccessMessage ?? this.lastSuccessMessage,
      orders: orders ?? this.orders,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  OrderNotifier(this._service, this._readUserId, this._ref)
    : super(const OrderState());

  final OrderService _service;
  final String? Function() _readUserId;
  final Ref _ref;
  StreamSubscription<List<CustomerOrder>>? _ordersSubscription;

  Future<void> placeOrder(OrderDraft draft) async {
    state = state.copyWith(
      isSubmitting: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _service.placeOrder(draft);
      state = state.copyWith(
        isSubmitting: false,
        lastSuccessMessage: 'Order placed successfully.',
      );
      await loadOrders();
      try {
        await _ref.read(productProvider.notifier).load();
      } catch (_) {
        // Inventory was already reserved; catalog refresh failure should not mask success.
      }
    } on OrderInventoryException catch (error) {
      state = state.copyWith(isSubmitting: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> loadOrders() async {
    final userId = _readUserId();
    await _ordersSubscription?.cancel();
    _ordersSubscription = null;

    if (userId == null || userId.isEmpty) {
      state = state.copyWith(
        orders: const [],
        isLoading: false,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final completer = Completer<void>();

    try {
      _ordersSubscription = _service
          .watchOrders(userId)
          .listen(
            (orders) {
              if (!mounted) return;
              state = state.copyWith(
                orders: orders,
                isLoading: false,
                clearError: true,
              );
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
            onError: (error) {
              if (!mounted) return;
              state = state.copyWith(
                isLoading: false,
                errorMessage: error.toString(),
              );
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
          );
      await completer.future;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService();
});

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final notifier = OrderNotifier(
    ref.read(orderServiceProvider),
    () => ref.read(authProvider).user?.uid,
    ref,
  );
  notifier.loadOrders();
  return notifier;
});

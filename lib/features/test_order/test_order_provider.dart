import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/features/test_order/Test_order_service.dart';
import 'package:wafi_ecommerce_app/features/test_order/test_order_model.dart';

class TestOrderState {
  const TestOrderState({
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
  final List<TestOrderModel> orders;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  TestOrderState copyWith({
    bool? isSubmitting,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? lastSuccessMessage,
    bool clearSuccess = false,
    List<TestOrderModel>? orders,
  }) {
    return TestOrderState(
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

class TestOrderNotifier extends StateNotifier<TestOrderState> {
  TestOrderNotifier(this._service) : super(const TestOrderState());

  final TestOrderService _service;

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final orders = await _service.fetchOrders();
      state = state.copyWith(
        orders: orders,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}

final testOrderServiceProvider = Provider<TestOrderService>((ref) {
  return TestOrderService();
});

final testOrderProvider =
    StateNotifierProvider<TestOrderNotifier, TestOrderState>((ref) {
      final service = ref.watch(testOrderServiceProvider);
      return TestOrderNotifier(service);
    });

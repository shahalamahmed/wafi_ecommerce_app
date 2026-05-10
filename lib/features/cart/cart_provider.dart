import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';

import 'cart_model.dart';
import 'cart_service.dart';

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(
    this._service,
    this._readAuthState,
  ) : super(const CartState.initial()) {
    load();
  }

  final CartService _service;
  final AuthState Function() _readAuthState;

  String? _activeUserId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      _activeUserId = _currentUserId;
      final items = await _service.loadCart(userId: _activeUserId);
      state = state.copyWith(
        items: items,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> handleAuthChanged() async {
    final nextUserId = _currentUserId;
    if (nextUserId == _activeUserId && !state.isLoading) return;
    await load();
  }

  Future<void> addProduct(
    ProductModel product, {
    int quantity = 1,
    String selectedOptionLabel = '',
    String selectedOptionKey = '',
  }) async {
    final entry = CartItem.fromProduct(
      product,
      quantity: quantity,
      selectedOptionLabel: selectedOptionLabel,
      selectedOptionKey: selectedOptionKey,
    );

    final items = [...state.items];
    final index = items.indexWhere((item) => item.id == entry.id);

    if (index >= 0) {
      final current = items[index];
      final nextQuantity = (current.quantity + quantity).clamp(1, _maxQuantityFor(current.stock));
      items[index] = current.copyWith(quantity: nextQuantity);
    } else {
      items.add(
        entry.copyWith(quantity: quantity.clamp(1, _maxQuantityFor(entry.stock))),
      );
    }

    await _setItems(items);
  }

  Future<void> increment(String itemId) async {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    final current = items[index];
    final maxQuantity = _maxQuantityFor(current.stock);
    if (current.quantity >= maxQuantity) return;

    items[index] = current.copyWith(quantity: current.quantity + 1);
    await _setItems(items);
  }

  Future<void> decrement(String itemId) async {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;

    final current = items[index];
    if (current.quantity <= 1) {
      items.removeAt(index);
    } else {
      items[index] = current.copyWith(quantity: current.quantity - 1);
    }

    await _setItems(items);
  }

  Future<void> remove(String itemId) async {
    final items = state.items.where((item) => item.id != itemId).toList();
    await _setItems(items);
  }

  Future<void> clear() async {
    await _setItems(const []);
  }

  int quantityForProduct(
    String productId, {
    String selectedOptionKey = '',
  }) {
    final key = selectedOptionKey.trim().isEmpty
        ? productId
        : '$productId::${selectedOptionKey.trim()}';

    for (final item in state.items) {
      if (item.id == key) {
        return item.quantity;
      }
    }

    return 0;
  }

  String? get _currentUserId {
    final authState = _readAuthState();
    return authState.isAuthenticated ? authState.user?.uid : null;
  }

  int _maxQuantityFor(int stock) => stock <= 0 ? 20 : stock;

  Future<void> _setItems(List<CartItem> items) async {
    state = state.copyWith(
      items: items,
      isSyncing: true,
      clearError: true,
    );

    try {
      await _service.saveCart(items: items, userId: _currentUserId);
      state = state.copyWith(isSyncing: false, clearError: true);
    } catch (error) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: error.toString(),
      );
    }
  }
}

final cartServiceProvider = Provider<CartService>((ref) {
  return CartService();
});

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final notifier = CartNotifier(
    ref.read(cartServiceProvider),
    () => ref.read(authProvider),
  );

  ref.listen(authProvider, (previous, next) {
    notifier.handleAuthChanged();
  });

  return notifier;
});

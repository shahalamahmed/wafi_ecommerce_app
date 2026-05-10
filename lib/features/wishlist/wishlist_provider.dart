import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';

import 'wishlist_model.dart';
import 'wishlist_service.dart';

class WishlistNotifier extends StateNotifier<WishlistState> {
  WishlistNotifier(this._service, this._readAuthState)
    : super(const WishlistState.initial()) {
    load();
  }

  final WishlistService _service;
  final AuthState Function() _readAuthState;

  String? _activeUserId;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      _activeUserId = _currentUserId;
      final items = await _service.loadWishlist(userId: _activeUserId);
      items.sort((a, b) {
        final left = a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
      state = state.copyWith(items: items, isLoading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> handleAuthChanged() async {
    final nextUserId = _currentUserId;
    if (nextUserId == _activeUserId && !state.isLoading) return;
    await load();
  }

  Future<void> toggleProduct(ProductModel product) async {
    final items = [...state.items];
    final index = items.indexWhere((item) => item.productId == product.id);

    if (index >= 0) {
      items.removeAt(index);
    } else {
      items.insert(0, WishlistItem.fromProduct(product));
    }

    await _setItems(items);
  }

  Future<void> remove(String productId) async {
    final items = state.items
        .where((item) => item.productId != productId)
        .toList();
    await _setItems(items);
  }

  Future<void> clear() async {
    await _setItems(const []);
  }

  bool containsProduct(String productId) {
    for (final item in state.items) {
      if (item.productId == productId) return true;
    }
    return false;
  }

  String? get _currentUserId {
    final authState = _readAuthState();
    return authState.isAuthenticated ? authState.user?.uid : null;
  }

  Future<void> _setItems(List<WishlistItem> items) async {
    state = state.copyWith(items: items, isSyncing: true, clearError: true);

    try {
      await _service.saveWishlist(items: items, userId: _currentUserId);
      state = state.copyWith(isSyncing: false, clearError: true);
    } catch (error) {
      state = state.copyWith(isSyncing: false, errorMessage: error.toString());
    }
  }
}

final wishlistServiceProvider = Provider<WishlistService>((ref) {
  return WishlistService();
});

final wishlistProvider = StateNotifierProvider<WishlistNotifier, WishlistState>(
  (ref) {
    final notifier = WishlistNotifier(
      ref.read(wishlistServiceProvider),
      () => ref.read(authProvider),
    );

    ref.listen(authProvider, (previous, next) {
      notifier.handleAuthChanged();
    });

    return notifier;
  },
);

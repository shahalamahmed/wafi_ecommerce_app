import 'dart:async';

import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/offers/offer_provider.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';

import 'owner_management_service.dart';

class OwnerProductManagementState {
  const OwnerProductManagementState({
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  final List<ProductModel> products;
  final List<ProductCategory> categories;
  final bool isLoading;
  final bool isSaving;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  List<ProductModel> get filteredProducts {
    final query = searchQuery.trim().toLowerCase();
    final items =
        products.where((product) {
          if (query.isEmpty) return true;
          return product.name.toLowerCase().contains(query) ||
              product.sku.toLowerCase().contains(query) ||
              product.shortDescription.toLowerCase().contains(query);
        }).toList()..sort((a, b) {
          final aDate =
              a.updatedAt ??
              a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              b.updatedAt ??
              b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
    return items;
  }

  OwnerProductManagementState copyWith({
    List<ProductModel>? products,
    List<ProductCategory>? categories,
    bool? isLoading,
    bool? isSaving,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return OwnerProductManagementState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

class OwnerProductManagementNotifier
    extends StateNotifier<OwnerProductManagementState> {
  OwnerProductManagementNotifier(this._service, this._ref)
    : super(const OwnerProductManagementState()) {
    load();
  }

  final OwnerManagementService _service;
  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final categories = await _service.fetchCategories();
      final products = await _service.fetchProducts();
      state = state.copyWith(
        categories: categories,
        products: products,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> createProduct(OwnerProductDraft draft) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _service.createProduct(draft);
      await _refreshCatalogConsumers();
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Product created successfully.',
      );
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  Future<void> updateProduct(String productId, OwnerProductDraft draft) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _service.updateProduct(productId, draft);
      await _refreshCatalogConsumers();
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Product updated successfully.',
      );
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  Future<void> deleteProduct(String productId) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _service.deleteProduct(productId);
      await _refreshCatalogConsumers();
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Product removed successfully.',
      );
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  Future<void> _refreshCatalogConsumers() async {
    await load();
    await _ref.read(productProvider.notifier).load();
    await _ref.read(offerProvider.notifier).load();
  }
}

class OwnerOrderManagementState {
  const OwnerOrderManagementState({
    this.orders = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.selectedStatus = 'all',
    this.errorMessage,
    this.successMessage,
  });

  final List<CustomerOrder> orders;
  final bool isLoading;
  final bool isSaving;
  final String selectedStatus;
  final String? errorMessage;
  final String? successMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  List<CustomerOrder> get visibleOrders {
    if (selectedStatus == 'all') return orders;
    return orders.where((order) => order.status == selectedStatus).toList();
  }

  OwnerOrderManagementState copyWith({
    List<CustomerOrder>? orders,
    bool? isLoading,
    bool? isSaving,
    String? selectedStatus,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return OwnerOrderManagementState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

class OwnerCategoryManagementState {
  const OwnerCategoryManagementState({
    this.categories = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  final List<ProductCategory> categories;
  final bool isLoading;
  final bool isSaving;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  List<ProductCategory> get filteredCategories {
    final query = searchQuery.trim().toLowerCase();
    final items = categories.where((category) {
      if (query.isEmpty) return true;
      return category.name.toLowerCase().contains(query) ||
          category.description.toLowerCase().contains(query) ||
          (category.parentId ?? '').toLowerCase().contains(query);
    }).toList()..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return items;
  }

  OwnerCategoryManagementState copyWith({
    List<ProductCategory>? categories,
    bool? isLoading,
    bool? isSaving,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return OwnerCategoryManagementState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

class OwnerOrderManagementNotifier
    extends StateNotifier<OwnerOrderManagementState> {
  OwnerOrderManagementNotifier(this._service, this._ref)
    : super(const OwnerOrderManagementState()) {
    load();
  }

  final OwnerManagementService _service;
  final Ref _ref;
  StreamSubscription<List<CustomerOrder>>? _ordersSubscription;

  Future<void> load() async {
    await _ordersSubscription?.cancel();
    _ordersSubscription = null;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    final completer = Completer<void>();

    try {
      _ordersSubscription = _service.watchOrders().listen(
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

  void setStatusFilter(String status) {
    state = state.copyWith(selectedStatus: status);
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _service.updateOrderStatus(orderDocId: orderId, status: status);
      await load();
      try {
        await _ref.read(productProvider.notifier).load();
      } catch (_) {
        // Order update succeeded; catalog refresh failure should not mask success.
      }
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Order status updated to ${_labelFor(status)}.',
      );
    } on OrderStatusUpdateException catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  Future<void> markCodAsPaid({required String orderId}) async {
    final actor = _ref.read(authProvider).user;
    if (actor == null) {
      state = state.copyWith(
        errorMessage: 'Sign in as an owner to collect COD payment.',
      );
      return;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _service.markCodAsPaid(orderDocId: orderId, collector: actor);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'COD payment marked as paid.',
      );
    } on OrderPaymentUpdateException catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  String _labelFor(String value) {
    switch (value) {
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}

class OwnerUserManagementState {
  const OwnerUserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  final List<AppUser> users;
  final bool isLoading;
  final bool isSaving;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  List<AppUser> get filteredUsers {
    final query = searchQuery.trim().toLowerCase();
    final items =
        users.where((user) {
          if (query.isEmpty) return true;
          return user.displayName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              user.phone.toLowerCase().contains(query);
        }).toList()..sort((a, b) {
          if (a.isOwner != b.isOwner) {
            return a.isOwner ? -1 : 1;
          }

          final aDate =
              a.updatedAt ??
              a.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              b.updatedAt ??
              b.createdAt ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });
    return items;
  }

  OwnerUserManagementState copyWith({
    List<AppUser>? users,
    bool? isLoading,
    bool? isSaving,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return OwnerUserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

class OwnerUserManagementNotifier
    extends StateNotifier<OwnerUserManagementState> {
  OwnerUserManagementNotifier(this._service)
    : super(const OwnerUserManagementState()) {
    load();
  }

  final OwnerManagementService _service;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final users = await _service.fetchUsers();
      state = state.copyWith(users: users, isLoading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _service.updateUserRole(userId: userId, role: role);
      final users = await _service.fetchUsers();
      state = state.copyWith(
        users: users,
        isSaving: false,
        successMessage: role == UserRole.owner
            ? 'User promoted to owner.'
            : 'User changed to customer.',
      );
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }
}

class OwnerCategoryManagementNotifier
    extends StateNotifier<OwnerCategoryManagementState> {
  OwnerCategoryManagementNotifier(this._service, this._ref)
    : super(const OwnerCategoryManagementState()) {
    load();
  }

  final OwnerManagementService _service;
  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final categories = await _service.fetchCategories();
      state = state.copyWith(
        categories: categories,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> createCategory(OwnerCategoryDraft draft) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _service.createCategory(draft);
      await _refreshAllCategoryConsumers();
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Category created successfully.',
      );
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  Future<void> updateCategory(
    String categoryId,
    OwnerCategoryDraft draft,
  ) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _service.updateCategory(categoryId, draft);
      await _refreshAllCategoryConsumers();
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Category updated successfully.',
      );
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _service.deleteCategory(categoryId);
      await _refreshAllCategoryConsumers();
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Category removed successfully.',
      );
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  Future<void> _refreshAllCategoryConsumers() async {
    await load();
    await _ref.read(ownerProductManagementProvider.notifier).load();
    await _ref.read(productProvider.notifier).load();
  }
}

final ownerManagementServiceProvider = Provider<OwnerManagementService>((ref) {
  return OwnerManagementService();
});

final ownerProductManagementProvider =
    StateNotifierProvider<
      OwnerProductManagementNotifier,
      OwnerProductManagementState
    >((ref) {
      return OwnerProductManagementNotifier(
        ref.read(ownerManagementServiceProvider),
        ref,
      );
    });

final ownerOrderManagementProvider =
    StateNotifierProvider<
      OwnerOrderManagementNotifier,
      OwnerOrderManagementState
    >((ref) {
      return OwnerOrderManagementNotifier(
        ref.read(ownerManagementServiceProvider),
        ref,
      );
    });

final ownerUserManagementProvider =
    StateNotifierProvider<
      OwnerUserManagementNotifier,
      OwnerUserManagementState
    >((ref) {
      return OwnerUserManagementNotifier(
        ref.read(ownerManagementServiceProvider),
      );
    });

final ownerCategoryManagementProvider =
    StateNotifierProvider<
      OwnerCategoryManagementNotifier,
      OwnerCategoryManagementState
    >((ref) {
      return OwnerCategoryManagementNotifier(
        ref.read(ownerManagementServiceProvider),
        ref,
      );
    });

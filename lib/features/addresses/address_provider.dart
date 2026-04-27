import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/features/addresses/address_model.dart';
import 'package:wafi_ecommerce_app/features/addresses/address_service.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';

class AddressState {
  const AddressState({
    required this.items,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  const AddressState.initial() : this(items: const [], isLoading: true);

  final List<AddressModel> items;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;
  bool get isEmpty => items.isEmpty;

  AddressState copyWith({
    List<AddressModel>? items,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddressState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AddressNotifier extends StateNotifier<AddressState> {
  AddressNotifier(this._service, this._readUserId) : super(const AddressState.initial()) {
    load();
  }

  final AddressService _service;
  final String? Function() _readUserId;

  Future<void> load() async {
    final userId = _readUserId();
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(items: const [], isLoading: false, clearError: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _service.fetchAddresses(userId);
      state = state.copyWith(items: items, isLoading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> save(AddressModel address) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _service.saveAddress(address);
      await load();
      state = state.copyWith(isSaving: false, clearError: true);
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  Future<void> remove(String id) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _service.deleteAddress(id);
      await load();
      state = state.copyWith(isSaving: false, clearError: true);
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }
}

final addressServiceProvider = Provider<AddressService>((ref) {
  return AddressService();
});

final addressProvider = StateNotifierProvider<AddressNotifier, AddressState>((ref) {
  return AddressNotifier(
    ref.read(addressServiceProvider),
    () => ref.read(authProvider).user?.uid,
  );
});

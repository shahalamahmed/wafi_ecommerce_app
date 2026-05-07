import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offer_model.dart';
import 'offer_service.dart';

class OfferState {
  const OfferState({
    required this.offers,
    required this.isLoading,
    this.errorMessage,
  });

  const OfferState.initial() : offers = const [], isLoading = true, errorMessage = null;

  final List<OfferModel> offers;
  final bool isLoading;
  final String? errorMessage;

  bool get hasError => errorMessage != null && errorMessage!.trim().isNotEmpty;

  OfferState copyWith({
    List<OfferModel>? offers,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OfferState(
      offers: offers ?? this.offers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class OfferNotifier extends StateNotifier<OfferState> {
  OfferNotifier(this._service) : super(const OfferState.initial()) {
    load();
  }

  final OfferService _service;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final offers = await _service.fetchActiveOffers();
      state = state.copyWith(
        offers: offers,
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
}

final offerServiceProvider = Provider<OfferService>((ref) {
  return OfferService();
});

final offerProvider = StateNotifierProvider<OfferNotifier, OfferState>((ref) {
  return OfferNotifier(ref.read(offerServiceProvider));
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_provider.dart';
import 'package:wafi_ecommerce_app/features/products/product_model.dart';
import 'package:wafi_ecommerce_app/features/products/product_provider.dart';
import 'package:wafi_ecommerce_app/features/reviews/review_model.dart';
import 'package:wafi_ecommerce_app/features/reviews/review_service.dart';

class ReviewMutationState {
  const ReviewMutationState({
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  ReviewMutationState copyWith({
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return ReviewMutationState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

class ReviewMutationNotifier extends StateNotifier<ReviewMutationState> {
  ReviewMutationNotifier(this._service, this._ref)
    : super(const ReviewMutationState());

  final ReviewService _service;
  final Ref _ref;

  Future<void> submitReview({
    required ProductModel product,
    required int rating,
    required String title,
    required String comment,
  }) async {
    final user = _ref.read(authProvider).user;
    if (user == null) {
      state = state.copyWith(
        errorMessage: 'Sign in to write a review.',
        clearSuccess: true,
      );
      return;
    }

    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      await _service.createOrUpdateReview(
        productId: product.id,
        user: user,
        rating: rating,
        title: title,
        comment: comment,
      );
      await _ref.read(productProvider.notifier).load();
      _ref.invalidate(reviewEligibilityProvider(product.id));
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Your review has been saved.',
      );
    } on ReviewWriteException catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.message);
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

final productReviewsProvider = StreamProvider.autoDispose
    .family<List<ReviewModel>, String>((ref, productId) {
      return ref.watch(reviewServiceProvider).watchProductReviews(productId);
    });

final myProductReviewProvider = StreamProvider.autoDispose
    .family<ReviewModel?, String>((ref, productId) {
      final userId = ref.watch(authProvider).user?.uid;
      if (userId == null || userId.isEmpty) {
        return Stream<ReviewModel?>.value(null);
      }
      return ref
          .watch(reviewServiceProvider)
          .watchMyReview(productId: productId, userId: userId);
    });

final reviewEligibilityProvider = FutureProvider.autoDispose
    .family<ReviewEligibility, String>((ref, productId) {
      final user = ref.watch(authProvider).user;
      return ref
          .watch(reviewServiceProvider)
          .checkReviewEligibility(productId: productId, user: user);
    });

final reviewMutationProvider =
    StateNotifierProvider.autoDispose<
      ReviewMutationNotifier,
      ReviewMutationState
    >((ref) {
      return ReviewMutationNotifier(ref.watch(reviewServiceProvider), ref);
    });

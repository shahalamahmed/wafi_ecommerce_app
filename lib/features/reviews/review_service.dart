import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wafi_ecommerce_app/features/auth/auth_model.dart';
import 'package:wafi_ecommerce_app/features/orders/order_model.dart';
import 'package:wafi_ecommerce_app/features/reviews/review_model.dart';

class ReviewService {
  ReviewService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Stream<List<ReviewModel>> watchProductReviews(String productId) {
    return _reviews.where('productId', isEqualTo: productId).snapshots().map((
      snapshot,
    ) {
      final reviews =
          snapshot.docs
              .map((doc) => ReviewModel.fromMap(doc.id, doc.data()))
              .where((review) => review.isPublished)
              .toList()
            ..sort((a, b) {
              final aDate = a.updatedAt ?? a.createdAt ?? DateTime(2000);
              final bDate = b.updatedAt ?? b.createdAt ?? DateTime(2000);
              return bDate.compareTo(aDate);
            });
      return reviews;
    });
  }

  Stream<ReviewModel?> watchMyReview({
    required String productId,
    required String userId,
  }) {
    return _reviews.doc(_reviewDocId(productId, userId)).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;
      return ReviewModel.fromMap(snapshot.id, snapshot.data()!);
    });
  }

  Future<ReviewEligibility> checkReviewEligibility({
    required String productId,
    required AppUser? user,
  }) async {
    if (user == null) {
      return const ReviewEligibility(
        canReview: false,
        message: 'Sign in to write a review.',
      );
    }

    final sourceOrderId = await _findEligibleDeliveredOrderId(
      userId: user.uid,
      productId: productId,
    );

    if (sourceOrderId == null) {
      return const ReviewEligibility(
        canReview: false,
        message: 'Only delivered buyers can review this product.',
      );
    }

    return ReviewEligibility(
      canReview: true,
      message: null,
      sourceOrderId: sourceOrderId,
    );
  }

  Future<void> createOrUpdateReview({
    required String productId,
    required AppUser user,
    required int rating,
    required String title,
    required String comment,
  }) async {
    final normalizedTitle = title.trim();
    final normalizedComment = comment.trim();

    if (rating < 1 || rating > 5) {
      throw const ReviewWriteException('Select a rating from 1 to 5 stars.');
    }
    if (normalizedTitle.isEmpty) {
      throw const ReviewWriteException('Review title is required.');
    }
    if (normalizedComment.isEmpty) {
      throw const ReviewWriteException('Review comment is required.');
    }

    final eligibility = await checkReviewEligibility(
      productId: productId,
      user: user,
    );
    if (!eligibility.canReview || eligibility.sourceOrderId == null) {
      throw ReviewWriteException(
        eligibility.message ?? 'You cannot review this product yet.',
      );
    }

    final reviewRef = _reviews.doc(_reviewDocId(productId, user.uid));
    final productRef = _products.doc(productId);
    final reviewerName = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : user.email.trim();

    await _firestore.runTransaction((transaction) async {
      final productSnap = await transaction.get(productRef);
      if (!productSnap.exists) {
        throw const ReviewWriteException(
          'This product is no longer available.',
        );
      }

      final reviewSnap = await transaction.get(reviewRef);
      final product = productSnap.data() ?? <String, dynamic>{};
      final existingReview = reviewSnap.exists
          ? ReviewModel.fromMap(reviewSnap.id, reviewSnap.data()!)
          : null;

      final currentCount = (product['reviewCount'] as num?)?.toInt() ?? 0;
      final currentAverage = (product['rating'] as num?)?.toDouble() ?? 0;
      final nextAggregate = _recomputeAggregate(
        currentAverage: currentAverage,
        currentCount: currentCount,
        previousRating: existingReview?.rating,
        nextRating: rating,
      );

      final payload = <String, dynamic>{
        'productId': productId,
        'userId': user.uid,
        'sourceOrderId':
            existingReview?.sourceOrderId ?? eligibility.sourceOrderId,
        'rating': rating,
        'title': normalizedTitle,
        'comment': normalizedComment,
        'status': 'published',
        'reviewerName': reviewerName,
        'isVerifiedPurchase': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!reviewSnap.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(reviewRef, payload, SetOptions(merge: true));
      transaction.update(productRef, {
        'rating': nextAggregate.average,
        'reviewCount': nextAggregate.count,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<String?> _findEligibleDeliveredOrderId({
    required String userId,
    required String productId,
  }) async {
    final snapshot = await _orders.where('userId', isEqualTo: userId).get();
    final orders =
        snapshot.docs
            .map((doc) => CustomerOrder.fromMap(doc.id, doc.data()))
            .toList()
          ..sort((a, b) {
            final aDate = a.deliveredAt ?? a.createdAt ?? DateTime(2000);
            final bDate = b.deliveredAt ?? b.createdAt ?? DateTime(2000);
            return bDate.compareTo(aDate);
          });

    for (final order in orders) {
      if (order.status.trim().toLowerCase() != 'delivered') continue;
      final hasProduct = order.items.any((item) => item.productId == productId);
      if (hasProduct) return order.orderId;
    }
    return null;
  }

  String _reviewDocId(String productId, String userId) =>
      '${productId}_$userId';

  _ReviewAggregate _recomputeAggregate({
    required double currentAverage,
    required int currentCount,
    required int? previousRating,
    required int nextRating,
  }) {
    if (previousRating == null) {
      final count = currentCount + 1;
      final average = (((currentAverage * currentCount) + nextRating) / count)
          .clamp(0, 5)
          .toDouble();
      return _ReviewAggregate(count: count, average: average);
    }

    final count = currentCount <= 0 ? 1 : currentCount;
    final total = (currentAverage * count) - previousRating + nextRating;
    final average = (total / count).clamp(0, 5).toDouble();
    return _ReviewAggregate(count: count, average: average);
  }
}

class ReviewWriteException implements Exception {
  const ReviewWriteException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _ReviewAggregate {
  const _ReviewAggregate({required this.count, required this.average});

  final int count;
  final double average;
}

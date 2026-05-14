import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.sourceOrderId,
    required this.rating,
    required this.title,
    required this.comment,
    required this.status,
    required this.reviewerName,
    required this.isVerifiedPurchase,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final String userId;
  final String sourceOrderId;
  final int rating;
  final String title;
  final String comment;
  final String status;
  final String reviewerName;
  final bool isVerifiedPurchase;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isPublished => status.trim().toLowerCase() == 'published';

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) {
    return ReviewModel(
      id: id,
      productId: (map['productId'] as String?)?.trim() ?? '',
      userId: (map['userId'] as String?)?.trim() ?? '',
      sourceOrderId: (map['sourceOrderId'] as String?)?.trim() ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      title: (map['title'] as String?)?.trim() ?? '',
      comment: (map['comment'] as String?)?.trim() ?? '',
      status: (map['status'] as String?)?.trim() ?? 'published',
      reviewerName: (map['reviewerName'] as String?)?.trim() ?? '',
      isVerifiedPurchase: map['isVerifiedPurchase'] as bool? ?? false,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class ReviewEligibility {
  const ReviewEligibility({
    required this.canReview,
    required this.message,
    this.sourceOrderId,
  });

  final bool canReview;
  final String? message;
  final String? sourceOrderId;
}

import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  const OfferModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.categoryId,
    required this.subCategoryId,
    required this.originalPrice,
    required this.offerPrice,
    required this.discountAmount,
    required this.discountPercent,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final String categoryId;
  final String? subCategoryId;
  final double originalPrice;
  final double offerPrice;
  final double discountAmount;
  final int discountPercent;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasValidDiscount =>
      isActive &&
      originalPrice > offerPrice &&
      discountAmount > 0 &&
      discountPercent > 0;

  factory OfferModel.fromMap(String id, Map<String, dynamic> map) {
    return OfferModel(
      id: id,
      productId: (map['productId'] as String?)?.trim() ?? id,
      productName: (map['productName'] as String?)?.trim() ?? '',
      productImage: (map['productImage'] as String?)?.trim() ?? '',
      categoryId: (map['categoryId'] as String?)?.trim() ?? '',
      subCategoryId: (map['subCategoryId'] as String?)?.trim(),
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0,
      offerPrice: (map['offerPrice'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0,
      discountPercent: (map['discountPercent'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? false,
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

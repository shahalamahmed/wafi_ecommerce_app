import 'package:cloud_firestore/cloud_firestore.dart';

enum AddressType { home, office, other }

class AddressModel {
  const AddressModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.isDefault,
    this.createdAt,
  });

  final String id;
  final String userId;
  final AddressType type;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;
  final DateTime? createdAt;

  String get typeLabel => switch (type) {
        AddressType.home => 'Home',
        AddressType.office => 'Office',
        AddressType.other => 'Other',
      };

  String get formatted => [addressLine1, addressLine2, city, postalCode, country]
      .where((part) => part.trim().isNotEmpty)
      .join(', ');

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'postalCode': postalCode,
      'country': country,
      'isDefault': isDefault,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }

  factory AddressModel.fromMap(String id, Map<String, dynamic> map) {
    return AddressModel(
      id: id,
      userId: (map['userId'] as String?)?.trim() ?? '',
      type: _parseType(map['type'] as String?),
      addressLine1: (map['addressLine1'] as String?)?.trim() ?? '',
      addressLine2: (map['addressLine2'] as String?)?.trim() ?? '',
      city: (map['city'] as String?)?.trim() ?? '',
      postalCode: (map['postalCode'] as String?)?.trim() ?? '',
      country: (map['country'] as String?)?.trim() ?? '',
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  static AddressType _parseType(String? raw) {
    return switch (raw) {
      'home' => AddressType.home,
      'office' => AddressType.office,
      _ => AddressType.other,
    };
  }
}

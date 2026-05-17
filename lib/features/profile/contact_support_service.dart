import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactSupportRequest {
  const ContactSupportRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.message,
    required this.userId,
    required this.isGuest,
    this.issueType,
    this.orderId,
  });

  final String name;
  final String email;
  final String phone;
  final String message;
  final String? userId;
  final bool isGuest;
  final String? issueType;
  final String? orderId;

  Map<String, dynamic> toMap() {
    final normalizedIssueType = issueType?.trim() ?? '';
    final normalizedOrderId = orderId?.trim() ?? '';

    return {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'message': message.trim(),
      'userId': userId?.trim().isNotEmpty == true ? userId!.trim() : null,
      'isGuest': isGuest,
      'issueType': normalizedIssueType.isEmpty ? null : normalizedIssueType,
      'orderId': normalizedOrderId.isEmpty ? null : normalizedOrderId,
      'channel': 'profile_contact_form',
      'source': 'profile_screen',
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class ContactSupportService {
  ContactSupportService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> submitContactRequest(ContactSupportRequest request) async {
    await _firestore.collection('contact_submissions').add(request.toMap());
  }
}

final contactSupportServiceProvider = Provider<ContactSupportService>((ref) {
  return ContactSupportService();
});

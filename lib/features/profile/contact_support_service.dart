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
  });

  final String name;
  final String email;
  final String phone;
  final String message;
  final String? userId;
  final bool isGuest;

  Map<String, dynamic> toMap() {
    return {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'message': message.trim(),
      'userId': userId?.trim().isNotEmpty == true ? userId!.trim() : null,
      'isGuest': isGuest,
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

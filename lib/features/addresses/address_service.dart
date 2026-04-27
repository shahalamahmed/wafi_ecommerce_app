import 'package:cloud_firestore/cloud_firestore.dart';

import 'address_model.dart';

class AddressService {
  AddressService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<AddressModel>> fetchAddresses(String userId) async {
    final snapshot = await _firestore
        .collection('addresses')
        .where('userId', isEqualTo: userId)
        .get();

    final items = snapshot.docs
        .map((doc) => AddressModel.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) {
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
    return items;
  }

  Future<void> saveAddress(AddressModel address) async {
    final collection = _firestore.collection('addresses');

    if (address.isDefault) {
      final existing = await collection.where('userId', isEqualTo: address.userId).get();
      for (final doc in existing.docs) {
        if (doc.id == address.id) continue;
        await doc.reference.set({'isDefault': false}, SetOptions(merge: true));
      }
    }

    if (address.id.isEmpty) {
      await collection.add(address.toMap());
      return;
    }

    await collection.doc(address.id).set(address.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteAddress(String id) async {
    await _firestore.collection('addresses').doc(id).delete();
  }
}

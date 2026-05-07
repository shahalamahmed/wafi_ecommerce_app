import 'package:cloud_firestore/cloud_firestore.dart';

import 'offer_model.dart';

class OfferService {
  OfferService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<OfferModel>> fetchActiveOffers() async {
    final snapshot = await _firestore
        .collection('offers')
        .where('isActive', isEqualTo: true)
        .get();

    final offers = snapshot.docs
        .map((doc) => OfferModel.fromMap(doc.id, doc.data()))
        .where((offer) => offer.hasValidDiscount)
        .toList()
      ..sort((a, b) {
        final aDate =
            a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return offers;
  }
}

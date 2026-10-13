import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/utils/tawad_eligibility.dart';

class TawadEligibilityService {
  const TawadEligibilityService();

  DocumentReference<Map<String, dynamic>> eligibilityReference({
    required String vendorId,
    required String supplierId,
  }) {
    return FirebaseFirestore.instance
        .collection('tawadEligibility')
        .doc(vendorId)
        .collection('suppliers')
        .doc(supplierId);
  }

  Future<bool> unlockFromExistingPurchase({
    required String vendorId,
    required String supplierId,
  }) async {
    final cleanVendorId = vendorId.trim();
    final cleanSupplierId = supplierId.trim();

    if (cleanVendorId.isEmpty || cleanSupplierId.isEmpty) {
      return false;
    }

    final eligibility = eligibilityReference(
      vendorId: cleanVendorId,
      supplierId: cleanSupplierId,
    );

    if ((await eligibility.get()).exists) {
      return true;
    }

    // Query only the buyer's own readable orders, then check the supplier and
    // completion fields locally. This avoids requiring a new composite index.
    final orders = await FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: cleanVendorId)
        .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? qualifyingOrder;
    for (final order in orders.docs) {
      final data = order.data();
      if (data['supplierId']?.toString().trim() == cleanSupplierId &&
          TawadEligibility.isQualifyingOrder(data)) {
        qualifyingOrder = order;
        break;
      }
    }

    if (qualifyingOrder == null) {
      return false;
    }

    final qualifyingOrderId = qualifyingOrder.id;
    final qualifyingOrderReference = qualifyingOrder.reference;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final existingEligibility = await transaction.get(eligibility);
      if (existingEligibility.exists) {
        return;
      }

      final latestOrder = await transaction.get(qualifyingOrderReference);
      final latestData = latestOrder.data();
      if (!latestOrder.exists ||
          latestData == null ||
          latestData['vendorId']?.toString().trim() != cleanVendorId ||
          latestData['supplierId']?.toString().trim() != cleanSupplierId ||
          !TawadEligibility.isQualifyingOrder(latestData)) {
        throw StateError(
          'A delivered and paid order is required before requesting Tawad.',
        );
      }

      transaction.set(eligibility, <String, dynamic>{
        'vendorId': cleanVendorId,
        'supplierId': cleanSupplierId,
        'qualifyingOrderId': qualifyingOrderId,
        'unlockedAt': FieldValue.serverTimestamp(),
      });
    });

    return true;
  }
}

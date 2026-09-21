import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/utils/stock_state.dart';

/// Read-only data and business helpers used by the supplier dashboard.
///
/// Keeping these queries and calculations out of the screen makes the
/// dashboard easier to maintain without mixing Firestore logic with UI code.
class SupplierDashboardService {
  const SupplierDashboardService();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> stockStream(String supplierId) {
    return _firestore
        .collection('fishStocks')
        .where('supplierId', isEqualTo: supplierId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> orderStream(String supplierId) {
    return _firestore
        .collection('orders')
        .where('supplierId', isEqualTo: supplierId)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> supplierProfileStream(
    String supplierId,
  ) {
    return _firestore
        .collection('supplierProfiles')
        .doc(supplierId)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> supplierProfile(
    String supplierId,
  ) {
    return _firestore.collection('supplierProfiles').doc(supplierId).get();
  }

  double numberValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String stringValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  int createdAtMillis(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final value = document.data()['createdAt'];
    return value is Timestamp ? value.millisecondsSinceEpoch : 0;
  }

  double thresholdFor(Map<String, dynamic> data) {
    final saved = numberValue(data, 'lowStockLevel');
    if (saved > 0) {
      return saved;
    }

    final referenceStock = numberValue(data, 'referenceStockQuantity');
    final reference = referenceStock > 0
        ? referenceStock
        : numberValue(data, 'quantity');
    final savedPercentage = numberValue(data, 'lowStockPercentage');
    final percentage = savedPercentage > 0 ? savedPercentage : 20;

    return reference * percentage / 100;
  }

  bool isHidden(Map<String, dynamic> data) {
    return StockState.isIntentionallyHidden(data);
  }

  bool isOutOfStock(Map<String, dynamic> data) {
    return !isHidden(data) && numberValue(data, 'quantity') <= 0;
  }

  bool isLowStock(Map<String, dynamic> data) {
    final quantity = numberValue(data, 'quantity');
    return !isHidden(data) && quantity > 0 && quantity <= thresholdFor(data);
  }

  bool isAvailable(Map<String, dynamic> data) {
    return !isHidden(data) && numberValue(data, 'quantity') > thresholdFor(data);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> sortStocks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    int priority(Map<String, dynamic> data) {
      if (isOutOfStock(data)) {
        return 0;
      }
      if (isLowStock(data)) {
        return 1;
      }
      if (isAvailable(data)) {
        return 2;
      }
      return 3;
    }

    final result = [...documents];
    result.sort((a, b) {
      final priorityCompare = priority(a.data()).compareTo(priority(b.data()));
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return createdAtMillis(b).compareTo(createdAtMillis(a));
    });
    return result;
  }

  int activeListings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where((document) {
      final data = document.data();
      return !isHidden(data) && numberValue(data, 'quantity') > 0;
    }).length;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> stockAlerts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where((document) {
      final data = document.data();
      return isLowStock(data) || isOutOfStock(data);
    }).toList();
  }

  int activeOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where((document) {
      final status = stringValue(
        document.data(),
        'orderStatus',
        'pending',
      ).toLowerCase();
      return status == 'pending' || status == 'accepted';
    }).length;
  }

  int pendingOrders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return documents.where((document) {
      return stringValue(
            document.data(),
            'orderStatus',
            'pending',
          ).toLowerCase() ==
          'pending';
    }).length;
  }

  String supplierLocation(Map<String, dynamic> data) {
    final approvedStoreLocation = stringValue(data, 'storeLocation', '');

    if (approvedStoreLocation.isNotEmpty) {
      return approvedStoreLocation;
    }

    final parts = <String>[
      stringValue(data, 'storeAddress', ''),
      stringValue(data, 'storeCityMunicipality', ''),
      stringValue(data, 'storeProvince', ''),
      'Caraga Region',
    ].where((value) => value.trim().isNotEmpty).toList();

    if (parts.length > 1) {
      return parts.join(', ');
    }

    return stringValue(data, 'location', 'Caraga Region');
  }
}

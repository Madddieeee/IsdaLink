import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierProductStats {
  const SupplierProductStats({
    required this.totalProducts,
    required this.lowStockCount,
    required this.unavailableCount,
  });

  final int totalProducts;
  final int lowStockCount;
  final int unavailableCount;
}

class SupplierProductUpdateInput {
  const SupplierProductUpdateInput({
    required this.productName,
    required this.price,
    required this.quantity,
    required this.lowStockLevel,
  });

  final String productName;
  final double price;
  final double quantity;
  final double lowStockLevel;
}

class SupplierProductService {
  const SupplierProductService();

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  fishStocksStream(
    String supplierId,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .where(
          'supplierId',
          isEqualTo: supplierId,
        )
        .snapshots();
  }

  List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  sortStocks(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    final sortedDocuments = [
      ...documents,
    ];

    sortedDocuments.sort(
      (
        a,
        b,
      ) =>
          OrderHelpers.createdAtMillis(
            b,
          ).compareTo(
            OrderHelpers.createdAtMillis(
              a,
            ),
          ),
    );

    return sortedDocuments;
  }

  SupplierProductStats calculateStats(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    final unavailableCount = documents.where(
      (
        document,
      ) {
        final status = OrderHelpers.getStringValue(
          document.data(),
          'status',
          'available',
        );

        return status.toLowerCase() ==
            'unavailable';
      },
    ).length;

    final lowStockCount = documents.where(
      (
        document,
      ) {
        final data = document.data();

        final status = OrderHelpers.getStringValue(
          data,
          'status',
          'available',
        );

        final quantity = OrderHelpers.getDoubleValue(
          data,
          'quantity',
        );

        final lowStockLevel = OrderHelpers.getDoubleValue(
          data,
          'lowStockLevel',
        );

        return status.toLowerCase() !=
                'unavailable' &&
            quantity >
                0 &&
            quantity <=
                lowStockLevel;
      },
    ).length;

    return SupplierProductStats(
      totalProducts: documents.length,
      lowStockCount: lowStockCount,
      unavailableCount: unavailableCount,
    );
  }

  Future<
    void
  >
  updateProduct({
    required String documentId,
    required SupplierProductUpdateInput input,
  }) async {
    await FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .doc(
          documentId,
        )
        .update(
          {
            'productName': input.productName.trim(),
            'price': input.price,
            'quantity': input.quantity,
            'lowStockLevel': input.lowStockLevel,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
  }

  Future<
    void
  >
  toggleAvailability({
    required String documentId,
    required String currentStatus,
  }) async {
    final newStatus =
        currentStatus.toLowerCase() ==
            'unavailable'
        ? 'available'
        : 'unavailable';

    await FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .doc(
          documentId,
        )
        .update(
          {
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
  }

  Future<
    void
  >
  deleteProduct(
    String documentId,
  ) async {
    await FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .doc(
          documentId,
        )
        .delete();
  }
}

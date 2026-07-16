import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isdalink/utils/order_helpers.dart';

class SupplierDashboardStats {
  const SupplierDashboardStats({
    required this.totalProducts,
    required this.totalStocks,
    required this.lowStockCount,
  });

  final int totalProducts;
  final double totalStocks;
  final int lowStockCount;
}

class SupplierDashboardService {
  const SupplierDashboardService();

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

  SupplierDashboardStats calculateStats(
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
    final totalProducts = documents.length;

    final totalStocks =
        documents.fold<
          double
        >(
          0.0,
          (
            total,
            document,
          ) {
            return total +
                OrderHelpers.getDoubleValue(
                  document.data(),
                  'quantity',
                );
          },
        );

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

    return SupplierDashboardStats(
      totalProducts: totalProducts,
      totalStocks: totalStocks,
      lowStockCount: lowStockCount,
    );
  }
}

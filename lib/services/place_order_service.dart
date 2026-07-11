import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/utils/order_helpers.dart';

class PlaceOrderResult {
  const PlaceOrderResult({
    required this.orderId,
    required this.stockId,
    required this.remainingStock,
  });

  final String orderId;
  final String stockId;
  final double remainingStock;
}

class PlaceOrderService {
  const PlaceOrderService();

  Future<
    String
  >
  resolveStockId({
    required Supplier supplier,
    required FishProduct product,
    required String stockId,
    required String supplierId,
  }) async {
    if (stockId.trim().isNotEmpty) {
      return stockId.trim();
    }

    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
    snapshot;

    if (supplierId.trim().isNotEmpty) {
      snapshot = await FirebaseFirestore.instance
          .collection(
            'fishStocks',
          )
          .where(
            'supplierId',
            isEqualTo: supplierId.trim(),
          )
          .where(
            'productName',
            isEqualTo: product.name,
          )
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection(
            'fishStocks',
          )
          .where(
            'supplierName',
            isEqualTo: supplier.name,
          )
          .where(
            'productName',
            isEqualTo: product.name,
          )
          .get();
    }

    final matchingDocuments = snapshot.docs.where(
      (
        document,
      ) {
        final data = document.data();

        final status = OrderHelpers.getStringValue(
          data,
          'status',
          'available',
        ).toLowerCase();

        final availableQuantity = OrderHelpers.getDoubleValue(
          data,
          'quantity',
        );

        return (status ==
                    'available' ||
                status ==
                    'active') &&
            availableQuantity >
                0;
      },
    ).toList();

    if (matchingDocuments.isEmpty) {
      throw Exception(
        'Unable to find the selected stock record. Please go back and select the product again from Browse Suppliers.',
      );
    }

    matchingDocuments.sort(
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

    return matchingDocuments.first.id;
  }

  Future<
    PlaceOrderResult
  >
  createCodOrder({
    required User user,
    required Supplier supplier,
    required FishProduct product,
    required int quantity,
    required String stockId,
    required String supplierId,
  }) async {
    final resolvedStockId = await resolveStockId(
      supplier: supplier,
      product: product,
      stockId: stockId,
      supplierId: supplierId,
    );

    final userDocument = await FirebaseFirestore.instance
        .collection(
          'users',
        )
        .doc(
          user.uid,
        )
        .get();

    final userData =
        userDocument.data() ??
        <
          String,
          dynamic
        >{};

    final vendorName = OrderHelpers.getStringValue(
      userData,
      'name',
      user.displayName ??
          user.email ??
          'Vendor',
    );

    final vendorPhone = OrderHelpers.getStringValue(
      userData,
      'phone',
      '',
    );

    final stockReference = FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .doc(
          resolvedStockId,
        );

    final orderReference = FirebaseFirestore.instance
        .collection(
          'orders',
        )
        .doc();

    double finalRemainingStock = 0;

    await FirebaseFirestore.instance.runTransaction(
      (
        transaction,
      ) async {
        final stockSnapshot = await transaction.get(
          stockReference,
        );

        if (!stockSnapshot.exists) {
          throw Exception(
            'This fish stock post no longer exists.',
          );
        }

        final stockData =
            stockSnapshot.data() ??
            <
              String,
              dynamic
            >{};

        final currentStock = OrderHelpers.getDoubleValue(
          stockData,
          'quantity',
        );

        final currentStatus = OrderHelpers.getStringValue(
          stockData,
          'status',
          'available',
        ).toLowerCase();

        if (currentStatus !=
                'available' &&
            currentStatus !=
                'active') {
          throw Exception(
            'This product is no longer available for ordering.',
          );
        }

        if (quantity >
            currentStock) {
          throw Exception(
            'Not enough stock available. Current stock is ${currentStock.toStringAsFixed(0)} ${product.quantityUnit}.',
          );
        }

        final remainingStock =
            currentStock -
            quantity;
        finalRemainingStock = remainingStock;

        final realSupplierId = OrderHelpers.getStringValue(
          stockData,
          'supplierId',
          supplierId,
        );

        final realSupplierName = OrderHelpers.getStringValue(
          stockData,
          'supplierName',
          supplier.name,
        );

        final realSupplierLocation = OrderHelpers.getStringValue(
          stockData,
          'supplierLocation',
          supplier.location,
        );

        final realSupplierContact = OrderHelpers.getStringValue(
          stockData,
          'supplierContactNumber',
          supplier.contactNumber,
        );

        transaction.update(
          stockReference,
          {
            'quantity': remainingStock,
            'status':
                remainingStock <=
                    0
                ? 'unavailable'
                : 'available',
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        transaction.set(
          orderReference,
          {
            'stockId': resolvedStockId,
            'fishStockId': resolvedStockId,
            'supplierId': realSupplierId,
            'productName': product.name,
            'productCategory': product.category,
            'productEmoji': product.emoji,
            'productDescription': product.description,
            'supplierName': realSupplierName,
            'supplierLocation': realSupplierLocation,
            'supplierContactNumber': realSupplierContact,
            'vendorId': user.uid,
            'vendorName': vendorName,
            'vendorEmail':
                user.email ??
                '',
            'vendorPhone': vendorPhone,
            'quantity': quantity,
            'quantityUnit': product.quantityUnit,
            'unitPrice': product.price,
            'priceUnit': product.priceUnit,
            'totalAmount':
                product.price *
                quantity,
            'paymentMethod': 'COD',
            'paymentStatus': 'To be paid on delivery',
            'orderStatus': 'Pending',
            'stockDeducted': true,
            'stockRestored': false,
            'reservedQuantity': quantity,
            'remainingStockAfterOrder': remainingStock,
            'region': 'Caraga Region',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      },
    );

    return PlaceOrderResult(
      orderId: orderReference.id,
      stockId: resolvedStockId,
      remainingStock: finalRemainingStock,
    );
  }
}

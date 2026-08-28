import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isdalink/screens/map/caraga_map_defaults.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/services/stock_notification_service.dart';
import 'package:isdalink/utils/order_helpers.dart';
import 'package:isdalink/utils/stock_state.dart';

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

  StockNotificationService get stockNotificationService =>
      const StockNotificationService();

  String firstNonEmpty(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  Future<String> resolveStockId({
    required Supplier supplier,
    required FishProduct product,
    required String stockId,
    required String supplierId,
  }) async {
    if (stockId.trim().isNotEmpty) {
      return stockId.trim();
    }

    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (supplierId.trim().isNotEmpty) {
      snapshot = await FirebaseFirestore.instance
          .collection('fishStocks')
          .where('supplierId', isEqualTo: supplierId.trim())
          .where('productName', isEqualTo: product.name)
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('fishStocks')
          .where('supplierName', isEqualTo: supplier.name)
          .where('productName', isEqualTo: product.name)
          .get();
    }

    final matchingDocuments = snapshot.docs.where((document) {
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

      return (status == 'available' || status == 'active') &&
          availableQuantity > 0;
    }).toList();

    if (matchingDocuments.isEmpty) {
      throw Exception(
        'Unable to find the selected stock record. Please go back and select the product again from Browse Suppliers.',
      );
    }

    matchingDocuments.sort(
      (a, b) => OrderHelpers.createdAtMillis(b).compareTo(
        OrderHelpers.createdAtMillis(a),
      ),
    );

    return matchingDocuments.first.id;
  }

  Future<PlaceOrderResult> createCodOrder({
    required User user,
    required Supplier supplier,
    required FishProduct product,
    required int quantity,
    required String stockId,
    required String supplierId,
    String buyerName = '',
    String buyerPhone = '',
    String buyerAddress = '',
    required double deliveryLatitude,
    required double deliveryLongitude,
    required String deliveryProvince,
    required String deliveryCityMunicipality,
  }) async {
    final requestedSupplierId = supplierId.trim();

    final validDeliveryPin = CaragaMapDefaults.containsCoordinates(
      latitude: deliveryLatitude,
      longitude: deliveryLongitude,
      province: deliveryProvince,
      locality: deliveryCityMunicipality,
    );

    if (!validDeliveryPin) {
      throw Exception(
        'Choose a delivery location within the selected city or municipality.',
      );
    }

    if (requestedSupplierId.isNotEmpty &&
        requestedSupplierId == user.uid) {
      throw Exception(
        'You cannot place an order from your own supplier store.',
      );
    }

    final resolvedStockId = await resolveStockId(
      supplier: supplier,
      product: product,
      stockId: stockId,
      supplierId: supplierId,
    );

    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDocument.data() ?? <String, dynamic>{};

    final savedVendorName = firstNonEmpty(
      userData,
      const ['name', 'fullName', 'displayName'],
      fallback: user.displayName ?? user.email ?? 'Vendor',
    );

    final savedVendorPhone = firstNonEmpty(
      userData,
      const ['phone', 'contactNumber', 'mobileNumber'],
    );

    final savedVendorAddress = firstNonEmpty(
      userData,
      const ['deliveryAddress', 'address', 'location', 'region'],
      fallback: 'Caraga Region',
    );

    final finalVendorName =
        buyerName.trim().isNotEmpty ? buyerName.trim() : savedVendorName;
    final finalVendorPhone =
        buyerPhone.trim().isNotEmpty ? buyerPhone.trim() : savedVendorPhone;
    final finalVendorAddress = buyerAddress.trim().isNotEmpty
        ? buyerAddress.trim()
        : savedVendorAddress;

    final stockReference = FirebaseFirestore.instance
        .collection('fishStocks')
        .doc(resolvedStockId);

    final orderReference = FirebaseFirestore.instance
        .collection('orders')
        .doc();

    final newOrderNotificationReference = FirebaseFirestore.instance
        .collection('notifications')
        .doc();
    final orderCode = orderReference.id.length > 8
        ? orderReference.id.substring(0, 8).toUpperCase()
        : orderReference.id.toUpperCase();

    double finalRemainingStock = 0;

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final stockSnapshot = await transaction.get(stockReference);

      if (!stockSnapshot.exists) {
        throw Exception('This fish stock post no longer exists.');
      }

      final stockData = stockSnapshot.data() ?? <String, dynamic>{};

      final currentStock = OrderHelpers.getDoubleValue(
        stockData,
        'quantity',
      );

      if (!StockState.isMarketplaceOrderable(stockData)) {
        throw Exception(
          'This product is no longer available for ordering.',
        );
      }

      if (quantity > currentStock) {
        throw Exception(
          'Not enough stock available. Current stock is ${currentStock.toStringAsFixed(0)} ${product.quantityUnit}.',
        );
      }

      final remainingStock = currentStock - quantity;
      finalRemainingStock = remainingStock;

      final realSupplierId = OrderHelpers.getStringValue(
        stockData,
        'supplierId',
        supplierId,
      ).trim();

      if (realSupplierId.isNotEmpty && realSupplierId == user.uid) {
        throw Exception(
          'You cannot place an order from your own supplier store.',
        );
      }

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

      final stockTransition = stockNotificationService.transitionFor(
        stockData: stockData,
        nextQuantity: remainingStock,
      );

      transaction.update(
        stockReference,
        {
          ...StockState.fieldsForQuantity(
            stockData,
            quantity: remainingStock,
          ),
          ...stockTransition.markerFields(),
          // Links this exact stock deduction to the order created in the
          // same Firestore transaction. Security Rules validate both writes
          // together so another signed-in user cannot drain supplier stock.
          'lastOrderId': orderReference.id,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      stockNotificationService.createNotificationInTransaction(
        transaction: transaction,
        stockReference: stockReference,
        stockData: stockData,
        nextQuantity: remainingStock,
        transition: stockTransition,
        supplierIdOverride: realSupplierId,
        productNameOverride: product.name,
        quantityUnitOverride: product.quantityUnit,
        sourceOrderId: orderReference.id,
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
          'productImageUrl': product.imageUrl,
          'imageUrl': product.imageUrl,
          'productDescription': product.description,
          'supplierName': realSupplierName,
          'supplierLocation': realSupplierLocation,
          'supplierContactNumber': realSupplierContact,
          'vendorId': user.uid,
          'vendorName': finalVendorName,
          'vendorEmail': user.email ?? '',
          'vendorPhone': finalVendorPhone,
          'vendorAddress': finalVendorAddress,
          'deliveryAddress': finalVendorAddress,
          'deliveryLatitude': deliveryLatitude,
          'deliveryLongitude': deliveryLongitude,
          'deliveryProvince': deliveryProvince.trim(),
          'deliveryCityMunicipality': deliveryCityMunicipality.trim(),
          'deliveryReferenceType': 'map_pin',
          'quantity': quantity,
          'quantityUnit': product.quantityUnit,
          'unitPrice': product.price,
          'priceUnit': product.priceUnit,
          'totalAmount': product.price * quantity,
          'paymentMethod': 'COD',
          'paymentStatus': 'To be paid on delivery',
          'orderStatus': 'Pending',
          'stockDeducted': true,
          'stockRestored': false,
          'newOrderNotificationId': newOrderNotificationReference.id,
          'reservedQuantity': quantity,
          'remainingStockAfterOrder': remainingStock,
          'region': 'Caraga Region',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (realSupplierId.isNotEmpty) {
        transaction.set(
          newOrderNotificationReference,
          <String, dynamic>{
            'notificationId': newOrderNotificationReference.id,
            'userId': realSupplierId,
            'supplierId': realSupplierId,
            'orderId': orderReference.id,
            'title': 'New COD Order',
            'message':
                'Order #$orderCode: $finalVendorName ordered ${OrderHelpers.formatNumber(quantity.toDouble())} ${product.quantityUnit} of ${product.name}.',
            'type': 'new_order',
            'status': 'Pending',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }
    });

    return PlaceOrderResult(
      orderId: orderReference.id,
      stockId: resolvedStockId,
      remainingStock: finalRemainingStock,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/my_orders_screen.dart';

class PlaceOrderScreen
    extends
        StatefulWidget {
  final Supplier supplier;
  final FishProduct product;
  final String stockId;
  final String supplierId;

  const PlaceOrderScreen({
    super.key,
    required this.supplier,
    required this.product,
    this.stockId = '',
    this.supplierId = '',
  });

  @override
  State<
    PlaceOrderScreen
  >
  createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState
    extends
        State<
          PlaceOrderScreen
        > {
  int quantity = 1;
  bool isSubmitting = false;

  double get totalAmount =>
      widget.product.price *
      quantity;

  void decreaseQuantity() {
    if (quantity >
        1) {
      setState(
        () {
          quantity--;
        },
      );
    }
  }

  void increaseQuantity() {
    if (quantity <
        widget.product.availableQuantity) {
      setState(
        () {
          quantity++;
        },
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Quantity cannot exceed available stock.',
          ),
        ),
      );
    }
  }

  String getStringValue(
    Map<
      String,
      dynamic
    >?
    data,
    String key,
    String fallback,
  ) {
    if (data ==
        null) {
      return fallback;
    }

    final value = data[key];

    if (value ==
        null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor: isError
            ? const Color(
                0xFFD32F2F,
              )
            : const Color(
                0xFF2E7D32,
              ),
      ),
    );
  }

  Future<
    String
  >
  resolveStockId() async {
    if (widget.stockId.trim().isNotEmpty) {
      return widget.stockId.trim();
    }

    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
    snapshot;

    if (widget.supplierId.trim().isNotEmpty) {
      snapshot = await FirebaseFirestore.instance
          .collection(
            'fishStocks',
          )
          .where(
            'supplierId',
            isEqualTo: widget.supplierId.trim(),
          )
          .where(
            'productName',
            isEqualTo: widget.product.name,
          )
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection(
            'fishStocks',
          )
          .where(
            'supplierName',
            isEqualTo: widget.supplier.name,
          )
          .where(
            'productName',
            isEqualTo: widget.product.name,
          )
          .get();
    }

    final matchingDocuments = snapshot.docs.where(
      (
        document,
      ) {
        final data = document.data();

        final status = getStringValue(
          data,
          'status',
          'available',
        ).toLowerCase();

        final quantityValue = data['quantity'];
        double availableQuantity = 0;

        if (quantityValue
            is int) {
          availableQuantity = quantityValue.toDouble();
        } else if (quantityValue
            is double) {
          availableQuantity = quantityValue;
        } else if (quantityValue
            is String) {
          availableQuantity =
              double.tryParse(
                quantityValue,
              ) ??
              0;
        }

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
      ) {
        final aCreatedAt = a.data()['createdAt'];
        final bCreatedAt = b.data()['createdAt'];

        final aMillis =
            aCreatedAt
                is Timestamp
            ? aCreatedAt.millisecondsSinceEpoch
            : 0;
        final bMillis =
            bCreatedAt
                is Timestamp
            ? bCreatedAt.millisecondsSinceEpoch
            : 0;

        return bMillis.compareTo(
          aMillis,
        );
      },
    );

    return matchingDocuments.first.id;
  }

  Future<
    void
  >
  confirmOrder() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user ==
        null) {
      showMessage(
        'Please log in first before placing an order.',
        isError: true,
      );
      return;
    }

    setState(
      () {
        isSubmitting = true;
      },
    );

    try {
      final resolvedStockId = await resolveStockId();

      final userDocument = await FirebaseFirestore.instance
          .collection(
            'users',
          )
          .doc(
            user.uid,
          )
          .get();

      final userData = userDocument.data();

      final vendorName = getStringValue(
        userData,
        'name',
        user.displayName ??
            user.email ??
            'Vendor',
      );

      final vendorPhone = getStringValue(
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

          final currentStockValue = stockData['quantity'];

          double currentStock = 0;

          if (currentStockValue
              is int) {
            currentStock = currentStockValue.toDouble();
          } else if (currentStockValue
              is double) {
            currentStock = currentStockValue;
          } else if (currentStockValue
              is String) {
            currentStock =
                double.tryParse(
                  currentStockValue,
                ) ??
                0;
          }

          final currentStatus = getStringValue(
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
              'Not enough stock available. Current stock is ${currentStock.toStringAsFixed(0)} ${widget.product.quantityUnit}.',
            );
          }

          final remainingStock =
              currentStock -
              quantity;

          final realSupplierId = getStringValue(
            stockData,
            'supplierId',
            widget.supplierId,
          );

          final realSupplierName = getStringValue(
            stockData,
            'supplierName',
            widget.supplier.name,
          );

          final realSupplierLocation = getStringValue(
            stockData,
            'supplierLocation',
            widget.supplier.location,
          );

          final realSupplierContact = getStringValue(
            stockData,
            'supplierContactNumber',
            widget.supplier.contactNumber,
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
              'productName': widget.product.name,
              'productCategory': widget.product.category,
              'productEmoji': widget.product.emoji,
              'productDescription': widget.product.description,
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
              'quantityUnit': widget.product.quantityUnit,
              'unitPrice': widget.product.price,
              'priceUnit': widget.product.priceUnit,
              'totalAmount': totalAmount,
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

      if (!mounted) return;

      setState(
        () {
          isSubmitting = false;
        },
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (
              dialogContext,
            ) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    24,
                  ),
                ),
                title: const Text(
                  'Order Placed',
                  style: TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: Text(
                  'Your COD order for ${widget.product.name} has been saved.\n\n'
                  'The ordered quantity has been reserved and deducted from the supplier stock. '
                  'If the supplier cancels the order, the quantity will be returned to the available stock.',
                  style: const TextStyle(
                    color: Color(
                      0xFF52677A,
                    ),
                    height: 1.4,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                      Navigator.pop(
                        context,
                      );
                      Navigator.pop(
                        context,
                      );
                    },
                    child: const Text(
                      'Back to Products',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (
                                _,
                              ) => const MyOrdersScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF146BFF,
                      ),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'View Orders',
                    ),
                  ),
                ],
              );
            },
      );
    } catch (
      error
    ) {
      if (!mounted) return;

      setState(
        () {
          isSubmitting = false;
        },
      );

      showMessage(
        'Failed to place order: $error',
        isError: true,
      );
    }
  }

  Widget quantityButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled
          ? onTap
          : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(
                  0xFF146BFF,
                )
              : const Color(
                  0xFFE1E9F0,
                ),
          borderRadius: BorderRadius.circular(
            15,
          ),
        ),
        child: Icon(
          icon,
          color: enabled
              ? Colors.white
              : const Color(
                  0xFF7B8FA3,
                ),
          size: 22,
        ),
      ),
    );
  }

  Widget detailRow({
    required String label,
    required String value,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(
                  0xFF7B8FA3,
                ),
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(
                  0xFF102C44,
                ),
                fontSize: bold
                    ? 18
                    : 13,
                fontWeight: bold
                    ? FontWeight.w900
                    : FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      const Color(
                        0xFF146BFF,
                      ).withAlpha(
                        24,
                      ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(
                    0xFF146BFF,
                  ),
                  size: 21,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool canDecrease =
        quantity >
        1;
    final bool canIncrease =
        quantity <
        widget.product.availableQuantity;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              54,
              20,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(
                    0xFF102C44,
                  ),
                  Color(
                    0xFF146BFF,
                  ),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(
                  32,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(
                        context,
                      ),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(
                            38,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Expanded(
                      child: Text(
                        'Place COD Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 22,
                ),
                Container(
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(
                      34,
                    ),
                    borderRadius: BorderRadius.circular(
                      24,
                    ),
                    border: Border.all(
                      color: Colors.white.withAlpha(
                        34,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            22,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            widget.product.emoji,
                            style: const TextStyle(
                              fontSize: 38,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              widget.supplier.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(
                                  0xFFDCE9F5,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              '₱${widget.product.price.toStringAsFixed(0)} ${widget.product.priceUnit}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                18,
                22,
                18,
                20,
              ),
              children: [
                sectionCard(
                  title: 'Order Quantity',
                  icon: Icons.add_shopping_cart,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          quantityButton(
                            icon: Icons.remove,
                            onTap: decreaseQuantity,
                            enabled: canDecrease,
                          ),
                          Container(
                            width: 120,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFEAF7FB,
                              ),
                              borderRadius: BorderRadius.circular(
                                18,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    color: Color(
                                      0xFF102C44,
                                    ),
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  widget.product.quantityUnit,
                                  style: const TextStyle(
                                    color: Color(
                                      0xFF7B8FA3,
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          quantityButton(
                            icon: Icons.add,
                            onTap: increaseQuantity,
                            enabled: canIncrease,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      Text(
                        'Available stock: ${widget.product.availableQuantity.toStringAsFixed(0)} ${widget.product.quantityUnit}',
                        style: const TextStyle(
                          color: Color(
                            0xFF7B8FA3,
                          ),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                sectionCard(
                  title: 'Payment Method',
                  icon: Icons.payments,
                  child: Container(
                    padding: const EdgeInsets.all(
                      14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFEAF7FB,
                      ),
                      borderRadius: BorderRadius.circular(
                        18,
                      ),
                      border: Border.all(
                        color:
                            const Color(
                              0xFF146BFF,
                            ).withAlpha(
                              50,
                            ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF146BFF,
                            ),
                            borderRadius: BorderRadius.circular(
                              14,
                            ),
                          ),
                          child: const Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cash on Delivery',
                                style: TextStyle(
                                  color: Color(
                                    0xFF102C44,
                                  ),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(
                                height: 3,
                              ),
                              Text(
                                'Pay the supplier when the order is received.',
                                style: TextStyle(
                                  color: Color(
                                    0xFF7B8FA3,
                                  ),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle,
                          color: Color(
                            0xFF2E7D32,
                          ),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
                sectionCard(
                  title: 'Order Summary',
                  icon: Icons.receipt_long,
                  child: Column(
                    children: [
                      detailRow(
                        label: 'Product',
                        value: widget.product.name,
                      ),
                      detailRow(
                        label: 'Supplier',
                        value: widget.supplier.name,
                      ),
                      detailRow(
                        label: 'Quantity',
                        value: '$quantity ${widget.product.quantityUnit}',
                      ),
                      detailRow(
                        label: 'Price',
                        value: '₱${widget.product.price.toStringAsFixed(0)} ${widget.product.priceUnit}',
                      ),
                      detailRow(
                        label: 'Payment',
                        value: 'COD',
                      ),
                      const Divider(
                        height: 24,
                      ),
                      detailRow(
                        label: 'Total Amount',
                        value: '₱${totalAmount.toStringAsFixed(0)}',
                        bold: true,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFEAF7FB,
                    ),
                    borderRadius: BorderRadius.circular(
                      22,
                    ),
                    border: Border.all(
                      color:
                          const Color(
                            0xFF146BFF,
                          ).withAlpha(
                            42,
                          ),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.cloud_done,
                        color: Color(
                          0xFF146BFF,
                        ),
                        size: 22,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          'Firebase mode: This COD order will reserve stock immediately. Cancelled orders return the reserved stock.',
                          style: TextStyle(
                            color: Color(
                              0xFF52677A,
                            ),
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(
                    0x14000000,
                  ),
                  blurRadius: 14,
                  offset: Offset(
                    0,
                    -4,
                  ),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : confirmOrder,
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle,
                        ),
                  label: Text(
                    isSubmitting
                        ? 'Saving Order...'
                        : 'Confirm COD Order',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF146BFF,
                    ),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(
                      0xFF7B8FA3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

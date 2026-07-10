import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupplierManageProductsScreen
    extends
        StatelessWidget {
  const SupplierManageProductsScreen({
    super.key,
  });

  User? get currentUser => FirebaseAuth.instance.currentUser;

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

  int createdAtMillis(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final value = document.data()['createdAt'];

    if (value
        is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    return 0;
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
          createdAtMillis(
            b,
          ).compareTo(
            createdAtMillis(
              a,
            ),
          ),
    );

    return sortedDocuments;
  }

  String getStringValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
    String fallback,
  ) {
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

  double getDoubleValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
  ) {
    final value = data[key];

    if (value
        is int) {
      return value.toDouble();
    }

    if (value
        is double) {
      return value;
    }

    if (value
        is String) {
      return double.tryParse(
            value,
          ) ??
          0;
    }

    return 0;
  }

  String formatNumber(
    double value,
  ) {
    if (value %
            1 ==
        0) {
      return value.toStringAsFixed(
        0,
      );
    }

    return value.toStringAsFixed(
      2,
    );
  }

  Color getStockColor(
    double quantity,
    double lowStockLevel,
    String status,
  ) {
    if (status.toLowerCase() ==
        'unavailable') {
      return const Color(
        0xFF7B8FA3,
      );
    }

    if (quantity <=
        0) {
      return const Color(
        0xFFD32F2F,
      );
    }

    if (quantity <=
        lowStockLevel) {
      return const Color(
        0xFFFF7A1A,
      );
    }

    return const Color(
      0xFF2E7D32,
    );
  }

  String getStockStatus(
    double quantity,
    double lowStockLevel,
    String status,
  ) {
    if (status.toLowerCase() ==
        'unavailable') {
      return 'Unavailable';
    }

    if (quantity <=
        0) {
      return 'Out of Stock';
    }

    if (quantity <=
        lowStockLevel) {
      return 'Low Stock';
    }

    return 'Available';
  }

  Future<
    void
  >
  updateProduct({
    required BuildContext pageContext,
    required BuildContext dialogContext,
    required String documentId,
    required String productName,
    required String priceText,
    required String quantityText,
    required String lowStockText,
  }) async {
    final price = double.tryParse(
      priceText.trim(),
    );
    final quantity = double.tryParse(
      quantityText.trim(),
    );
    final lowStockLevel = double.tryParse(
      lowStockText.trim(),
    );

    if (productName.trim().isEmpty ||
        price ==
            null ||
        quantity ==
            null ||
        lowStockLevel ==
            null) {
      ScaffoldMessenger.of(
        pageContext,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter valid product values.',
          ),
          backgroundColor: Color(
            0xFFD32F2F,
          ),
        ),
      );
      return;
    }

    if (price <=
            0 ||
        quantity <
            0 ||
        lowStockLevel <
            0) {
      ScaffoldMessenger.of(
        pageContext,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Price, quantity, and low-stock level must be valid.',
          ),
          backgroundColor: Color(
            0xFFD32F2F,
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection(
            'fishStocks',
          )
          .doc(
            documentId,
          )
          .update(
            {
              'productName': productName.trim(),
              'price': price,
              'quantity': quantity,
              'lowStockLevel': lowStockLevel,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );

      if (!dialogContext.mounted ||
          !pageContext.mounted)
        return;

      Navigator.pop(
        dialogContext,
      );

      ScaffoldMessenger.of(
        pageContext,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Product updated successfully.',
          ),
          backgroundColor: Color(
            0xFF2E7D32,
          ),
        ),
      );
    } catch (
      error
    ) {
      if (!pageContext.mounted) return;

      ScaffoldMessenger.of(
        pageContext,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update product: $error',
          ),
          backgroundColor: const Color(
            0xFFD32F2F,
          ),
        ),
      );
    }
  }

  Future<
    void
  >
  toggleAvailability(
    BuildContext context,
    String documentId,
    String currentStatus,
  ) async {
    final newStatus =
        currentStatus.toLowerCase() ==
            'unavailable'
        ? 'available'
        : 'unavailable';

    try {
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

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Product marked as $newStatus.',
          ),
          backgroundColor: const Color(
            0xFF146BFF,
          ),
        ),
      );
    } catch (
      error
    ) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update availability: $error',
          ),
          backgroundColor: const Color(
            0xFFD32F2F,
          ),
        ),
      );
    }
  }

  Future<
    void
  >
  deleteProduct(
    BuildContext context,
    String documentId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection(
            'fishStocks',
          )
          .doc(
            documentId,
          )
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Product deleted from Firebase.',
          ),
          backgroundColor: Color(
            0xFFD32F2F,
          ),
        ),
      );
    } catch (
      error
    ) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete product: $error',
          ),
          backgroundColor: const Color(
            0xFFD32F2F,
          ),
        ),
      );
    }
  }

  void showEditDialog(
    BuildContext pageContext,
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final data = document.data();

    final productNameController = TextEditingController(
      text: getStringValue(
        data,
        'productName',
        '',
      ),
    );

    final priceController = TextEditingController(
      text:
          getDoubleValue(
            data,
            'price',
          ).toStringAsFixed(
            0,
          ),
    );

    final quantityController = TextEditingController(
      text:
          getDoubleValue(
            data,
            'quantity',
          ).toStringAsFixed(
            0,
          ),
    );

    final lowStockController = TextEditingController(
      text:
          getDoubleValue(
            data,
            'lowStockLevel',
          ).toStringAsFixed(
            0,
          ),
    );

    showDialog(
      context: pageContext,
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
                'Edit Product',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: productNameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: Icon(
                          Icons.set_meal,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixIcon: Icon(
                          Icons.sell,
                        ),
                        suffixText: 'PHP',
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(
                          Icons.inventory,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: lowStockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Alert Level',
                        prefixIcon: Icon(
                          Icons.warning_amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                  ),
                  child: const Text(
                    'Cancel',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    updateProduct(
                      pageContext: pageContext,
                      dialogContext: dialogContext,
                      documentId: document.id,
                      productName: productNameController.text,
                      priceText: priceController.text,
                      quantityText: quantityController.text,
                      lowStockText: lowStockController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF146BFF,
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Save',
                  ),
                ),
              ],
            );
          },
    );
  }

  void showDeleteDialog(
    BuildContext context,
    String documentId,
    String productName,
  ) {
    showDialog(
      context: context,
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
                'Delete Product?',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Text(
                'Are you sure you want to delete $productName from this supplier account?',
                style: const TextStyle(
                  color: Color(
                    0xFF52677A,
                  ),
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    dialogContext,
                  ),
                  child: const Text(
                    'Cancel',
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                    deleteProduct(
                      context,
                      documentId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFD32F2F,
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Delete',
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget statCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(
            38,
          ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: Colors.white.withAlpha(
              36,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(
                  0xFFDCE9F5,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget productCard(
    BuildContext context,
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final data = document.data();

    final productName = getStringValue(
      data,
      'productName',
      'Fish Product',
    );
    final category = getStringValue(
      data,
      'category',
      'Fresh Fish',
    );
    final emoji = getStringValue(
      data,
      'emoji',
      '🐟',
    );
    final price = getDoubleValue(
      data,
      'price',
    );
    final priceUnit = getStringValue(
      data,
      'priceUnit',
      'per kilo',
    );
    final quantity = getDoubleValue(
      data,
      'quantity',
    );
    final quantityUnit = getStringValue(
      data,
      'quantityUnit',
      'kilo',
    );
    final lowStockLevel = getDoubleValue(
      data,
      'lowStockLevel',
    );
    final status = getStringValue(
      data,
      'status',
      'available',
    );

    final stockColor = getStockColor(
      quantity,
      lowStockLevel,
      status,
    );
    final stockStatus = getStockStatus(
      quantity,
      lowStockLevel,
      status,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x12000000,
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
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFEAF7FB,
                  ),
                  borderRadius: BorderRadius.circular(
                    18,
                  ),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 13,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      '$category • ₱${price.toStringAsFixed(0)} $priceUnit',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: stockColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            '$stockStatus • ${formatNumber(quantity)} $quantityUnit',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: stockColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showEditDialog(
                    context,
                    document,
                  ),
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                  ),
                  label: const Text(
                    'Edit',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => toggleAvailability(
                    context,
                    document.id,
                    status,
                  ),
                  icon: Icon(
                    status.toLowerCase() ==
                            'unavailable'
                        ? Icons.visibility
                        : Icons.visibility_off,
                    size: 16,
                  ),
                  label: Text(
                    status.toLowerCase() ==
                            'unavailable'
                        ? 'Available'
                        : 'Hide',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDeleteDialog(
                    context,
                    document.id,
                    productName,
                  ),
                  icon: const Icon(
                    Icons.delete,
                    size: 16,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(
                      0xFFD32F2F,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget emptyCard() {
    return Container(
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
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Color(
              0xFF146BFF,
            ),
            size: 44,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'No products to manage yet',
            style: TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'Only fish stocks posted by this supplier account will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingCard() {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              'Loading your products from Firebase...',
              style: TextStyle(
                color: Color(
                  0xFF7B8FA3,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget errorCard(
    Object error,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
      ),
      child: Text(
        'Unable to load your Firebase products: $error',
        style: const TextStyle(
          color: Color(
            0xFFD32F2F,
          ),
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget header(
    BuildContext context,
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

    final unavailableCount = documents.where(
      (
        document,
      ) {
        final status = getStringValue(
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
        final status = getStringValue(
          data,
          'status',
          'available',
        );
        final quantity = getDoubleValue(
          data,
          'quantity',
        );
        final lowStockLevel = getDoubleValue(
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

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Manage Products',
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
            height: 8,
          ),
          const Text(
            'Update posted fish stock, prices, quantities, and availability for this account.',
            style: TextStyle(
              color: Color(
                0xFFDCE9F5,
              ),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Row(
            children: [
              statCard(
                value: '$totalProducts',
                label: 'Products',
                icon: Icons.inventory_2,
              ),
              statCard(
                value: '$lowStockCount',
                label: 'Low Stock',
                icon: Icons.warning_amber,
              ),
              statCard(
                value: '$unavailableCount',
                label: 'Hidden',
                icon: Icons.visibility_off,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget bodyContent(
    BuildContext context,
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
    return Column(
      children: [
        header(
          context,
          documents,
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
              const Text(
                'Your Firebase Product Records',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                'These records belong only to the logged-in supplier account.',
                style: TextStyle(
                  color: Color(
                    0xFF7B8FA3,
                  ),
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              if (documents.isEmpty)
                emptyCard()
              else
                ...documents.map(
                  (
                    document,
                  ) => productCard(
                    context,
                    document,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget loadingBody(
    BuildContext context,
  ) {
    return Column(
      children: [
        header(
          context,
          const [],
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
              const Text(
                'Your Firebase Product Records',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              loadingCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget errorBody(
    BuildContext context,
    Object error,
  ) {
    return Column(
      children: [
        header(
          context,
          const [],
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
              const Text(
                'Your Firebase Product Records',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              errorCard(
                error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget notLoggedInBody() {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(
            22,
          ),
          padding: const EdgeInsets.all(
            18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ),
          ),
          child: const Text(
            'Please log in first to manage supplier products.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(
                0xFFD32F2F,
              ),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final user = currentUser;

    if (user ==
        null) {
      return notLoggedInBody();
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body:
          StreamBuilder<
            QuerySnapshot<
              Map<
                String,
                dynamic
              >
            >
          >(
            stream: fishStocksStream(
              user.uid,
            ),
            builder:
                (
                  context,
                  snapshot,
                ) {
                  if (snapshot.hasError) {
                    return errorBody(
                      context,
                      snapshot.error!,
                    );
                  }

                  if (!snapshot.hasData) {
                    return loadingBody(
                      context,
                    );
                  }

                  final documents = sortStocks(
                    snapshot.data!.docs,
                  );

                  return bodyContent(
                    context,
                    documents,
                  );
                },
          ),
    );
  }
}

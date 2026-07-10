import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';

class SupplierDetailsScreen
    extends
        StatelessWidget {
  final Supplier supplier;
  final String? supplierId;

  const SupplierDetailsScreen({
    super.key,
    required this.supplier,
    this.supplierId,
  });

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  get fishStocksStream {
    return FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
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

  bool matchesSelectedSupplier(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final stockSupplierId = getStringValue(
      data,
      'supplierId',
      '',
    );

    final stockSupplierName = getStringValue(
      data,
      'supplierName',
      '',
    ).toLowerCase();

    final selectedSupplierName = supplier.name.toLowerCase();

    final hasMatchingId =
        supplierId !=
            null &&
        supplierId!.trim().isNotEmpty &&
        stockSupplierId ==
            supplierId;

    final hasMatchingName =
        stockSupplierName ==
        selectedSupplierName;

    return hasMatchingId ||
        hasMatchingName;
  }

  bool isVisibleStock(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final status = getStringValue(
      data,
      'status',
      'available',
    ).toLowerCase();

    return status ==
            'available' ||
        status ==
            'active';
  }

  List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  filterSupplierStocks(
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
    return documents.where(
      (
        document,
      ) {
        final data = document.data();

        return matchesSelectedSupplier(
              data,
            ) &&
            isVisibleStock(
              data,
            );
      },
    ).toList();
  }

  Color getStockColor(
    double quantity,
    double lowStockLevel,
  ) {
    if (quantity <=
        0) {
      return const Color(
        0xFFD32F2F,
      );
    }

    if (quantity <=
        lowStockLevel) {
      return const Color(
        0xFFF57C00,
      );
    }

    return const Color(
      0xFF2E7D32,
    );
  }

  String getStockStatus(
    double quantity,
    double lowStockLevel,
  ) {
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

  FishProduct fishProductFromFirestore(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    return FishProduct(
      name: getStringValue(
        data,
        'productName',
        'Fish Product',
      ),
      category: getStringValue(
        data,
        'category',
        'Fresh Fish',
      ),
      description: getStringValue(
        data,
        'description',
        'Fresh fish stock available for vendor orders.',
      ),
      emoji: getStringValue(
        data,
        'emoji',
        '🐟',
      ),
      price: getDoubleValue(
        data,
        'price',
      ),
      priceUnit: getStringValue(
        data,
        'priceUnit',
        'per kilo',
      ),
      availableQuantity: getDoubleValue(
        data,
        'quantity',
      ),
      quantityUnit: getStringValue(
        data,
        'quantityUnit',
        'kilo',
      ),
      lowStockThreshold: getDoubleValue(
        data,
        'lowStockLevel',
      ),
    );
  }

  void openProduct(
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

    final product = fishProductFromFirestore(
      data,
    );

    final stockSupplierId = getStringValue(
      data,
      'supplierId',
      supplierId ??
          '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => ProductDetailsScreen(
              supplier: supplier,
              product: product,
              stockId: document.id,
              supplierId: stockSupplierId,
            ),
      ),
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

    final stockColor = getStockColor(
      quantity,
      lowStockLevel,
    );
    final stockStatus = getStockStatus(
      quantity,
      lowStockLevel,
    );

    return GestureDetector(
      onTap: () => openProduct(
        context,
        document,
      ),
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            22,
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
        child: Row(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFEAF7FB,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 34,
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
                    category,
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
                          '$stockStatus • ${quantity.toStringAsFixed(0)} $quantityUnit',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: stockColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(
                      0xFF146BFF,
                    ),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  priceUnit,
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF146BFF,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
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
              'Loading available fish products from Firebase...',
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
            size: 42,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'No available fish products yet',
            style: TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'This supplier has no visible Firebase fish stock posts yet.',
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
        'Unable to load Firebase products: $error',
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
    final availableProducts = documents.where(
      (
        document,
      ) {
        final quantity = getDoubleValue(
          document.data(),
          'quantity',
        );
        return quantity >
            0;
      },
    ).length;

    final lowStockProducts = documents.where(
      (
        document,
      ) {
        final data = document.data();
        final quantity = getDoubleValue(
          data,
          'quantity',
        );
        final lowStockLevel = getDoubleValue(
          data,
          'lowStockLevel',
        );

        return quantity >
                0 &&
            quantity <=
                lowStockLevel;
      },
    ).length;

    final firstEmoji = documents.isNotEmpty
        ? getStringValue(
            documents.first.data(),
            'emoji',
            '🐟',
          )
        : '🐟';

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
                  'Supplier Details',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    24,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(
                        0x22000000,
                      ),
                      blurRadius: 16,
                      offset: Offset(
                        0,
                        8,
                      ),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    firstEmoji,
                    style: const TextStyle(
                      fontSize: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(
                            0xFFDCE9F5,
                          ),
                          size: 15,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Expanded(
                          child: Text(
                            supplier.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(
                                0xFFDCE9F5,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.payments,
                          color: Color(
                            0xFFFFB703,
                          ),
                          size: 16,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Text(
                          'COD only',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
            height: 20,
          ),
          Text(
            supplier.description,
            style: const TextStyle(
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
                value: '${documents.length}',
                label: 'Products',
                icon: Icons.inventory_2,
              ),
              statCard(
                value: '$availableProducts',
                label: 'Available',
                icon: Icons.check_circle,
              ),
              statCard(
                value: '$lowStockProducts',
                label: 'Low Stock',
                icon: Icons.warning_amber,
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
                'Available Fish Products',
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
                'Live Firebase stock posts for the selected supplier. Tap a product to view details and place a COD order.',
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
                'Available Fish Products',
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
                'Available Fish Products',
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

  @override
  Widget build(
    BuildContext context,
  ) {
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
            stream: fishStocksStream,
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

                  final documents = filterSupplierStocks(
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

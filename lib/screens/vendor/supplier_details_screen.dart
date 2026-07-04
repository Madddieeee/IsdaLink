import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';

class SupplierDetailsScreen
    extends
        StatelessWidget {
  final Supplier supplier;

  const SupplierDetailsScreen({
    super.key,
    required this.supplier,
  });

  void openProduct(
    BuildContext context,
    FishProduct product,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => ProductDetailsScreen(
              supplier: supplier,
              product: product,
            ),
      ),
    );
  }

  int get availableProducts {
    return supplier.products
        .where(
          (
            product,
          ) =>
              product.availableQuantity >
              0,
        )
        .length;
  }

  int get lowStockProducts {
    return supplier.products
        .where(
          (
            product,
          ) =>
              product.availableQuantity >
                  0 &&
              product.availableQuantity <=
                  product.lowStockThreshold,
        )
        .length;
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
    FishProduct product,
  ) {
    return GestureDetector(
      onTap: () => openProduct(
        context,
        product,
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
                  product.emoji,
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
                    product.name,
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
                    product.category,
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
                          color: product.stockColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          '${product.stockStatus} • ${product.availableQuantity} ${product.quantityUnit}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: product.stockColor,
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
                  '₱${product.price.toStringAsFixed(0)}',
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
                  product.priceUnit,
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final firstProduct = supplier.products.isNotEmpty
        ? supplier.products.first
        : null;

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
                          firstProduct?.emoji ??
                              '🐟',
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
                                Icons.star,
                                color: Color(
                                  0xFFFFB703,
                                ),
                                size: 16,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Text(
                                '${supplier.rating} • ${supplier.reviews} reviews',
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
                      value: '${supplier.products.length}',
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
                  'Tap a product to view details and place a COD order.',
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
                ...supplier.products.map(
                  (
                    product,
                  ) => productCard(
                    context,
                    product,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

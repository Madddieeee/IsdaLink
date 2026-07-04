import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/place_order_screen.dart';

class ProductDetailsScreen
    extends
        StatelessWidget {
  final Supplier supplier;
  final FishProduct product;

  const ProductDetailsScreen({
    super.key,
    required this.supplier,
    required this.product,
  });

  void placeOrder(
    BuildContext context,
  ) {
    if (product.availableQuantity <=
        0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'This product is currently out of stock.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => PlaceOrderScreen(
              supplier: supplier,
              product: product,
            ),
      ),
    );
  }

  Widget infoPill({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = const Color(
      0xFF146BFF,
    ),
  }) {
    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
            ),
            blurRadius: 12,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(
                24,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget stockBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: product.stockColor.withAlpha(
          26,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: product.stockColor.withAlpha(
            80,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
            width: 6,
          ),
          Text(
            product.stockStatus,
            style: TextStyle(
              color: product.stockColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget supplierCard(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF102C44,
        ),
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x18000000,
            ),
            blurRadius: 16,
            offset: Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(
                0xFF146BFF,
              ),
              borderRadius: BorderRadius.circular(
                16,
              ),
            ),
            child: const Icon(
              Icons.storefront,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supplier',
                  style: TextStyle(
                    color: Color(
                      0xFFBFD1E3,
                    ),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  supplier.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(
                        0xFFDCE9F5,
                      ),
                      size: 13,
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
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          const Icon(
            Icons.verified,
            color: Color(
              0xFF38D39F,
            ),
            size: 22,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool isOutOfStock =
        product.availableQuantity <=
        0;

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
              26,
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
                        'Product Details',
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
                  height: 24,
                ),
                Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      34,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(
                          0x22000000,
                        ),
                        blurRadius: 18,
                        offset: Offset(
                          0,
                          9,
                        ),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      product.emoji,
                      style: const TextStyle(
                        fontSize: 62,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                Text(
                  product.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  product.category,
                  style: const TextStyle(
                    color: Color(
                      0xFFDCE9F5,
                    ),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                stockBadge(),
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
                Row(
                  children: [
                    Expanded(
                      child: infoPill(
                        icon: Icons.sell,
                        label: 'Price',
                        value: '₱${product.price.toStringAsFixed(0)} ${product.priceUnit}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  children: [
                    Expanded(
                      child: infoPill(
                        icon: Icons.inventory_2,
                        label: 'Available Stock',
                        value: '${product.availableQuantity} ${product.quantityUnit}',
                        iconColor: product.stockColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  children: [
                    Expanded(
                      child: infoPill(
                        icon: Icons.warning_amber,
                        label: 'Low Stock Alert Level',
                        value: '${product.lowStockThreshold} ${product.quantityUnit}',
                        iconColor: const Color(
                          0xFFFF7A1A,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 18,
                ),
                supplierCard(
                  context,
                ),
                const SizedBox(
                  height: 18,
                ),
                Container(
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
                      const Text(
                        'Product Description',
                        style: TextStyle(
                          color: Color(
                            0xFF102C44,
                          ),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        product.description,
                        style: const TextStyle(
                          color: Color(
                            0xFF52677A,
                          ),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      const Divider(),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: const [
                          Icon(
                            Icons.payments,
                            color: Color(
                              0xFF146BFF,
                            ),
                            size: 20,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(
                              'Payment Method: Cash on Delivery only',
                              style: TextStyle(
                                color: Color(
                                  0xFF102C44,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
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
                  onPressed: isOutOfStock
                      ? null
                      : () => placeOrder(
                          context,
                        ),
                  icon: const Icon(
                    Icons.shopping_cart,
                  ),
                  label: Text(
                    isOutOfStock
                        ? 'Out of Stock'
                        : 'Place COD Order',
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
                      0xFFCAD6E0,
                    ),
                    disabledForegroundColor: const Color(
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

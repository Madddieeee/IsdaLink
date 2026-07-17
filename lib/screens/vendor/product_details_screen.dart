import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/place_order_screen.dart';
import 'package:isdalink/screens/vendor/product_details/widgets/product_bottom_order_bar.dart';
import 'package:isdalink/screens/vendor/product_details/widgets/product_description_card.dart';
import 'package:isdalink/screens/vendor/product_details/widgets/product_details_header.dart';
import 'package:isdalink/screens/vendor/product_details/widgets/product_info_pill.dart';
import 'package:isdalink/screens/vendor/product_details/widgets/product_supplier_card.dart';

class ProductDetailsScreen
    extends
        StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    required this.supplier,
    required this.product,
    this.stockId = '',
    this.supplierId = '',
  });

  final Supplier supplier;
  final FishProduct product;
  final String stockId;
  final String supplierId;

  bool get isOutOfStock =>
      product.availableQuantity <=
      0;

  void placeOrder(
    BuildContext context,
  ) {
    if (isOutOfStock) {
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
              stockId: stockId,
              supplierId: supplierId,
            ),
      ),
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
      body: Column(
        children: [
          ProductDetailsHeader(
            product: product,
            onBack: () => Navigator.pop(
              context,
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
                ProductInfoPill(
                  icon: Icons.sell,
                  label: 'Price',
                  value: '₱${product.price.toStringAsFixed(0)} ${product.priceUnit}',
                ),
                const SizedBox(
                  height: 12,
                ),
                ProductInfoPill(
                  icon: Icons.inventory_2,
                  label: 'Available Stock',
                  value: '${product.availableQuantity.toStringAsFixed(0)} ${product.quantityUnit}',
                  iconColor: product.stockColor,
                ),
                const SizedBox(
                  height: 12,
                ),
                ProductInfoPill(
                  icon: Icons.warning_amber,
                  label: 'Low Stock Alert Level',
                  value: '${product.lowStockThreshold.toStringAsFixed(0)} ${product.quantityUnit}',
                  iconColor: const Color(
                    0xFFFF7A1A,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                ProductSupplierCard(
                  supplier: supplier,
                ),
                const SizedBox(
                  height: 18,
                ),
                ProductDescriptionCard(
                  description: product.description,
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
          ProductBottomOrderBar(
            isOutOfStock: isOutOfStock,
            onPlaceOrder: () => placeOrder(
              context,
            ),
          ),
        ],
      ),
    );
  }
}

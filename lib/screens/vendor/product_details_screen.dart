import 'package:flutter/material.dart';
import 'package:isdalink/core/app_colors.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/place_order_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Supplier supplier;
  final FishProduct product;

  const ProductDetailsScreen({
    super.key,
    required this.supplier,
    required this.product,
  });

  void placeOrder(BuildContext context) {
    if (product.availableQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is currently out of stock.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceOrderScreen(supplier: supplier, product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Fish Product Details'),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Text(product.emoji, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 12),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(product.category),
                  const SizedBox(height: 16),
                  Text(
                    '₱${product.price.toStringAsFixed(2)} ${product.priceUnit}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(
                      product.stockStatus,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: product.stockColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(product.description),
                  const SizedBox(height: 12),
                  Text('Supplier: ${supplier.name}'),
                  Text(
                    'Available Quantity: ${product.availableQuantity} ${product.quantityUnit}',
                  ),
                  Text(
                    'Low Stock Threshold: ${product.lowStockThreshold} ${product.quantityUnit}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Payment Method: Cash on Delivery only',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => placeOrder(context),
              icon: const Icon(Icons.shopping_cart),
              label: const Text(
                'Place COD Order',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:isdalink/core/app_colors.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';

class SupplierDetailsScreen extends StatelessWidget {
  final Supplier supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  void openProduct(BuildContext context, FishProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailsScreen(supplier: supplier, product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Supplier Details'),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(supplier.description),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.blue),
                      const SizedBox(width: 8),
                      Expanded(child: Text(supplier.location)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: AppColors.blue),
                      const SizedBox(width: 8),
                      Text(supplier.contactNumber),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        '${supplier.rating} rating • ${supplier.reviews} reviews',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Available Fish Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
            ),
          ),

          const SizedBox(height: 10),

          ...supplier.products.map((product) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => openProduct(context, product),
                leading: CircleAvatar(
                  backgroundColor: AppColors.lightBg,
                  child: Text(
                    product.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '₱${product.price.toStringAsFixed(2)} ${product.priceUnit}\n'
                  '${product.availableQuantity} ${product.quantityUnit} available',
                ),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(
                    product.stockStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  backgroundColor: product.stockColor,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

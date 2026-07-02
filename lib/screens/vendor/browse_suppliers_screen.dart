import 'package:flutter/material.dart';
import 'package:isdalink/core/app_colors.dart';
import 'package:isdalink/data/sample_data.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';

class BrowseSuppliersScreen extends StatelessWidget {
  const BrowseSuppliersScreen({super.key});

  void openSupplierDetails(BuildContext context, Supplier supplier) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupplierDetailsScreen(supplier: supplier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Browse Suppliers'),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sampleSuppliers.length,
        itemBuilder: (context, index) {
          final supplier = sampleSuppliers[index];

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 14),
            child: ListTile(
              onTap: () => openSupplierDetails(context, supplier),
              leading: const CircleAvatar(
                backgroundColor: AppColors.blue,
                child: Icon(Icons.store, color: Colors.white),
              ),
              title: Text(
                supplier.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${supplier.location}\n⭐ ${supplier.rating} (${supplier.reviews} reviews)',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
    );
  }
}

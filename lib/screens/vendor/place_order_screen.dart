import 'package:flutter/material.dart';
import 'package:isdalink/core/app_colors.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';

class PlaceOrderScreen extends StatefulWidget {
  final Supplier supplier;
  final FishProduct product;

  const PlaceOrderScreen({
    super.key,
    required this.supplier,
    required this.product,
  });

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final TextEditingController quantityController = TextEditingController();

  double get quantity {
    return double.tryParse(quantityController.text) ?? 0;
  }

  double get estimatedTotal {
    return quantity * widget.product.price;
  }

  void confirmOrder() {
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity.')),
      );
      return;
    }

    if (quantity > widget.product.availableQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity exceeds available stock.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Order Placed'),
          content: Text(
            'Your COD order for ${widget.product.name} has been placed.\n\n'
            'Order Status: Pending\n'
            'Payment Status: Unpaid - Cash on Delivery',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Place COD Order'),
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
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Supplier: ${widget.supplier.name}'),
                  Text(
                    'Price: ₱${widget.product.price.toStringAsFixed(2)} ${widget.product.priceUnit}',
                  ),
                  Text(
                    'Available: ${widget.product.availableQuantity} ${widget.product.quantityUnit}',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Payment Method: Cash on Delivery',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text('Payment Status: Unpaid until delivery'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Order Quantity (${widget.product.quantityUnit})',
              prefixIcon: const Icon(Icons.scale),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: AppColors.blue),
              title: const Text(
                'Estimated Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '₱${estimatedTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  color: AppColors.darkBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Confirm COD Order',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

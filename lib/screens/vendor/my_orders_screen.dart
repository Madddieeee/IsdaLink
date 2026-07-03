import 'package:flutter/material.dart';
import 'package:isdalink/core/app_colors.dart';
import 'package:isdalink/data/sample_orders.dart';
import 'package:isdalink/models/order_model.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Color getOrderStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.orange;
      case 'accepted':
        return AppColors.blue;
      case 'delivered':
        return AppColors.green;
      case 'cancelled':
        return AppColors.red;
      default:
        return Colors.grey;
    }
  }

  Color getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return AppColors.green;
      case 'unpaid':
        return AppColors.orange;
      default:
        return Colors.grey;
    }
  }

  String formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget orderCard(OrderModel order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.orderId,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    order.orderStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: getOrderStatusColor(order.orderStatus),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              order.productName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('Supplier: ${order.supplierName}'),
            Text('Quantity: ${order.quantity} ${order.quantityUnit}'),
            Text('Order Date: ${formatDate(order.orderDate)}'),
            const SizedBox(height: 10),
            Text(
              'Total: ₱${order.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.payments, size: 20, color: AppColors.blue),
                const SizedBox(width: 6),
                Expanded(child: Text('Payment Method: ${order.paymentMethod}')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Payment Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    order.paymentStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: getPaymentStatusColor(order.paymentStatus),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Order History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'View your fish orders and Cash on Delivery payment status.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 18),
          ...sampleOrders.map(orderCard),
        ],
      ),
    );
  }
}

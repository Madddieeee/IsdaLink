import 'package:flutter/material.dart';
import 'package:isdalink/models/analytics_models.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_formatters.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_section_card.dart';

class RestockingSuggestionsCard extends StatelessWidget {
  const RestockingSuggestionsCard({super.key, required this.stockAlerts, required this.isSupplierMode});

  final List<StockAlertSummary> stockAlerts;
  final bool isSupplierMode;

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      title: 'Restocking Suggestions',
      subtitle: isSupplierMode
          ? 'Low-stock products owned by this supplier account are flagged.'
          : 'Low-stock products visible in Firebase are flagged for vendor awareness.',
      icon: Icons.notification_important,
      child: stockAlerts.isEmpty
          ? const Text('No low-stock or out-of-stock items found.', style: TextStyle(color: Color(0xFF7B8FA3), fontSize: 13))
          : Column(children: stockAlerts.take(5).map((alert) => StockAlertTile(alert: alert)).toList()),
    );
  }
}

class StockAlertTile extends StatelessWidget {
  const StockAlertTile({super.key, required this.alert});

  final StockAlertSummary alert;

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = alert.quantity <= 0;
    final color = isOutOfStock ? const Color(0xFFD32F2F) : const Color(0xFFFF7A1A);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF4F8FB), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: const Color(0xFFEAF7FB), borderRadius: BorderRadius.circular(17)),
            child: Center(child: Text(alert.emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.productName, style: const TextStyle(color: Color(0xFF102C44), fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(alert.supplierName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF7B8FA3), fontSize: 11)),
                const SizedBox(height: 7),
                Text('${formatAnalyticsNumber(alert.quantity)} ${alert.quantityUnit} left', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(16)),
            child: Text(isOutOfStock ? 'Out of Stock' : 'Low Stock', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:isdalink/models/analytics_models.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_formatters.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_section_card.dart';

class SalesTrendCard extends StatelessWidget {
  const SalesTrendCard({super.key, required this.dailySales});

  final List<DailySalesPoint> dailySales;

  @override
  Widget build(BuildContext context) {
    final recentPoints = dailySales.length > 7 ? dailySales.sublist(dailySales.length - 7) : dailySales;

    final maxQuantity = recentPoints.fold<double>(0.0, (largest, point) => point.quantity > largest ? point.quantity : largest);

    return AnalyticsSectionCard(
      title: 'Sales Trend',
      subtitle: 'Recent completed order quantities grouped by transaction date.',
      icon: Icons.timeline,
      child: recentPoints.isEmpty
          ? const Text('No completed daily sales records yet.', style: TextStyle(color: Color(0xFF7B8FA3), fontSize: 13))
          : Column(
              children: recentPoints.map(
                (point) {
                  final ratio = maxQuantity <= 0 ? 0.0 : point.quantity / maxQuantity;
                  return TrendBarTile(point: point, ratio: ratio);
                },
              ).toList(),
            ),
    );
  }
}

class TrendBarTile extends StatelessWidget {
  const TrendBarTile({super.key, required this.point, required this.ratio});

  final DailySalesPoint point;
  final double ratio;

  String get label => '${point.date.month}/${point.date.day}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(label, style: const TextStyle(color: Color(0xFF52677A), fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: const Color(0xFFEAF7FB),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF146BFF)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 62,
            child: Text(
              '${formatAnalyticsNumber(point.quantity)} units',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF102C44), fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

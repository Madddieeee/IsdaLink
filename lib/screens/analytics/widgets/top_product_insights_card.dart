import 'package:flutter/material.dart';
import 'package:isdalink/models/analytics_models.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_formatters.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_section_card.dart';

class TopProductInsightsCard extends StatelessWidget {
  const TopProductInsightsCard({super.key, required this.topProducts});

  final List<ProductSalesSummary> topProducts;

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      title: 'Top Product Insights',
      subtitle: 'Ranking is based on completed Firebase order quantity.',
      icon: Icons.emoji_events,
      child: topProducts.isEmpty
          ? const Text('No completed order records yet.', style: TextStyle(color: Color(0xFF7B8FA3), fontSize: 13))
          : Column(
              children: topProducts.take(5).toList().asMap().entries.map(
                    (entry) => TopProductTile(rank: entry.key + 1, product: entry.value),
                  ).toList(),
            ),
    );
  }
}

class TopProductTile extends StatelessWidget {
  const TopProductTile({super.key, required this.rank, required this.product});

  final int rank;
  final ProductSalesSummary product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF4F8FB), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: const Color(0xFF146BFF), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Text(product.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.productName, style: const TextStyle(color: Color(0xFF102C44), fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${formatAnalyticsNumber(product.quantity)} total units sold', style: const TextStyle(color: Color(0xFF7B8FA3), fontSize: 11)),
              ],
            ),
          ),
          Text(formatCurrency(product.revenue), style: const TextStyle(color: Color(0xFF146BFF), fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

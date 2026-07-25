import 'package:flutter/material.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_formatters.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_section_card.dart';

class ForecastingMethodsCard extends StatelessWidget {
  const ForecastingMethodsCard({super.key, required this.simpleForecast, required this.seasonalForecast});

  final double simpleForecast;
  final double seasonalForecast;

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      title: 'Forecasting Methods',
      subtitle: 'Forecasts are computed from completed Firebase order records.',
      icon: Icons.trending_up,
      child: Column(
        children: [
          ForecastMethodTile(
            title: 'Simple Moving Average',
            description: 'Uses recent completed order quantities to estimate short-term demand.',
            useCase: 'Current forecast: ${formatAnalyticsNumber(simpleForecast)} units',
            icon: Icons.show_chart,
          ),
          ForecastMethodTile(
            title: 'Seasonal Moving Average',
            description: 'Uses recurring weekday patterns when matching sales records are available.',
            useCase: 'Current forecast: ${formatAnalyticsNumber(seasonalForecast)} units',
            icon: Icons.calendar_month,
          ),
        ],
      ),
    );
  }
}

class ForecastMethodTile extends StatelessWidget {
  const ForecastMethodTile({super.key, required this.title, required this.description, required this.useCase, required this.icon});

  final String title;
  final String description;
  final String useCase;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E9F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: const Color(0xFF146BFF), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF102C44), fontSize: 14, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Color(0xFF52677A), fontSize: 12, height: 1.35)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(color: const Color(0xFFEAF7FB), borderRadius: BorderRadius.circular(14)),
                  child: Text(useCase, style: const TextStyle(color: Color(0xFF146BFF), fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

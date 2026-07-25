import 'package:flutter/material.dart';
import 'package:isdalink/models/analytics_models.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_formatters.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_section_card.dart';

class ForecastEvaluationCard extends StatelessWidget {
  const ForecastEvaluationCard({super.key, required this.evaluation});

  final ForecastEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      title: 'Forecast Evaluation',
      subtitle: evaluation.hasEnoughData
          ? 'MAPE and MAE are computed using simple moving average back-testing.'
          : 'More completed daily sales records are needed to compute stable MAPE and MAE values.',
      icon: Icons.fact_check,
      child: Row(
        children: [
          ForecastMetricTile(
            label: 'MAPE',
            value: evaluation.hasEnoughData ? '${evaluation.mape.toStringAsFixed(2)}%' : '--',
            subtitle: 'Percentage error',
            color: const Color(0xFF146BFF),
          ),
          const SizedBox(width: 12),
          ForecastMetricTile(
            label: 'MAE',
            value: evaluation.hasEnoughData ? formatAnalyticsNumber(evaluation.mae) : '--',
            subtitle: 'Average absolute error',
            color: const Color(0xFFFF7A1A),
          ),
        ],
      ),
    );
  }
}

class ForecastMetricTile extends StatelessWidget {
  const ForecastMetricTile({super.key, required this.label, required this.value, required this.subtitle, required this.color});

  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withAlpha(22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(56)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Color(0xFF102C44), fontSize: 12, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF7B8FA3), fontSize: 10, height: 1.25)),
          ],
        ),
      ),
    );
  }
}

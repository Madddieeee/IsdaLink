import 'package:flutter/material.dart';

class AnalyticsFooterNote extends StatelessWidget {
  const AnalyticsFooterNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF146BFF).withAlpha(42)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_done, color: Color(0xFF146BFF), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Firebase mode: Analytics use completed COD order records, visible stock records, Simple Moving Average, Seasonal Moving Average, MAPE, and MAE.',
              style: TextStyle(color: Color(0xFF52677A), fontSize: 12, height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

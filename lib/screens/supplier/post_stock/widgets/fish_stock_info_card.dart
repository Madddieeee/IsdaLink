import 'package:flutter/material.dart';

class FishStockInfoCard
    extends
        StatelessWidget {
  const FishStockInfoCard({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFEAF7FB,
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color:
              const Color(
                0xFF146BFF,
              ).withAlpha(
                42,
              ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_done,
            color: Color(
              0xFF146BFF,
            ),
            size: 22,
          ),
          SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              'Firebase mode: New fish stock posts are saved with the current supplier UID.',
              style: TextStyle(
                color: Color(
                  0xFF52677A,
                ),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

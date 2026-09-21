import 'package:flutter/material.dart';

class FishStockInfoCard extends StatelessWidget {
  const FishStockInfoCard({
    super.key,
    required this.productInformationComplete,
    required this.photoComplete,
    required this.priceAndStockComplete,
    required this.listingReady,
  });

  final bool productInformationComplete;
  final bool photoComplete;
  final bool priceAndStockComplete;
  final bool listingReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: listingReady ? const Color(0xFFEDF9F5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: listingReady
              ? const Color(0xFFBCE8D8)
              : const Color(0xFFE1EBF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: listingReady
                      ? const Color(0xFFDDF6EC)
                      : const Color(0xFFEAF7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  listingReady
                      ? Icons.verified_rounded
                      : Icons.fact_check_outlined,
                  color: listingReady
                      ? const Color(0xFF147D64)
                      : const Color(0xFF0875D1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listingReady ? 'Ready to Publish' : 'Before You Publish',
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listingReady
                          ? 'All required details are complete.'
                          : 'Finish the three required parts below.',
                      style: const TextStyle(
                        color: Color(0xFF657C8E),
                        fontSize: 9.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _ReadinessItem(
            label: 'Product details',
            complete: productInformationComplete,
          ),
          const SizedBox(height: 7),
          _ReadinessItem(label: 'Product photo', complete: photoComplete),
          const SizedBox(height: 7),
          _ReadinessItem(
            label: 'Price, stock, and alert',
            complete: priceAndStockComplete,
          ),
        ],
      ),
    );
  }
}

class _ReadinessItem extends StatelessWidget {
  const _ReadinessItem({required this.label, required this.complete});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          complete
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: complete ? const Color(0xFF1DBB8A) : const Color(0xFF9AAEBC),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: complete
                  ? const Color(0xFF102C44)
                  : const Color(0xFF7B8FA3),
              fontSize: 10.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          complete ? 'Done' : 'Required',
          style: TextStyle(
            color: complete
                ? const Color(0xFF147D64)
                : const Color(0xFF8BA0B1),
            fontSize: 8.8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

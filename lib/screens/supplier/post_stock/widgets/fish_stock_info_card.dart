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
      margin: const EdgeInsets.only(
        bottom: 2,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: listingReady
              ? const [
                  Color(0xFFE8F8F2),
                  Color(0xFFEAF8FF),
                ]
              : const [
                  Color(0xFFF2F7FB),
                  Color(0xFFF6F9FB),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: listingReady
              ? const Color(0xFF1DBB8A).withAlpha(85)
              : const Color(0xFFDDE8EF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 41,
                height: 41,
                decoration: BoxDecoration(
                  color: listingReady
                      ? const Color(0xFFDDF6EC)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  listingReady
                      ? Icons.verified_rounded
                      : Icons.fact_check_outlined,
                  color: listingReady
                      ? const Color(0xFF147D64)
                      : const Color(0xFF146BFF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      listingReady
                          ? 'Ready to Publish'
                          : 'Listing Readiness',
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      listingReady
                          ? 'All required listing details are complete.'
                          : 'Complete each section before publishing.',
                      style: const TextStyle(
                        color: Color(0xFF657C8E),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _ReadinessItem(
            label: 'Product information',
            complete: productInformationComplete,
          ),
          const SizedBox(height: 8),
          _ReadinessItem(
            label: 'Product photo',
            complete: photoComplete,
          ),
          const SizedBox(height: 8),
          _ReadinessItem(
            label: 'Price, unit, stock, and alert',
            complete: priceAndStockComplete,
          ),
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              11,
              10,
              11,
              10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(205),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  listingReady
                      ? Icons.cloud_done_rounded
                      : Icons.info_outline_rounded,
                  color: listingReady
                      ? const Color(0xFF147D64)
                      : const Color(0xFF146BFF),
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    listingReady
                        ? 'Publishing will add this listing to your Supplier Dashboard and vendor marketplace.'
                        : 'The Publish button will activate when all required details are complete.',
                    style: const TextStyle(
                      color: Color(0xFF52677A),
                      fontSize: 9.7,
                      height: 1.32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessItem extends StatelessWidget {
  const _ReadinessItem({
    required this.label,
    required this.complete,
  });

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
          color: complete
              ? const Color(0xFF1DBB8A)
              : const Color(0xFF9AAEBC),
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: complete
                  ? const Color(0xFF102C44)
                  : const Color(0xFF7B8FA3),
              fontSize: 10.5,
              fontWeight:
                  complete ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ),
        Text(
          complete ? 'Complete' : 'Required',
          style: TextStyle(
            color: complete
                ? const Color(0xFF147D64)
                : const Color(0xFF8BA0B1),
            fontSize: 8.6,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

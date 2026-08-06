import 'package:flutter/material.dart';

class SupplierOrdersEmptyCard extends StatelessWidget {
  const SupplierOrdersEmptyCard({
    super.key,
    required this.filtered,
    required this.onClearFilters,
  });

  final bool filtered;
  final VoidCallback onClearFilters;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F00152A),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF7FB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              filtered
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              color: const Color(0xFF146BFF),
              size: 32,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            filtered
                ? 'No matching COD orders'
                : 'No incoming COD orders yet',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            filtered
                ? 'Try another vendor or product search, or clear the selected order stage.'
                : 'Vendor COD orders for this supplier account will appear here automatically.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 10.8,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (filtered) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(
                Icons.filter_alt_off_outlined,
                size: 18,
              ),
              label: const Text(
                'Clear Search and Filters',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SupplierOrdersLoadingCard extends StatelessWidget {
  const SupplierOrdersLoadingCard({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Color(0xFF146BFF),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading your incoming COD orders...',
              style: TextStyle(
                color: Color(0xFF52677A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierOrdersErrorCard extends StatelessWidget {
  const SupplierOrdersErrorCard({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFF2C7C5),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFFD94A45),
            size: 39,
          ),
          const SizedBox(height: 9),
          const Text(
            'Unable to load COD orders',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Check your connection and try loading the supplier order queue again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: const Text(
              'Try Again',
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

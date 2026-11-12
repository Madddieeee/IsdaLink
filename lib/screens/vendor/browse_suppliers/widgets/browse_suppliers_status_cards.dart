import 'package:flutter/material.dart';

Widget _supplierIconBuilder(BuildContext context) {
  return const Icon(
    Icons.storefront_rounded,
    color: Color(0xFF0A73D8),
    size: 17,
  );
}

Widget _listingFishIconBuilder(BuildContext context) {
  return Image.asset(
    'assets/images/Fish.png',
    width: 17,
    height: 17,
    fit: BoxFit.contain,
    errorBuilder: (_, _, _) =>
        const Icon(Icons.set_meal_rounded, color: Color(0xFF0875D1), size: 17),
  );
}

Widget _paymentIconBuilder(BuildContext context) {
  return const Icon(
    Icons.account_balance_wallet_rounded,
    color: Color(0xFFE79A13),
    size: 17,
  );
}

class BrowseSuppliersStatusCards extends StatelessWidget {
  const BrowseSuppliersStatusCards({
    super.key,
    required this.supplierCount,
    required this.listingCount,
  });

  final int supplierCount;
  final int listingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BrowseStatusCard(
            value: '$supplierCount',
            label: 'Suppliers',
            iconBuilder: _supplierIconBuilder,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BrowseStatusCard(
            value: '$listingCount',
            label: 'Listings',
            iconBuilder: _listingFishIconBuilder,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _BrowseStatusCard(
            value: 'COD',
            label: 'Payment',
            iconBuilder: _paymentIconBuilder,
          ),
        ),
      ],
    );
  }
}

class _BrowseStatusCard extends StatelessWidget {
  const _BrowseStatusCard({
    required this.value,
    required this.label,
    required this.iconBuilder,
  });

  final String value;
  final String label;
  final WidgetBuilder iconBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9EAF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E063A5A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 28,
            child: Center(child: iconBuilder(context)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF082E50),
                fontSize: 15.5,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF627D92),
                fontSize: 9.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    errorBuilder: (_, _, _) => const Icon(
      Icons.set_meal_rounded,
      color: Color(0xFF0875D1),
      size: 17,
    ),
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
            iconBackground: const Color(0xFFE8F5FC),
            markerColor: const Color(0xFF1FAF78),
            markerIcon: Icons.verified_rounded,
            iconBuilder: _supplierIconBuilder,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _BrowseStatusCard(
            value: '$listingCount',
            label: 'Listings',
            iconBackground: const Color(0xFFEAF5FD),
            markerColor: const Color(0xFF39A7D8),
            markerIcon: Icons.list_alt_rounded,
            iconBuilder: _listingFishIconBuilder,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: _BrowseStatusCard(
            value: 'COD',
            label: 'Payment',
            iconBackground: Color(0xFFFFF4DB),
            markerColor: Color(0xFFF3B33D),
            markerIcon: Icons.local_shipping_rounded,
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
    required this.iconBackground,
    required this.markerColor,
    required this.markerIcon,
  });

  final String value;
  final String label;
  final WidgetBuilder iconBuilder;
  final Color iconBackground;
  final Color markerColor;
  final IconData markerIcon;

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
            width: 36,
            height: 33,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: iconBuilder(context),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE4EEF5)),
                    ),
                    child: Icon(markerIcon, color: markerColor, size: 10),
                  ),
                ),
              ],
            ),
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

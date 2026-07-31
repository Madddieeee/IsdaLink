import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/services/supplier_details_service.dart';

class SupplierDetailsHeader extends StatelessWidget {
  const SupplierDetailsHeader({
    super.key,
    required this.supplier,
    required this.stats,
    required this.onBack,
  });

  final Supplier supplier;
  final SupplierDetailsStats stats;
  final VoidCallback onBack;

  bool get hasNetworkImage {
    final imageUrl = supplier.profileImageUrl.trim();

    return imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');
  }

  String get storeInitial {
    final name = supplier.name.trim();

    if (name.isEmpty) {
      return 'S';
    }

    return name.substring(0, 1).toUpperCase();
  }

  Widget storePhoto() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 13,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: hasNetworkImage
            ? Image.network(
                supplier.profileImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (
                  context,
                  child,
                  loadingProgress,
                ) {
                  if (loadingProgress == null) {
                    return child;
                  }

                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, _, _) {
                  return StoreInitial(
                    initial: storeInitial,
                  );
                },
              )
            : StoreInitial(
                initial: storeInitial,
              ),
      ),
    );
  }

  Widget headerChip({
    required IconData icon,
    required String text,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    final foreground = foregroundColor ?? Colors.white;
    final background =
        backgroundColor ?? Colors.white.withAlpha(34);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: foreground.withAlpha(40),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: foreground,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontSize: 9.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget statItem({
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 8.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget ratingLine() {
    if (supplier.rating <= 0 || supplier.reviews <= 0) {
      return const Row(
        children: [
          Icon(
            Icons.star_border_rounded,
            color: Color(0xFFFFD166),
            size: 15,
          ),
          SizedBox(width: 4),
          Text(
            'No reviews yet',
            style: TextStyle(
              color: Color(0xFFEAF5FB),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(
          Icons.star_rounded,
          color: Color(0xFFFFD166),
          size: 15,
        ),
        const SizedBox(width: 4),
        Text(
          '${supplier.rating.toStringAsFixed(1)} from '
          '${supplier.reviews} review'
          '${supplier.reviews == 1 ? '' : 's'}',
          style: const TextStyle(
            color: Color(0xFFEAF5FB),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final description = supplier.description.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        48,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF074F83),
            Color(0xFF087AC0),
            Color(0xFF11B8D5),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -55,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -55,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(16),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.white.withAlpha(36),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onBack,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'Supplier Store',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  headerChip(
                    icon: Icons.verified_rounded,
                    text: 'Verified',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  storePhoto(),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFEAF5FB),
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                supplier.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFEAF5FB),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ratingLine(),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            headerChip(
                              icon: Icons.payments_outlined,
                              text: 'COD only',
                            ),
                            headerChip(
                              icon: Icons.set_meal_outlined,
                              text: 'Fish supplier',
                            ),
                            if (supplier.isNewSupplier)
                              headerChip(
                                icon: Icons.auto_awesome_rounded,
                                text: 'New supplier',
                                foregroundColor:
                                    const Color(0xFF8A4D00),
                                backgroundColor:
                                    const Color(0xFFFFE29A),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 13),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFEAF5FB),
                    fontSize: 10.7,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    statItem(
                      value: '${stats.totalListings}',
                      label: 'Fish listings',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFDDEAF1),
                    ),
                    statItem(
                      value: '${stats.availableListings}',
                      label: 'Available now',
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: const Color(0xFFDDEAF1),
                    ),
                    statItem(
                      value: '${supplier.reviews}',
                      label: 'Store reviews',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StoreInitial extends StatelessWidget {
  const StoreInitial({
    super.key,
    required this.initial,
  });

  final String initial;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color: const Color(0xFFEAF8FC),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF087AC0),
          fontSize: 29,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

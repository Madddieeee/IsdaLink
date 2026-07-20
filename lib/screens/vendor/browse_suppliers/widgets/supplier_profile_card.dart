import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';

class SupplierProfileCard extends StatelessWidget {
  const SupplierProfileCard({
    super.key,
    required this.supplier,
    required this.paymentMethod,
    required this.status,
    required this.onTap,
  });

  final Supplier supplier;
  final String paymentMethod;
  final String status;
  final VoidCallback onTap;

  bool get hasProfileImage {
    return supplier.profileImageUrl.trim().isNotEmpty &&
        (supplier.profileImageUrl.startsWith('http://') ||
            supplier.profileImageUrl.startsWith('https://'));
  }

  Widget supplierAvatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 70,
        height: 70,
        color: const Color(0xFFEAF7FB),
        child: hasProfileImage
            ? Image.network(
                supplier.profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      '🐟',
                      style: TextStyle(
                        fontSize: 34,
                      ),
                    ),
                  );
                },
              )
            : const Center(
                child: Text(
                  '🐟',
                  style: TextStyle(
                    fontSize: 34,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final statusLabel =
        status.toLowerCase() == 'approved' ? 'APPROVED' : status.toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 96,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF102C44),
                    Color(0xFF146BFF),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -26,
                    top: -28,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(28),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: -28,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7FB),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: supplierAvatar(),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(42),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Color(0xFFFFB703),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 36, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF7B8FA3),
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          supplier.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    supplier.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF52677A),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7FB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.cloud_done,
                              color: Color(0xFF146BFF),
                              size: 15,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Firebase',
                              style: TextStyle(
                                color: Color(0xFF146BFF),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          paymentMethod,
                          style: const TextStyle(
                            color: Color(0xFFFF7A1A),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFB703),
                            size: 17,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            supplier.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${supplier.reviews})',
                            style: const TextStyle(
                              color: Color(0xFF7B8FA3),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

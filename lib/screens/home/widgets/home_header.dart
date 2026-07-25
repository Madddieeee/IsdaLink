import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onLogout,
    required this.onSearchTap,
    required this.onProfileTap,
  });

  final VoidCallback onLogout;
  final VoidCallback onSearchTap;
  final VoidCallback onProfileTap;

  Widget userHeaderInfo() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const HomeUserText(
        name: 'Guest User',
        subtitle: 'Find fresh fish stocks and trusted suppliers.',
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final fallbackName = currentUser.displayName?.trim().isNotEmpty == true
            ? currentUser.displayName!.trim()
            : 'IsdaLink User';

        final name = data == null
            ? fallbackName
            : OrderHelpers.getStringValue(
                data,
                'name',
                fallbackName,
              );

        final role = data == null
            ? 'vendor'
            : OrderHelpers.getStringValue(
                data,
                'role',
                'vendor',
              ).toLowerCase();

        final supplierStatus = data == null
            ? 'not_applicable'
            : OrderHelpers.getStringValue(
                data,
                'supplierStatus',
                'not_applicable',
              ).toLowerCase();

        final isSupplier = role == 'supplier' || supplierStatus == 'approved';

        return HomeUserText(
          name: name.isEmpty ? 'IsdaLink User' : name,
          subtitle: isSupplier
              ? 'Manage fish stocks, COD orders, and market insights.'
              : 'Find fresh fish stocks and trusted suppliers near you.',
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 50, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF063B5C),
            Color(0xFF087AC0),
            Color(0xFF10B7D4),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: 14,
            child: SeaBubble(
              size: 112,
              opacity: 32,
            ),
          ),
          Positioned(
            left: -46,
            bottom: 36,
            child: SeaBubble(
              size: 90,
              opacity: 24,
            ),
          ),
          Positioned(
            right: 54,
            bottom: -44,
            child: SeaBubble(
              size: 96,
              opacity: 22,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'ISDALINK',
                    style: TextStyle(
                      color: Color(0xFFE6F9FF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(42),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withAlpha(34),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Caraga Region',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  HeaderCircleButton(
                    icon: Icons.person,
                    onTap: onProfileTap,
                  ),
                  const SizedBox(width: 8),
                  HeaderCircleButton(
                    icon: Icons.logout,
                    onTap: onLogout,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              userHeaderInfo(),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onSearchTap,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Color(0xFF6B8CA3),
                        size: 21,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Search fish, suppliers, or locations...',
                          style: TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.set_meal,
                        color: Color(0xFF10B7D4),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  HomeInfoChip(
                    icon: Icons.verified,
                    label: 'Verified suppliers',
                  ),
                  SizedBox(width: 8),
                  HomeInfoChip(
                    icon: Icons.payments,
                    label: 'COD only',
                  ),
                  SizedBox(width: 8),
                  HomeInfoChip(
                    icon: Icons.waves,
                    label: 'Fresh stocks',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeUserText extends StatelessWidget {
  const HomeUserText({
    super.key,
    required this.name,
    required this.subtitle,
  });

  final String name;
  final String subtitle;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFE2F7FF),
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class HeaderCircleButton extends StatelessWidget {
  const HeaderCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(42),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withAlpha(34),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class HomeInfoChip extends StatelessWidget {
  const HomeInfoChip({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withAlpha(26),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeaBubble extends StatelessWidget {
  const SeaBubble({
    super.key,
    required this.size,
    required this.opacity,
  });

  final double size;
  final int opacity;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

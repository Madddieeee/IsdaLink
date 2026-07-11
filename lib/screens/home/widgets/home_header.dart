import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/utils/order_helpers.dart';

class HomeHeader
    extends
        StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onLogout,
    required this.onSearchTap,
  });

  final VoidCallback onLogout;
  final VoidCallback onSearchTap;

  Widget userHeaderInfo() {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser ==
        null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guest User',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          Text(
            'Find fresh fish stocks and trusted suppliers.',
            style: TextStyle(
              color: Color(
                0xFFDCE9F5,
              ),
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return StreamBuilder<
      DocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >(
      stream: FirebaseFirestore.instance
          .collection(
            'users',
          )
          .doc(
            currentUser.uid,
          )
          .snapshots(),
      builder:
          (
            context,
            snapshot,
          ) {
            final data = snapshot.data?.data();

            final fallbackName =
                currentUser.displayName?.trim().isNotEmpty ==
                    true
                ? currentUser.displayName!.trim()
                : 'IsdaLink User';

            final name =
                data ==
                    null
                ? fallbackName
                : OrderHelpers.getStringValue(
                    data,
                    'name',
                    fallbackName,
                  );

            final role =
                data ==
                    null
                ? 'vendor'
                : OrderHelpers.getStringValue(
                    data,
                    'role',
                    'vendor',
                  ).toLowerCase();

            final subtitle =
                role ==
                    'supplier'
                ? 'Manage fish stocks and coordinate COD orders.'
                : 'Find fresh fish stocks and trusted suppliers.';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty
                      ? 'IsdaLink User'
                      : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(
                      0xFFDCE9F5,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            );
          },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        56,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(
              0xFF102C44,
            ),
            Color(
              0xFF146BFF,
            ),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(
            32,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ISDALINK',
                style: TextStyle(
                  color: Color(
                    0xFFBFD1E3,
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(
                    41,
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Text(
                      'Caraga Region',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              GestureDetector(
                onTap: onLogout,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(
                      41,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          userHeaderInfo(),
          const SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  18,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(
                      0x22000000,
                    ),
                    blurRadius: 12,
                    offset: Offset(
                      0,
                      6,
                    ),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Color(
                      0xFF7B8FA3,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      'Search fish, suppliers, or locations...',
                      style: TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

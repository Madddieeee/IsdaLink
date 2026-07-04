import 'package:flutter/material.dart';

import '../supplier/supplier_activation_screen.dart';
import '../supplier/supplier_dashboard_screen.dart';
import '../welcome_screen.dart';

class MeScreen
    extends
        StatelessWidget {
  const MeScreen({
    super.key,
  });

  void openSupplierActivation(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const SupplierActivationScreen(),
      ),
    );
  }

  void openSupplierDashboard(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const SupplierDashboardScreen(),
      ),
    );
  }

  void logout(
    BuildContext context,
  ) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const WelcomeScreen(),
      ),
      (
        route,
      ) => false,
    );
  }

  Widget menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(
      0xFF146BFF,
    ),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 14,
        ),
        padding: const EdgeInsets.all(
          16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            22,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x12000000,
              ),
              blurRadius: 14,
              offset: Offset(
                0,
                7,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(
                  25,
                ),
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(
              width: 14,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(
                0xFF9AAABD,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileStatusCard() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
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
        children: [
          Icon(
            Icons.info,
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
              'Offline/sample mode: Supplier status is for prototype testing. Real activation will be stored in the database later.',
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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              54,
              20,
              28,
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
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(
                        context,
                      ),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(
                            38,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Expanded(
                      child: Text(
                        'Me',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 26,
                ),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      28,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(
                          0x22000000,
                        ),
                        blurRadius: 16,
                        offset: Offset(
                          0,
                          8,
                        ),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(
                      0xFF146BFF,
                    ),
                    size: 46,
                  ),
                ),
                const SizedBox(
                  height: 14,
                ),
                const Text(
                  'Juan Dela Cruz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                const Text(
                  'Vendor Account • Caraga Region',
                  style: TextStyle(
                    color: Color(
                      0xFFDCE9F5,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(
                18,
              ),
              children: [
                profileStatusCard(),
                menuTile(
                  icon: Icons.dashboard_customize,
                  title: 'Supplier Dashboard',
                  subtitle: 'Open supplier tools for stocks, COD orders, and analytics.',
                  iconColor: const Color(
                    0xFF7B61FF,
                  ),
                  onTap: () => openSupplierDashboard(
                    context,
                  ),
                ),
                menuTile(
                  icon: Icons.inventory_2,
                  title: 'Become a Supplier',
                  subtitle: 'Activate supplier features for inventory posting.',
                  onTap: () => openSupplierActivation(
                    context,
                  ),
                ),
                menuTile(
                  icon: Icons.person_outline,
                  title: 'Account Information',
                  subtitle: 'View or update your profile information.',
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Account information coming soon',
                        ),
                      ),
                    );
                  },
                ),
                menuTile(
                  icon: Icons.location_on_outlined,
                  title: 'Region and Location',
                  subtitle: 'Manage your market location and service area.',
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Location settings coming soon',
                        ),
                      ),
                    );
                  },
                ),
                menuTile(
                  icon: Icons.help_outline,
                  title: 'Help and Support',
                  subtitle: 'Get help using IsdaLink features.',
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Help and support coming soon',
                        ),
                      ),
                    );
                  },
                ),
                menuTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: 'Return to the welcome screen.',
                  iconColor: const Color(
                    0xFFD32F2F,
                  ),
                  onTap: () => logout(
                    context,
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

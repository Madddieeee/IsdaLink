import 'package:flutter/material.dart';
import 'package:isdalink/core/app_colors.dart';
import 'package:isdalink/screens/vendor/browse_suppliers_screen.dart';
import 'package:isdalink/screens/welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  void openBrowseSuppliers(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BrowseSuppliersScreen()),
    );
  }

  void showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature coming next')));
  }

  Widget dashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.blue, size: 34),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        title: const Text('IsdaLink Dashboard'),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Hello, Vendor!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage fish orders, suppliers, and sales analytics.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            dashboardCard(
              icon: Icons.store,
              title: 'Browse Suppliers',
              subtitle: 'Find registered fish suppliers and available stocks.',
              onTap: () => openBrowseSuppliers(context),
            ),
            dashboardCard(
              icon: Icons.shopping_cart,
              title: 'My Orders',
              subtitle: 'View order history and COD payment status.',
              onTap: () => showComingSoon(context, 'My Orders'),
            ),
            dashboardCard(
              icon: Icons.inventory,
              title: 'Become a Supplier',
              subtitle: 'Activate supplier features for inventory posting.',
              onTap: () => showComingSoon(context, 'Supplier Activation'),
            ),
            dashboardCard(
              icon: Icons.bar_chart,
              title: 'Sales Analytics',
              subtitle: 'View demand trends and restocking suggestions.',
              onTap: () => showComingSoon(context, 'Sales Analytics'),
            ),
          ],
        ),
      ),
    );
  }
}

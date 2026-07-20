import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/profile/manage_profile_screen.dart';
import 'package:isdalink/screens/profile/widgets/me_header.dart';
import 'package:isdalink/screens/profile/widgets/me_loading_body.dart';
import 'package:isdalink/screens/profile/widgets/me_menu_tile.dart';
import 'package:isdalink/screens/profile/widgets/profile_status_card.dart';
import 'package:isdalink/screens/supplier/supplier_activation_screen.dart';
import 'package:isdalink/screens/supplier/supplier_dashboard_screen.dart';
import 'package:isdalink/screens/welcome_screen.dart';
import 'package:isdalink/services/user_profile_service.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({
    super.key,
  });

  UserProfileService get profileService => const UserProfileService();

  void showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
      ),
    );
  }

  void openSupplierDashboard(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupplierDashboardScreen(),
      ),
    );
  }

  void openSupplierApplication(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupplierActivationScreen(),
      ),
    );
  }

  void openManageProfile(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context).clearSnackBars();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManageProfileScreen(),
      ),
    );
  }

  Future<void> logout(
    BuildContext context,
  ) async {
    await profileService.logout();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  Widget bodyContent(
    BuildContext context,
    Map<String, dynamic>? profileData,
  ) {
    final user = profileService.currentUser;

    final fallbackName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'IsdaLink User';

    final name = profileService.getStringValue(
      profileData,
      'name',
      fallbackName,
    );

    final role = profileService
        .getStringValue(
          profileData,
          'role',
          'vendor',
        )
        .toLowerCase();

    final supplierStatus = profileService
        .getStringValue(
          profileData,
          'supplierStatus',
          'not_applicable',
        )
        .toLowerCase();

    final canOpenSupplierDashboard =
        role == 'supplier' || supplierStatus == 'approved';

    final isPendingSupplier = supplierStatus == 'pending';

    return Column(
      children: [
        MeHeader(
          name: name,
          supplierStatus: supplierStatus,
          onBack: () => Navigator.pop(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              ProfileStatusCard(
                supplierStatus: supplierStatus,
              ),
              if (canOpenSupplierDashboard)
                MeMenuTile(
                  icon: Icons.dashboard_customize,
                  title: 'Supplier Dashboard',
                  subtitle:
                      'Open approved supplier tools for stocks, COD orders, and analytics.',
                  iconColor: const Color(0xFF7B61FF),
                  onTap: () => openSupplierDashboard(context),
                )
              else if (isPendingSupplier)
                MeMenuTile(
                  icon: Icons.hourglass_top,
                  title: 'Supplier Application Pending',
                  subtitle:
                      'Admin approval is required before supplier tools become available.',
                  iconColor: const Color(0xFFFF7A1A),
                  onTap: () {
                    showMessage(
                      context,
                      'Your supplier application is still pending admin approval.',
                      isError: true,
                    );
                  },
                )
              else
                MeMenuTile(
                  icon: Icons.inventory_2,
                  title: 'Become a Supplier',
                  subtitle: 'Submit store details for admin approval.',
                  onTap: () => openSupplierApplication(context),
                ),
              MeMenuTile(
                icon: Icons.person_outline,
                title: 'Account Information',
                subtitle: 'View or update your profile information.',
                onTap: () => openManageProfile(context),
              ),
              MeMenuTile(
                icon: Icons.location_on_outlined,
                title: 'Region and Location',
                subtitle: 'Manage your market location and service area.',
                onTap: () => openManageProfile(context),
              ),
              MeMenuTile(
                icon: Icons.help_outline,
                title: 'Help and Support',
                subtitle: 'Get help using IsdaLink features.',
                onTap: () {
                  showMessage(
                    context,
                    'Help and support coming soon',
                  );
                },
              ),
              MeMenuTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Return to the welcome screen.',
                iconColor: const Color(0xFFD32F2F),
                onTap: () => logout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final stream = profileService.profileStream();

    if (stream == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        body: bodyContent(
          context,
          null,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const MeLoadingBody();
          }

          return bodyContent(
            context,
            snapshot.data?.data(),
          );
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'package:isdalink/screens/profile/manage_profile_screen.dart';
import 'package:isdalink/screens/supplier/post_fish_stock_screen.dart';
import 'package:isdalink/screens/supplier/supplier_activation_screen.dart';
import 'package:isdalink/screens/supplier/supplier_cod_orders_screen.dart';
import 'package:isdalink/screens/supplier/supplier_dashboard_screen.dart';
import 'package:isdalink/screens/supplier/supplier_manage_products_screen.dart';
import 'package:isdalink/screens/vendor/browse_suppliers_screen.dart';
import 'package:isdalink/screens/vendor/my_orders_screen.dart';
import 'package:isdalink/screens/welcome_screen.dart';
import 'package:isdalink/services/user_profile_service.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({
    super.key,
  });

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final UserProfileService profileService = const UserProfileService();

  bool approvalDialogScheduled = false;

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

  void openScreen(
    BuildContext context,
    Widget screen,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  void openSupplierDashboard(
    BuildContext context,
  ) {
    openScreen(
      context,
      const SupplierDashboardScreen(),
    );
  }

  void openSupplierApplication(
    BuildContext context,
  ) {
    openScreen(
      context,
      const SupplierActivationScreen(),
    );
  }

  void openManageProfile(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context).clearSnackBars();

    openScreen(
      context,
      const ManageProfileScreen(),
    );
  }

  Future<void> markSupplierApprovalSeen() async {
    final user = profileService.currentUser;

    if (user == null) {
      return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {
        'supplierApprovalSeen': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  void maybeShowSupplierApprovalDialog(
    Map<String, dynamic>? profileData,
  ) {
    if (profileData == null || approvalDialogScheduled) {
      return;
    }

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

    final isApprovedSupplier =
        role == 'supplier' || supplierStatus == 'approved';

    final approvalAlreadySeen = profileData['supplierApprovalSeen'] == true;

    if (!isApprovedSupplier || approvalAlreadySeen) {
      return;
    }

    approvalDialogScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        if (!mounted) {
          return;
        }

        await markSupplierApprovalSeen();

        if (!mounted) {
          return;
        }

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 28,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2E7D32),
                            Color(0xFF146BFF),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Congratulations!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'You are now an approved IsdaLink fish supplier.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF146BFF),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Your supplier account has been verified. You can now post fish stocks, manage products, track COD orders, and view supplier sales analytics.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF52677A),
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7FB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF146BFF).withAlpha(40),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.home_outlined,
                            color: Color(0xFF146BFF),
                            size: 20,
                          ),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'You will still start from the main home screen. Open Supplier Dashboard anytime from your profile.',
                              style: TextStyle(
                                color: Color(0xFF52677A),
                                fontSize: 11.5,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF146BFF),
                              side: const BorderSide(
                                color: Color(0xFF146BFF),
                              ),
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Later',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              openSupplierDashboard(context);
                            },
                            icon: const Icon(
                              Icons.dashboard_customize,
                              size: 18,
                            ),
                            label: const Text(
                              'Start Selling',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF146BFF),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  Widget dashboardHeader({
    required String name,
    required String email,
    required String location,
    required String supplierStatus,
    required bool canOpenSupplierDashboard,
    required bool isPendingSupplier,
    required bool isRejectedSupplier,
  }) {
    final accountLabel = canOpenSupplierDashboard
        ? 'Approved Supplier'
        : isPendingSupplier
            ? 'Pending Review'
            : isRejectedSupplier
                ? 'Application Rejected'
                : 'Vendor Account';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 48, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102C44),
            Color(0xFF146BFF),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: canOpenSupplierDashboard
                      ? () => openSupplierDashboard(context)
                      : () => openSupplierApplication(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          canOpenSupplierDashboard
                              ? Icons.storefront
                              : Icons.store_mall_directory,
                          color: const Color(0xFF102C44),
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          canOpenSupplierDashboard
                              ? 'Supplier Center'
                              : 'Start Selling',
                          style: const TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF102C44),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              HeaderIconButton(
                icon: Icons.settings,
                onTap: () => openManageProfile(context),
              ),
              const SizedBox(width: 9),
              HeaderIconButton(
                icon: Icons.logout,
                onTap: () => logout(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 14,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: Icon(
                  canOpenSupplierDashboard ? Icons.storefront : Icons.person,
                  color: const Color(0xFF146BFF),
                  size: 42,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFDCE9F5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        HeaderBadge(
                          icon: canOpenSupplierDashboard
                              ? Icons.verified
                              : Icons.person,
                          label: accountLabel,
                        ),
                        HeaderBadge(
                          icon: Icons.location_on,
                          label: location,
                        ),
                      ],
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

  Widget supplierStatusBanner(
    String supplierStatus,
  ) {
    final isPending = supplierStatus == 'pending';
    final isRejected = supplierStatus == 'rejected';

    if (!isPending && !isRejected) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending
            ? const Color(0xFFFFF8E8)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? const Color(0xFFFFB703).withAlpha(80)
              : const Color(0xFFD32F2F).withAlpha(60),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPending ? Icons.hourglass_top : Icons.info_outline,
            color: isPending
                ? const Color(0xFFFF7A1A)
                : const Color(0xFFD32F2F),
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isPending
                  ? 'Your supplier application is under admin review.'
                  : 'Your supplier application was rejected. You may review your details and apply again.',
              style: const TextStyle(
                color: Color(0xFF52677A),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget purchaseSection(
    String uid,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where(
            'vendorId',
            isEqualTo: uid,
          )
          .snapshots(),
      builder: (context, snapshot) {
        final documents = snapshot.data?.docs ?? [];

        final toPay = documents.where(
          (document) {
            final data = document.data();

            final orderStatus = (data['orderStatus'] ?? '')
                .toString()
                .toLowerCase();

            final paymentStatus = (data['paymentStatus'] ?? '')
                .toString()
                .toLowerCase();

            return orderStatus == 'pending' ||
                paymentStatus.contains('to be paid');
          },
        ).length;

        final accepted = documents.where(
          (document) {
            final status = (document.data()['orderStatus'] ?? '')
                .toString()
                .toLowerCase();

            return status == 'accepted';
          },
        ).length;

        final delivered = documents.where(
          (document) {
            final status = (document.data()['orderStatus'] ?? '')
                .toString()
                .toLowerCase();

            return status == 'delivered' || status == 'completed';
          },
        ).length;

        final toRate = documents.where(
          (document) {
            final data = document.data();

            final status = (data['orderStatus'] ?? '')
                .toString()
                .toLowerCase();

            final reviewed = data['reviewSubmitted'] == true;

            return (status == 'delivered' || status == 'completed') &&
                !reviewed;
          },
        ).length;

        return WhiteSectionCard(
          title: 'My Purchases',
          actionLabel: 'View Purchase History',
          onActionTap: () => openScreen(
            context,
            const MyOrdersScreen(),
          ),
          child: Row(
            children: [
              Expanded(
                child: StatusShortcut(
                  icon: Icons.payments_outlined,
                  label: 'To Pay',
                  count: toPay,
                  onTap: () => openScreen(
                    context,
                    const MyOrdersScreen(),
                  ),
                ),
              ),
              Expanded(
                child: StatusShortcut(
                  icon: Icons.inventory_2_outlined,
                  label: 'Accepted',
                  count: accepted,
                  onTap: () => openScreen(
                    context,
                    const MyOrdersScreen(),
                  ),
                ),
              ),
              Expanded(
                child: StatusShortcut(
                  icon: Icons.local_shipping_outlined,
                  label: 'Delivered',
                  count: delivered,
                  onTap: () => openScreen(
                    context,
                    const MyOrdersScreen(),
                  ),
                ),
              ),
              Expanded(
                child: StatusShortcut(
                  icon: Icons.star_border,
                  label: 'To Rate',
                  count: toRate,
                  onTap: () => openScreen(
                    context,
                    const MyOrdersScreen(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget supplierSection({
    required String uid,
    required bool canOpenSupplierDashboard,
    required bool isPendingSupplier,
    required bool isRejectedSupplier,
  }) {
    if (canOpenSupplierDashboard) {
      return WhiteSectionCard(
        title: 'Supplier Center',
        actionLabel: 'Open Dashboard',
        onActionTap: () => openSupplierDashboard(context),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SupplierToolShortcut(
                    icon: Icons.add_box_outlined,
                    label: 'Post Stock',
                    onTap: () => openScreen(
                      context,
                      const PostFishStockScreen(),
                    ),
                  ),
                ),
                Expanded(
                  child: SupplierToolShortcut(
                    icon: Icons.inventory_outlined,
                    label: 'Products',
                    onTap: () => openScreen(
                      context,
                      const SupplierManageProductsScreen(),
                    ),
                  ),
                ),
                Expanded(
                  child: SupplierToolShortcut(
                    icon: Icons.receipt_long_outlined,
                    label: 'COD Orders',
                    onTap: () => openScreen(
                      context,
                      const SupplierCodOrdersScreen(),
                    ),
                  ),
                ),
                Expanded(
                  child: SupplierToolShortcut(
                    icon: Icons.bar_chart,
                    label: 'Analytics',
                    onTap: () => openScreen(
                      context,
                      const AnalyticsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SupplierMiniStats(
              uid: uid,
            ),
          ],
        ),
      );
    }

    return WhiteSectionCard(
      title: 'Supplier Application',
      actionLabel: isPendingSupplier ? 'Pending' : 'Apply',
      onActionTap: isPendingSupplier
          ? () {
              showMessage(
                context,
                'Your supplier application is still pending admin review.',
                isError: true,
              );
            }
          : () => openSupplierApplication(context),
      child: ApplySupplierCard(
        isPendingSupplier: isPendingSupplier,
        isRejectedSupplier: isRejectedSupplier,
        onTap: isPendingSupplier
            ? () {
                showMessage(
                  context,
                  'Your supplier application is still pending admin review.',
                  isError: true,
                );
              }
            : () => openSupplierApplication(context),
      ),
    );
  }

  Widget fishMarketToolsSection() {
    return WhiteSectionCard(
      title: 'Fish Market Tools',
      child: Row(
        children: [
          Expanded(
            child: SupplierToolShortcut(
              icon: Icons.storefront,
              label: 'Browse',
              onTap: () => openScreen(
                context,
                const BrowseSuppliersScreen(),
              ),
            ),
          ),
          Expanded(
            child: SupplierToolShortcut(
              icon: Icons.receipt_long,
              label: 'Orders',
              onTap: () => openScreen(
                context,
                const MyOrdersScreen(),
              ),
            ),
          ),
          Expanded(
            child: SupplierToolShortcut(
              icon: Icons.analytics,
              label: 'Analytics',
              onTap: () => openScreen(
                context,
                const AnalyticsScreen(),
              ),
            ),
          ),
          Expanded(
            child: SupplierToolShortcut(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => openManageProfile(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget accountSettingsSection() {
    return WhiteSectionCard(
      title: 'Account Settings',
      child: Column(
        children: [
          SettingsRow(
            icon: Icons.person_outline,
            title: 'Account Information',
            subtitle: 'Update profile and contact number',
            onTap: () => openManageProfile(context),
          ),
          SettingsRow(
            icon: Icons.location_on_outlined,
            title: 'Region and Location',
            subtitle: 'Manage market location and service area',
            onTap: () => openManageProfile(context),
          ),
          SettingsRow(
            icon: Icons.help_outline,
            title: 'Help and Support',
            subtitle: 'Get help using IsdaLink features',
            onTap: () {
              showMessage(
                context,
                'Help and support coming soon',
              );
            },
          ),
          SettingsRow(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Return to welcome screen',
            iconColor: const Color(0xFFD32F2F),
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }

  Widget bodyContent(
    Map<String, dynamic>? profileData,
  ) {
    maybeShowSupplierApprovalDialog(profileData);

    final user = profileService.currentUser;
    final uid = user?.uid ?? '';

    final fallbackName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'IsdaLink User';

    final name = profileService.getStringValue(
      profileData,
      'name',
      fallbackName,
    );

    final email = profileService.getStringValue(
      profileData,
      'email',
      user?.email ?? 'No email',
    );

    final location = profileService.getStringValue(
      profileData,
      'region',
      profileService.getStringValue(
        profileData,
        'location',
        'Caraga Region',
      ),
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
    final isRejectedSupplier = supplierStatus == 'rejected';

    return Column(
      children: [
        dashboardHeader(
          name: name,
          email: email,
          location: location,
          supplierStatus: supplierStatus,
          canOpenSupplierDashboard: canOpenSupplierDashboard,
          isPendingSupplier: isPendingSupplier,
          isRejectedSupplier: isRejectedSupplier,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              supplierStatusBanner(
                supplierStatus,
              ),
              if (uid.isNotEmpty)
                purchaseSection(
                  uid,
                ),
              if (uid.isNotEmpty)
                supplierSection(
                  uid: uid,
                  canOpenSupplierDashboard: canOpenSupplierDashboard,
                  isPendingSupplier: isPendingSupplier,
                  isRejectedSupplier: isRejectedSupplier,
                ),
              fishMarketToolsSection(),
              accountSettingsSection(),
              const SizedBox(height: 22),
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return bodyContent(
            snapshot.data?.data(),
          );
        },
      ),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(38),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class HeaderBadge extends StatelessWidget {
  const HeaderBadge({
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(42),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withAlpha(34),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFFFFB703),
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class WhiteSectionCard extends StatelessWidget {
  const WhiteSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (actionLabel != null)
                GestureDetector(
                  onTap: onActionTap,
                  child: Row(
                    children: [
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          color: Color(0xFF52677A),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9AADBC),
                        size: 18,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class StatusShortcut extends StatelessWidget {
  const StatusShortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              Icon(
                icon,
                color: const Color(0xFF102C44),
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF52677A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (count > 0)
            Positioned(
              top: -7,
              right: 18,
              child: CountBadge(
                count: count,
              ),
            ),
        ],
      ),
    );
  }
}

class SupplierToolShortcut extends StatelessWidget {
  const SupplierToolShortcut({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF146BFF),
              size: 25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF52677A),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 21,
      ),
      height: 21,
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D2D),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class ApplySupplierCard extends StatelessWidget {
  const ApplySupplierCard({
    super.key,
    required this.isPendingSupplier,
    required this.isRejectedSupplier,
    required this.onTap,
  });

  final bool isPendingSupplier;
  final bool isRejectedSupplier;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final title = isPendingSupplier
        ? 'Application Under Review'
        : isRejectedSupplier
            ? 'Apply Again as Supplier'
            : 'Start Selling on IsdaLink';

    final subtitle = isPendingSupplier
        ? 'Admin is checking your store and verification details.'
        : 'Submit owner, store, supported unit, permit, and store photo details.';

    final buttonText = isPendingSupplier
        ? 'Pending'
        : isRejectedSupplier
            ? 'Apply Again'
            : 'Apply Now';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102C44),
            Color(0xFF146BFF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.storefront,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFDCE9F5),
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF146BFF),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierMiniStats extends StatelessWidget {
  const SupplierMiniStats({
    super.key,
    required this.uid,
  });

  final String uid;

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('fishStocks')
          .where(
            'supplierId',
            isEqualTo: uid,
          )
          .snapshots(),
      builder: (context, stockSnapshot) {
        final stocks = stockSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where(
                'supplierId',
                isEqualTo: uid,
              )
              .snapshots(),
          builder: (context, orderSnapshot) {
            final orders = orderSnapshot.data?.docs ?? [];

            final activeStocks = stocks.where(
              (document) {
                final status = (document.data()['status'] ?? '')
                    .toString()
                    .toLowerCase();

                return status != 'unavailable';
              },
            ).length;

            final activeOrders = orders.where(
              (document) {
                final status = (document.data()['orderStatus'] ?? '')
                    .toString()
                    .toLowerCase();

                return status == 'pending' || status == 'accepted';
              },
            ).length;

            final deliveredOrders = orders.where(
              (document) {
                final status = (document.data()['orderStatus'] ?? '')
                    .toString()
                    .toLowerCase();

                return status == 'delivered' || status == 'completed';
              },
            ).length;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F8FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: MiniMetric(
                      label: 'Stocks',
                      value: '$activeStocks',
                    ),
                  ),
                  Expanded(
                    child: MiniMetric(
                      label: 'Active COD',
                      value: '$activeOrders',
                    ),
                  ),
                  Expanded(
                    child: MiniMetric(
                      label: 'Delivered',
                      value: '$deliveredOrders',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class MiniMetric extends StatelessWidget {
  const MiniMetric({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF102C44),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF7B8FA3),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = const Color(0xFF146BFF),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 9,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor == const Color(0xFFD32F2F)
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFEAF7FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF102C44),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7B8FA3),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9AADBC),
              size: 21,
            ),
          ],
        ),
      ),
    );
  }
}

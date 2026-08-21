import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/admin/widgets/admin_change_request_card.dart';
import 'package:isdalink/screens/admin/supplier_change_request_review_screen.dart';
import 'package:isdalink/screens/admin/widgets/admin_dashboard_header.dart';
import 'package:isdalink/screens/admin/widgets/admin_overview_card.dart';
import 'package:isdalink/screens/admin/widgets/admin_section_title.dart';
import 'package:isdalink/screens/admin/widgets/admin_status_cards.dart';
import 'package:isdalink/screens/admin/widgets/admin_supplier_cards.dart';
import 'package:isdalink/screens/welcome_screen.dart';
import 'package:isdalink/services/admin_dashboard_service.dart';

class AdminDashboardScreen
    extends
        StatelessWidget {
  const AdminDashboardScreen({
    super.key,
  });

  AdminDashboardService get adminService => const AdminDashboardService();

  void showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor: isError
            ? const Color(
                0xFFD32F2F,
              )
            : const Color(
                0xFF2E7D32,
              ),
      ),
    );
  }

  Future<
    void
  >
  logout(
    BuildContext context,
  ) async {
    await adminService.logout();

    if (!context.mounted) {
      return;
    }

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

  Future<
    void
  >
  approveSupplier({
    required BuildContext context,
    required QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    supplierDocument,
  }) async {
    try {
      await adminService.approveSupplier(
        supplierDocument,
      );

      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Supplier approved. Supplier Dashboard is now available to this account.',
      );
    } catch (
      error
    ) {
      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Failed to approve supplier: $error',
        isError: true,
      );
    }
  }

  Future<
    void
  >
  rejectSupplier({
    required BuildContext context,
    required QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    supplierDocument,
  }) async {
    final shouldReject =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      22,
                    ),
                  ),
                  title: const Text(
                    'Reject Supplier?',
                    style: TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  content: const Text(
                    'This will mark the supplier application as rejected. The user will remain a vendor account.',
                    style: TextStyle(
                      color: Color(
                        0xFF52677A,
                      ),
                      height: 1.4,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        false,
                      ),
                      child: const Text(
                        'Cancel',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        true,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFD32F2F,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Reject',
                      ),
                    ),
                  ],
                );
              },
        );

    if (shouldReject !=
        true) {
      return;
    }

    try {
      await adminService.rejectSupplier(
        supplierDocument,
      );

      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Supplier application rejected.',
      );
    } catch (
      error
    ) {
      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Failed to reject supplier: $error',
        isError: true,
      );
    }
  }

  Widget dashboardBody({
    required BuildContext context,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    users,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    suppliers,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    changeRequests,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    stocks,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    orders,
  }) {
    final pendingSuppliers = adminService.pendingSuppliers(
      suppliers,
    );
    final approvedSuppliers = adminService.approvedSuppliers(
      suppliers,
    );
    final pendingChangeRequests = adminService.pendingChangeRequests(
      changeRequests,
    );
    final totalPending = pendingSuppliers.length + pendingChangeRequests.length;

    return Column(
      children: [
        AdminDashboardHeader(
          usersCount: users.length,
          suppliersCount: approvedSuppliers.length,
          pendingCount: totalPending,
          ordersCount: orders.length,
          onLogout: () => logout(
            context,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              20,
            ),
            children: [
              _AdminAttentionSummary(
                supplierApplications:
                    pendingSuppliers.length,
                verifiedChangeRequests:
                    pendingChangeRequests.length,
              ),
              const SizedBox(
                height: 24,
              ),
              const AdminSectionTitle(
                title: 'New Supplier Applications',
                subtitle: 'Review vendor applications and approve or reject supplier access.',
                icon: Icons.hourglass_top,
              ),
              const SizedBox(
                height: 16,
              ),
              if (pendingSuppliers.isEmpty)
                const AdminEmptyCard(
                  icon: Icons.check_circle_outline,
                  title: 'No pending supplier applications',
                  subtitle: 'Vendor applications will appear here after they tap Become a Supplier.',
                )
              else
                ...pendingSuppliers.map(
                  (
                    document,
                  ) => PendingSupplierCard(
                    document: document,
                    onReject: () => rejectSupplier(
                      context: context,
                      supplierDocument: document,
                    ),
                    onApprove: () => approveSupplier(
                      context: context,
                      supplierDocument: document,
                    ),
                  ),
                ),
              const SizedBox(
                height: 26,
              ),
              const AdminSectionTitle(
                title: 'Verified Profile Changes',
                subtitle: 'Review protected business, location, store-photo and permit changes from approved suppliers.',
                icon: Icons.manage_accounts_outlined,
              ),
              const SizedBox(
                height: 16,
              ),
              if (pendingChangeRequests.isEmpty)
                const AdminEmptyCard(
                  icon: Icons.verified_user_outlined,
                  title: 'No supplier change requests',
                  subtitle: 'Verified business information change requests will appear here for review.',
                )
              else
                ...pendingChangeRequests.map(
                  (
                    document,
                  ) => AdminChangeRequestCard(
                    document: document,
                    onOpen: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupplierChangeRequestReviewScreen(
                          supplierId: document.id,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(
                height: 26,
              ),
              const AdminSectionTitle(
                title: 'Approved Suppliers',
                subtitle: 'Suppliers with dashboard access and visible supplier profile status.',
                icon: Icons.verified,
              ),
              const SizedBox(
                height: 16,
              ),
              if (approvedSuppliers.isEmpty)
                const AdminEmptyCard(
                  icon: Icons.storefront_outlined,
                  title: 'No approved suppliers yet',
                  subtitle: 'Approved suppliers will appear here after admin review.',
                )
              else
                ...approvedSuppliers.map(
                  (
                    document,
                  ) => ApprovedSupplierCard(
                    document: document,
                  ),
                ),
              const SizedBox(
                height: 26,
              ),
              const AdminSectionTitle(
                title: 'System Overview',
                subtitle: 'Quick snapshot of current marketplace and account records.',
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(
                height: 16,
              ),
              AdminOverviewCard(
                usersCount: users.length,
                suppliersCount: suppliers.length,
                stocksCount: stocks.length,
                ordersCount: orders.length,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDashboardStreams() {
    return StreamBuilder<
      QuerySnapshot<
        Map<
          String,
          dynamic
        >
      >
    >(
      stream: adminService.usersStream,
      builder:
          (
            context,
            usersSnapshot,
          ) {
            return StreamBuilder<
              QuerySnapshot<
                Map<
                  String,
                  dynamic
                >
              >
            >(
              stream: adminService.supplierProfilesStream,
              builder:
                  (
                    context,
                    suppliersSnapshot,
                  ) {
                    return StreamBuilder<
                      QuerySnapshot<
                        Map<
                          String,
                          dynamic
                        >
                      >
                    >(
                      stream: adminService.fishStocksStream,
                      builder:
                          (
                            context,
                            stocksSnapshot,
                          ) {
                            return StreamBuilder<
                              QuerySnapshot<
                                Map<
                                  String,
                                  dynamic
                                >
                              >
                            >(
                              stream: adminService.ordersStream,
                              builder:
                                  (
                                    context,
                                    ordersSnapshot,
                                  ) {
                                    return StreamBuilder<
                                      QuerySnapshot<
                                        Map<
                                          String,
                                          dynamic
                                        >
                                      >
                                    >(
                                      stream: adminService.supplierChangeRequestsStream,
                                      builder:
                                          (
                                            context,
                                            changeRequestsSnapshot,
                                          ) {
                                            if (usersSnapshot.hasError) {
                                              return AdminErrorBody(
                                                error: usersSnapshot.error!,
                                              );
                                            }

                                            if (suppliersSnapshot.hasError) {
                                              return AdminErrorBody(
                                                error: suppliersSnapshot.error!,
                                              );
                                            }

                                            if (stocksSnapshot.hasError) {
                                              return AdminErrorBody(
                                                error: stocksSnapshot.error!,
                                              );
                                            }

                                            if (ordersSnapshot.hasError) {
                                              return AdminErrorBody(
                                                error: ordersSnapshot.error!,
                                              );
                                            }

                                            if (changeRequestsSnapshot.hasError) {
                                              return AdminErrorBody(
                                                error: changeRequestsSnapshot.error!,
                                              );
                                            }

                                            if (!usersSnapshot.hasData ||
                                                !suppliersSnapshot.hasData ||
                                                !stocksSnapshot.hasData ||
                                                !ordersSnapshot.hasData ||
                                                !changeRequestsSnapshot.hasData) {
                                              return const AdminLoadingBody();
                                            }

                                            return Scaffold(
                                              backgroundColor: const Color(
                                                0xFFF4F8FB,
                                              ),
                                              body: dashboardBody(
                                                context: context,
                                                users: usersSnapshot.data!.docs,
                                                suppliers: suppliersSnapshot.data!.docs,
                                                changeRequests: changeRequestsSnapshot.data!.docs,
                                                stocks: stocksSnapshot.data!.docs,
                                                orders: ordersSnapshot.data!.docs,
                                              ),
                                            );
                                          },
                                    );
                                  },
                            );
                          },
                    );
                  },
            );
          },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return buildDashboardStreams();
  }
}

class _AdminAttentionSummary extends StatelessWidget {
  const _AdminAttentionSummary({
    required this.supplierApplications,
    required this.verifiedChangeRequests,
  });

  final int supplierApplications;
  final int verifiedChangeRequests;

  @override
  Widget build(BuildContext context) {
    final total =
        supplierApplications + verifiedChangeRequests;
    final allClear = total == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: allClear
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF102C44),
                  Color(0xFF146BFF),
                ],
              ),
        color: allClear
            ? Colors.white
            : null,
        borderRadius: BorderRadius.circular(22),
        border: allClear
            ? Border.all(
                color: const Color(0xFFDDE8F0),
              )
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D102C44),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: allClear
                      ? const Color(0xFFEAF8F2)
                      : Colors.white.withValues(
                          alpha: 0.14,
                        ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  allClear
                      ? Icons.task_alt_rounded
                      : Icons
                          .notification_important_outlined,
                  color: allClear
                      ? const Color(0xFF16845C)
                      : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      allClear
                          ? 'All caught up'
                          : 'Needs Attention',
                      style: TextStyle(
                        color: allClear
                            ? const Color(0xFF102C44)
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      allClear
                          ? 'No supplier verification items currently require review.'
                          : '$total supplier verification ${total == 1 ? 'item requires' : 'items require'} Admin review.',
                      style: TextStyle(
                        color: allClear
                            ? const Color(0xFF7B8FA3)
                            : const Color(0xFFDDEBFA),
                        fontSize: 9,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!allClear)
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.15,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AdminAttentionMetric(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Applications',
                  value: supplierApplications,
                  dark: !allClear,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AdminAttentionMetric(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Profile changes',
                  value: verifiedChangeRequests,
                  dark: !allClear,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminAttentionMetric extends StatelessWidget {
  const _AdminAttentionMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.dark,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(
                alpha: 0.11,
              )
            : const Color(0xFFF5F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: dark
                ? Colors.white
                : const Color(0xFF146BFF),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dark
                    ? const Color(0xFFE6F0F8)
                    : const Color(0xFF5F7587),
                fontSize: 8.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: TextStyle(
              color: dark
                  ? Colors.white
                  : const Color(0xFF102C44),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}


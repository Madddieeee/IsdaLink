import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

    return Column(
      children: [
        AdminDashboardHeader(
          usersCount: users.length,
          suppliersCount: approvedSuppliers.length,
          pendingCount: pendingSuppliers.length,
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
              const AdminSectionTitle(
                title: 'Pending Supplier Applications',
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
                subtitle: 'Quick snapshot of live Firestore records for thesis demonstration.',
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

                                    if (!usersSnapshot.hasData ||
                                        !suppliersSnapshot.hasData ||
                                        !stocksSnapshot.hasData ||
                                        !ordersSnapshot.hasData) {
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
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return buildDashboardStreams();
  }
}

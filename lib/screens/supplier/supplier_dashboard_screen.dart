import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/analytics/analytics_screen.dart';
import 'package:isdalink/screens/home/home_screen.dart';
import 'package:isdalink/screens/supplier/dashboard/widgets/supplier_dashboard_actions.dart';
import 'package:isdalink/screens/supplier/dashboard/widgets/supplier_dashboard_header.dart';
import 'package:isdalink/screens/supplier/dashboard/widgets/supplier_dashboard_section_title.dart';
import 'package:isdalink/screens/supplier/dashboard/widgets/supplier_dashboard_status_cards.dart';
import 'package:isdalink/screens/supplier/dashboard/widgets/supplier_stock_list.dart';
import 'package:isdalink/screens/supplier/post_fish_stock_screen.dart';
import 'package:isdalink/screens/supplier/supplier_cod_orders_screen.dart';
import 'package:isdalink/screens/supplier/supplier_manage_products_screen.dart';
import 'package:isdalink/services/supplier_dashboard_service.dart';

class SupplierDashboardScreen
    extends
        StatelessWidget {
  const SupplierDashboardScreen({
    super.key,
  });

  User? get currentUser => FirebaseAuth.instance.currentUser;

  SupplierDashboardService get dashboardService => const SupplierDashboardService();

  void openPostFishStock(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const PostFishStockScreen(),
      ),
    );
  }

  void openManageProducts(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const SupplierManageProductsScreen(),
      ),
    );
  }

  void openAnalytics(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const AnalyticsScreen(),
      ),
    );
  }

  void openOrders(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const SupplierCodOrdersScreen(),
      ),
    );
  }

  void safeBack(
    BuildContext context,
  ) {
    if (Navigator.canPop(
      context,
    )) {
      Navigator.pop(
        context,
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const HomeScreen(),
      ),
    );
  }

  Widget dashboardContent({
    required BuildContext context,
    required List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  }) {
    final stats = dashboardService.calculateStats(
      documents,
    );

    return Column(
      children: [
        SupplierDashboardHeader(
          stats: stats,
          onBack: () => safeBack(
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
              const SupplierDashboardSectionTitle(
                title: 'Supplier Tools',
                subtitle: 'These tools support this supplier account only.',
              ),
              SupplierDashboardActions(
                onPostFishStock: () => openPostFishStock(
                  context,
                ),
                onManageProducts: () => openManageProducts(
                  context,
                ),
                onOrders: () => openOrders(
                  context,
                ),
                onAnalytics: () => openAnalytics(
                  context,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              const SupplierDashboardSectionTitle(
                title: 'Current Stock Posts',
                subtitle: 'Only fish stock posts owned by this supplier account are shown.',
              ),
              SupplierStockList(
                documents: documents,
                onEditStock: () => openManageProducts(
                  context,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget loadingDashboard(
    BuildContext context,
  ) {
    return Column(
      children: [
        SupplierDashboardHeader(
          stats: const SupplierDashboardStats(
            totalProducts: 0,
            totalStocks: 0,
            lowStockCount: 0,
          ),
          onBack: () => safeBack(
            context,
          ),
          isLoading: true,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              20,
            ),
            children: const [
              SupplierDashboardSectionTitle(
                title: 'Current Stock Posts',
                subtitle: 'Loading your live fish stock posts from Firebase Firestore.',
              ),
              SupplierDashboardLoadingStocks(),
            ],
          ),
        ),
      ],
    );
  }

  Widget errorDashboard(
    BuildContext context,
    Object error,
  ) {
    return Column(
      children: [
        SupplierDashboardHeader(
          stats: const SupplierDashboardStats(
            totalProducts: 0,
            totalStocks: 0,
            lowStockCount: 0,
          ),
          onBack: () => safeBack(
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
              const SupplierDashboardSectionTitle(
                title: 'Current Stock Posts',
                subtitle: 'There was a problem loading this supplier account stock posts.',
              ),
              SupplierDashboardErrorCard(
                error: error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget notLoggedInBody() {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(
            22,
          ),
          padding: const EdgeInsets.all(
            18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ),
          ),
          child: const Text(
            'Please log in first to view the Supplier Dashboard.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(
                0xFFD32F2F,
              ),
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
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
    final user = currentUser;

    if (user ==
        null) {
      return notLoggedInBody();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (
            didPop,
            result,
          ) {
            if (didPop) {
              return;
            }

            safeBack(
              context,
            );
          },
      child: Scaffold(
        backgroundColor: const Color(
          0xFFF4F8FB,
        ),
        body:
            StreamBuilder<
              QuerySnapshot<
                Map<
                  String,
                  dynamic
                >
              >
            >(
              stream: dashboardService.fishStocksStream(
                user.uid,
              ),
              builder:
                  (
                    context,
                    snapshot,
                  ) {
                    if (snapshot.hasError) {
                      return errorDashboard(
                        context,
                        snapshot.error!,
                      );
                    }

                    if (!snapshot.hasData) {
                      return loadingDashboard(
                        context,
                      );
                    }

                    final documents = dashboardService.sortStocks(
                      snapshot.data!.docs,
                    );

                    return dashboardContent(
                      context: context,
                      documents: documents,
                    );
                  },
            ),
      ),
    );
  }
}

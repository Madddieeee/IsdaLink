import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/analytics_models.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_footer_note.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_header.dart';
import 'package:isdalink/screens/analytics/widgets/analytics_state_widgets.dart';
import 'package:isdalink/screens/analytics/widgets/forecast_evaluation_card.dart';
import 'package:isdalink/screens/analytics/widgets/forecasting_methods_card.dart';
import 'package:isdalink/screens/analytics/widgets/restocking_suggestions_card.dart';
import 'package:isdalink/screens/analytics/widgets/sales_trend_card.dart';
import 'package:isdalink/screens/analytics/widgets/top_product_insights_card.dart';
import 'package:isdalink/services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, this.initialSupplierMode});

  final bool? initialSupplierMode;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService analyticsService = const AnalyticsService();

  bool? supplierModeOverride;

  @override
  void initState() {
    super.initState();
    supplierModeOverride = widget.initialSupplierMode;
  }

  void updateMode(bool isSupplierMode) {
    setState(() {
      supplierModeOverride = isSupplierMode;
    });
  }

  Widget analyticsContent({
    required AnalyticsData data,
    required bool hasSupplierAccess,
    required bool isSupplierMode,
  }) {
    return Column(
      children: [
        AnalyticsHeader(
          isSupplierMode: isSupplierMode,
          hasSupplierAccess: hasSupplierAccess,
          completedOrders: data.completedOrders,
          totalQuantity: data.totalQuantity,
          totalRevenue: data.totalRevenue,
          onBack: () => Navigator.pop(context),
          onModeChanged: updateMode,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
            children: [
              ForecastingMethodsCard(simpleForecast: data.simpleForecast, seasonalForecast: data.seasonalForecast),
              ForecastEvaluationCard(evaluation: data.evaluation),
              SalesTrendCard(dailySales: data.dailySales),
              RestockingSuggestionsCard(stockAlerts: data.stockAlerts, isSupplierMode: isSupplierMode),
              TopProductInsightsCard(topProducts: data.topProducts),
              const AnalyticsFooterNote(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildStockStream({
    required String uid,
    required bool hasSupplierAccess,
    required bool isSupplierMode,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orderDocuments,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: analyticsService.fishStocksStream(uid: uid, isSupplierMode: isSupplierMode),
      builder: (context, stockSnapshot) {
        if (stockSnapshot.hasError) {
          return AnalyticsErrorBody(error: stockSnapshot.error!);
        }

        if (!stockSnapshot.hasData) {
          return const AnalyticsLoadingBody();
        }

        final analyticsData = analyticsService.buildAnalyticsData(
          orderDocuments: orderDocuments,
          stockDocuments: stockSnapshot.data!.docs,
        );

        return analyticsContent(
          data: analyticsData,
          hasSupplierAccess: hasSupplierAccess,
          isSupplierMode: isSupplierMode,
        );
      },
    );
  }

  Widget buildOrderStream({
    required String uid,
    required bool hasSupplierAccess,
    required bool isSupplierMode,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: analyticsService.ordersStream(uid: uid, isSupplierMode: isSupplierMode),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.hasError) {
          return AnalyticsErrorBody(error: orderSnapshot.error!);
        }

        if (!orderSnapshot.hasData) {
          return const AnalyticsLoadingBody();
        }

        return buildStockStream(
          uid: uid,
          hasSupplierAccess: hasSupplierAccess,
          isSupplierMode: isSupplierMode,
          orderDocuments: orderSnapshot.data!.docs,
        );
      },
    );
  }

  Widget buildProfileStream(String uid) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: analyticsService.userProfileStream(uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return AnalyticsErrorBody(error: userSnapshot.error!);
        }

        if (!userSnapshot.hasData) {
          return const AnalyticsLoadingBody();
        }

        final userData = userSnapshot.data!.data() ?? {};
        final hasSupplierAccess = analyticsService.hasSupplierAccess(userData);
        final isSupplierMode = hasSupplierAccess ? (supplierModeOverride ?? true) : false;

        return buildOrderStream(
          uid: uid,
          hasSupplierAccess: hasSupplierAccess,
          isSupplierMode: isSupplierMode,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = analyticsService.currentUser;

    if (user == null) {
      return const AnalyticsLoggedOutBody();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: buildProfileStream(user.uid),
    );
  }
}

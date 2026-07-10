import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/home/home_screen.dart';

import '../analytics/analytics_screen.dart';
import 'post_fish_stock_screen.dart';
import 'supplier_cod_orders_screen.dart';
import 'supplier_manage_products_screen.dart';

class SupplierDashboardScreen
    extends
        StatelessWidget {
  const SupplierDashboardScreen({
    super.key,
  });

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  fishStocksStream(
    String supplierId,
  ) {
    return FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .where(
          'supplierId',
          isEqualTo: supplierId,
        )
        .snapshots();
  }

  int createdAtMillis(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final value = document.data()['createdAt'];

    if (value
        is Timestamp) {
      return value.millisecondsSinceEpoch;
    }

    return 0;
  }

  List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  sortStocks(
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    final sortedDocuments = [
      ...documents,
    ];

    sortedDocuments.sort(
      (
        a,
        b,
      ) =>
          createdAtMillis(
            b,
          ).compareTo(
            createdAtMillis(
              a,
            ),
          ),
    );

    return sortedDocuments;
  }

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

  Future<
    bool
  >
  handleSystemBack(
    BuildContext context,
  ) async {
    safeBack(
      context,
    );
    return false;
  }

  String getStringValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    if (value ==
        null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  double getDoubleValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
  ) {
    final value = data[key];

    if (value
        is int) {
      return value.toDouble();
    }

    if (value
        is double) {
      return value;
    }

    if (value
        is String) {
      return double.tryParse(
            value,
          ) ??
          0;
    }

    return 0;
  }

  Color getStockColor(
    double quantity,
    double lowStockLevel,
    String status,
  ) {
    if (status.toLowerCase() ==
        'unavailable') {
      return const Color(
        0xFF7B8FA3,
      );
    }

    if (quantity <=
        0) {
      return const Color(
        0xFFD32F2F,
      );
    }

    if (quantity <=
        lowStockLevel) {
      return const Color(
        0xFFF57C00,
      );
    }

    return const Color(
      0xFF2E7D32,
    );
  }

  String getStockStatus(
    double quantity,
    double lowStockLevel,
    String status,
  ) {
    if (status.toLowerCase() ==
        'unavailable') {
      return 'Hidden';
    }

    if (quantity <=
        0) {
      return 'Out of Stock';
    }

    if (quantity <=
        lowStockLevel) {
      return 'Low Stock';
    }

    return 'Available';
  }

  Widget statCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 76,
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(
            38,
          ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: Colors.white.withAlpha(
              36,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(
                  0xFFDCE9F5,
                ),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = const Color(
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
            24,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x10000000,
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(
                  24,
                ),
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
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
                        0xFF7B8FA3,
                      ),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(
                0xFF9AAABD,
              ),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget productStockCard(
    BuildContext context,
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final data = document.data();

    final productName = getStringValue(
      data,
      'productName',
      'Fish Product',
    );
    final emoji = getStringValue(
      data,
      'emoji',
      '🐟',
    );
    final price = getDoubleValue(
      data,
      'price',
    );
    final priceUnit = getStringValue(
      data,
      'priceUnit',
      'per kilo',
    );
    final quantity = getDoubleValue(
      data,
      'quantity',
    );
    final quantityUnit = getStringValue(
      data,
      'quantityUnit',
      'kilo',
    );
    final lowStockLevel = getDoubleValue(
      data,
      'lowStockLevel',
    );
    final status = getStringValue(
      data,
      'status',
      'available',
    );

    final stockColor = getStockColor(
      quantity,
      lowStockLevel,
      status,
    );
    final stockStatus = getStockStatus(
      quantity,
      lowStockLevel,
      status,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          22,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0F000000,
            ),
            blurRadius: 12,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(
                0xFFEAF7FB,
              ),
              borderRadius: BorderRadius.circular(
                17,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '₱${price.toStringAsFixed(0)} $priceUnit',
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: stockColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Text(
                        '$stockStatus • ${quantity.toStringAsFixed(0)} $quantityUnit',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: stockColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => openManageProducts(
              context,
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFEAF7FB,
                ),
                borderRadius: BorderRadius.circular(
                  13,
                ),
              ),
              child: const Icon(
                Icons.edit,
                color: Color(
                  0xFF146BFF,
                ),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 19,
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
                0xFF7B8FA3,
              ),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyStocksCard() {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Color(
              0xFF146BFF,
            ),
            size: 42,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'No fish stock posts yet',
            style: TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'Only posts created by this logged-in supplier account will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(
                0xFF7B8FA3,
              ),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingStockCards() {
    return Column(
      children: List.generate(
        3,
        (
          index,
        ) => Container(
          margin: const EdgeInsets.only(
            bottom: 12,
          ),
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              22,
            ),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 54,
                height: 54,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Text(
                  'Loading your fish stock posts...',
                  style: TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget errorStocksCard(
    Object error,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Text(
        'Unable to load your fish stock posts: $error',
        style: const TextStyle(
          color: Color(
            0xFFD32F2F,
          ),
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget dashboardContent(
    BuildContext context,
    List<
      QueryDocumentSnapshot<
        Map<
          String,
          dynamic
        >
      >
    >
    documents,
  ) {
    final totalProducts = documents.length;

    final totalStocks =
        documents.fold<
          double
        >(
          0,
          (
            sum,
            document,
          ) {
            return sum +
                getDoubleValue(
                  document.data(),
                  'quantity',
                );
          },
        );

    final lowStockCount = documents.where(
      (
        document,
      ) {
        final data = document.data();
        final status = getStringValue(
          data,
          'status',
          'available',
        );
        final quantity = getDoubleValue(
          data,
          'quantity',
        );
        final lowStockLevel = getDoubleValue(
          data,
          'lowStockLevel',
        );

        return status.toLowerCase() !=
                'unavailable' &&
            quantity >
                0 &&
            quantity <=
                lowStockLevel;
      },
    ).length;

    final productsToShow = documents
        .take(
          4,
        )
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            54,
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
                  GestureDetector(
                    onTap: () => safeBack(
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
                      'Supplier Dashboard',
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
                height: 18,
              ),
              const Text(
                'Manage fish stock posts, COD orders, and supplier analytics for this account.',
                style: TextStyle(
                  color: Color(
                    0xFFDCE9F5,
                  ),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Row(
                children: [
                  statCard(
                    value: '$totalProducts',
                    label: 'Products',
                    icon: Icons.inventory_2,
                  ),
                  statCard(
                    value: totalStocks.toStringAsFixed(
                      0,
                    ),
                    label: 'Stocks',
                    icon: Icons.scale,
                  ),
                  statCard(
                    value: '$lowStockCount',
                    label: 'Low Stock',
                    icon: Icons.warning_amber,
                  ),
                ],
              ),
            ],
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
              sectionTitle(
                'Supplier Tools',
                'These tools support this supplier account only.',
              ),
              actionTile(
                icon: Icons.add_box,
                title: 'Post Fish Stock',
                subtitle: 'Add fish products, price, quantity, and unit type.',
                onTap: () => openPostFishStock(
                  context,
                ),
              ),
              actionTile(
                icon: Icons.inventory,
                title: 'Manage Products',
                subtitle: 'Update your own stock levels, price, and low-stock alerts.',
                color: const Color(
                  0xFF00A6A6,
                ),
                onTap: () => openManageProducts(
                  context,
                ),
              ),
              actionTile(
                icon: Icons.receipt_long,
                title: 'COD Orders',
                subtitle: 'View incoming vendor orders and payment status.',
                color: const Color(
                  0xFFFF7A1A,
                ),
                onTap: () => openOrders(
                  context,
                ),
              ),
              actionTile(
                icon: Icons.analytics,
                title: 'Sales Analytics',
                subtitle: 'View moving average forecasts and restocking insights.',
                color: const Color(
                  0xFF7B61FF,
                ),
                onTap: () => openAnalytics(
                  context,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              sectionTitle(
                'Current Stock Posts',
                'Only fish stock posts owned by this supplier account are shown.',
              ),
              if (productsToShow.isEmpty)
                emptyStocksCard()
              else
                ...productsToShow.map(
                  (
                    document,
                  ) => productStockCard(
                    context,
                    document,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget loadingDashboard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            54,
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
              const Text(
                'Supplier Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              const Text(
                'Loading your supplier stock data from Firebase...',
                style: TextStyle(
                  color: Color(
                    0xFFDCE9F5,
                  ),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Row(
                children: [
                  statCard(
                    value: '...',
                    label: 'Products',
                    icon: Icons.inventory_2,
                  ),
                  statCard(
                    value: '...',
                    label: 'Stocks',
                    icon: Icons.scale,
                  ),
                  statCard(
                    value: '...',
                    label: 'Low Stock',
                    icon: Icons.warning_amber,
                  ),
                ],
              ),
            ],
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
              sectionTitle(
                'Current Stock Posts',
                'Loading your live fish stock posts from Firebase Firestore.',
              ),
              loadingStockCards(),
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

  Widget errorDashboard(
    Object error,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            54,
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
          child: const Text(
            'Supplier Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
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
              sectionTitle(
                'Current Stock Posts',
                'There was a problem loading this supplier account stock posts.',
              ),
              errorStocksCard(
                error,
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
    final user = currentUser;

    if (user ==
        null) {
      return notLoggedInBody();
    }

    return WillPopScope(
      onWillPop: () => handleSystemBack(
        context,
      ),
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
              stream: fishStocksStream(
                user.uid,
              ),
              builder:
                  (
                    context,
                    snapshot,
                  ) {
                    if (snapshot.hasError) {
                      return errorDashboard(
                        snapshot.error!,
                      );
                    }

                    if (!snapshot.hasData) {
                      return loadingDashboard();
                    }

                    final documents = sortStocks(
                      snapshot.data!.docs,
                    );

                    return dashboardContent(
                      context,
                      documents,
                    );
                  },
            ),
      ),
    );
  }
}

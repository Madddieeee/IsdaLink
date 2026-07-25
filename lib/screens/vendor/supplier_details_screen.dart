import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
import 'package:isdalink/screens/vendor/supplier_map_screen.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_details_header.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_details_status_cards.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_product_card.dart';
import 'package:isdalink/screens/vendor/supplier_details/widgets/supplier_reviews_section.dart';
import 'package:isdalink/services/supplier_details_service.dart';

class SupplierDetailsScreen extends StatelessWidget {
  const SupplierDetailsScreen({
    super.key,
    required this.supplier,
    this.supplierId,
  });

  final Supplier supplier;
  final String? supplierId;

  SupplierDetailsService get detailsService => const SupplierDetailsService();

  void openProduct({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
  }) {
    final data = document.data();

    final product = detailsService.fishProductFromFirestore(
      data,
    );

    final stockSupplierId = detailsService.getStringValue(
      data,
      'supplierId',
      supplierId ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          supplier: supplier,
          product: product,
          stockId: document.id,
          supplierId: stockSupplierId,
        ),
      ),
    );
  }

  Widget productCard({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
  }) {
    final data = document.data();

    final productName = detailsService.getStringValue(
      data,
      'productName',
      'Fish Product',
    );

    final category = detailsService.getStringValue(
      data,
      'category',
      'Fresh Fish',
    );

    final emoji = detailsService.getStringValue(
      data,
      'emoji',
      '🐟',
    );

    final price = detailsService.getDoubleValue(
      data,
      'price',
    );

    final priceUnit = detailsService.getStringValue(
      data,
      'priceUnit',
      'per kilo',
    );

    final quantity = detailsService.getDoubleValue(
      data,
      'quantity',
    );

    final quantityUnit = detailsService.getStringValue(
      data,
      'quantityUnit',
      'kilo',
    );

    final lowStockLevel = detailsService.getDoubleValue(
      data,
      'lowStockLevel',
    );

    final stockColor = detailsService.getStockColor(
      quantity: quantity,
      lowStockLevel: lowStockLevel,
    );

    final stockStatus = detailsService.getStockStatus(
      quantity: quantity,
      lowStockLevel: lowStockLevel,
    );

    return SupplierProductCard(
      productName: productName,
      category: category,
      emoji: emoji,
      price: price,
      priceUnit: priceUnit,
      quantity: quantity,
      quantityUnit: quantityUnit,
      stockColor: stockColor,
      stockStatus: stockStatus,
      onTap: () => openProduct(
        context: context,
        document: document,
      ),
    );
  }

  double? doubleValueFromProfile(
    Map<String, dynamic>? data,
    String key,
  ) {
    if (data == null) {
      return null;
    }

    final value = data[key];

    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is String) {
      return double.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  Widget supplierMapLocationCard(
    BuildContext context,
  ) {
    if (supplierId == null || supplierId!.trim().isEmpty) {
      return const SupplierMapUnavailableCard();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('supplierProfiles')
          .doc(supplierId)
          .snapshots(),
      builder: (context, profileSnapshot) {
        final data = profileSnapshot.data?.data();

        final latitude = doubleValueFromProfile(
          data,
          'latitude',
        );

        final longitude = doubleValueFromProfile(
          data,
          'longitude',
        );

        final profileData = data ?? <String, dynamic>{};

        final supplierName = detailsService.getStringValue(
          profileData,
          'supplierName',
          supplier.name,
        );

        final location = detailsService.getStringValue(
          profileData,
          'location',
          supplier.location,
        );

        if (latitude == null || longitude == null) {
          return const SupplierMapUnavailableCard();
        }

        return SupplierMapLocationCard(
          supplierName: supplierName,
          location: location,
          latitude: latitude,
          longitude: longitude,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SupplierMapScreen(
                  supplierName: supplierName,
                  location: location,
                  latitude: latitude,
                  longitude: longitude,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget bodyContent({
    required BuildContext context,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  }) {
    final stats = detailsService.calculateStats(
      documents,
    );

    return Column(
      children: [
        SupplierDetailsHeader(
          supplier: supplier,
          stats: stats,
          onBack: () => Navigator.pop(
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
              supplierMapLocationCard(
                context,
              ),
              const SizedBox(
                height: 18,
              ),
              const Text(
                'Available Fish Products',
                style: TextStyle(
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
              const Text(
                'Live Firebase stock posts for the selected supplier. Tap a product to view details and place a COD order.',
                style: TextStyle(
                  color: Color(
                    0xFF7B8FA3,
                  ),
                  fontSize: 12,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              if (documents.isEmpty)
                const SupplierDetailsEmptyCard()
              else
                ...documents.map(
                  (document) => productCard(
                    context: context,
                    document: document,
                  ),
                ),
              SupplierReviewsSection(
                supplierId: supplierId,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget loadingBody(
    BuildContext context,
  ) {
    final stats = detailsService.calculateStats(
      const [],
    );

    return Column(
      children: [
        SupplierDetailsHeader(
          supplier: supplier,
          stats: stats,
          onBack: () => Navigator.pop(
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
            children: const [
              Text(
                'Available Fish Products',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                height: 18,
              ),
              SupplierDetailsLoadingCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget errorBody({
    required BuildContext context,
    required Object error,
  }) {
    final stats = detailsService.calculateStats(
      const [],
    );

    return Column(
      children: [
        SupplierDetailsHeader(
          supplier: supplier,
          stats: stats,
          onBack: () => Navigator.pop(
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
              supplierMapLocationCard(
                context,
              ),
              const SizedBox(
                height: 18,
              ),
              const Text(
                'Available Fish Products',
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              SupplierDetailsErrorCard(
                error: error,
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
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: detailsService.fishStocksStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return errorBody(
              context: context,
              error: snapshot.error!,
            );
          }

          if (!snapshot.hasData) {
            return loadingBody(
              context,
            );
          }

          final documents = detailsService.filterSupplierStocks(
            documents: snapshot.data!.docs,
            supplier: supplier,
            supplierId: supplierId,
          );

          return bodyContent(
            context: context,
            documents: documents,
          );
        },
      ),
    );
  }
}


class SupplierMapLocationCard extends StatelessWidget {
  const SupplierMapLocationCard({
    super.key,
    required this.supplierName,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  final String supplierName;
  final String location;
  final double latitude;
  final double longitude;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF102C44),
                  Color(0xFF146BFF),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Store Location',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF146BFF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(
              Icons.map,
              size: 17,
            ),
            label: const Text(
              'View Map',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF146BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierMapUnavailableCard extends StatelessWidget {
  const SupplierMapUnavailableCard({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFB703).withAlpha(72),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_off_outlined,
            color: Color(0xFFFF7A1A),
            size: 24,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Map location is not set for this supplier yet. Add latitude and longitude to the supplier profile to show a Google Maps pin.',
              style: TextStyle(
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
}

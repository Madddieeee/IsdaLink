import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/product_details_screen.dart';
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

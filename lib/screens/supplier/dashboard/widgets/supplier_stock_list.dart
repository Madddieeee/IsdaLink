import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/dashboard/widgets/supplier_stock_card.dart';

class SupplierStockList
    extends
        StatelessWidget {
  const SupplierStockList({
    super.key,
    required this.documents,
    required this.onEditStock,
  });

  final List<
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  documents;
  final VoidCallback onEditStock;

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

  @override
  Widget build(
    BuildContext context,
  ) {
    final productsToShow = documents
        .take(
          4,
        )
        .toList();

    if (productsToShow.isEmpty) {
      return emptyStocksCard();
    }

    return Column(
      children: productsToShow
          .map(
            (
              document,
            ) => SupplierStockCard(
              document: document,
              onEdit: onEditStock,
            ),
          )
          .toList(),
    );
  }
}

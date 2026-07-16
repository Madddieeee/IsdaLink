import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/browse_suppliers_header.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/browse_suppliers_status_cards.dart';
import 'package:isdalink/screens/vendor/browse_suppliers/widgets/supplier_profile_card.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';
import 'package:isdalink/services/supplier_browse_service.dart';

class BrowseSuppliersScreen
    extends
        StatefulWidget {
  const BrowseSuppliersScreen({
    super.key,
  });

  @override
  State<
    BrowseSuppliersScreen
  >
  createState() => _BrowseSuppliersScreenState();
}

class _BrowseSuppliersScreenState
    extends
        State<
          BrowseSuppliersScreen
        > {
  final searchController = TextEditingController();

  final SupplierBrowseService supplierService = const SupplierBrowseService();

  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void openSupplierDetails({
    required BuildContext context,
    required String supplierId,
    required Map<
      String,
      dynamic
    >
    data,
  }) {
    final supplier = supplierService.supplierFromProfile(
      data,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => SupplierDetailsScreen(
              supplier: supplier,
              supplierId: supplierId,
            ),
      ),
    );
  }

  Widget supplierListBody({
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
    final approvedDocuments = supplierService.approvedSuppliers(
      documents,
    );

    final filteredDocuments = supplierService.searchSuppliers(
      documents: approvedDocuments,
      query: searchQuery,
    );

    if (approvedDocuments.isEmpty) {
      return const BrowseSuppliersEmptyBody(
        title: 'No supplier profiles yet',
        subtitle: 'Approved supplier accounts from Firebase will appear here after admin review.',
      );
    }

    if (filteredDocuments.isEmpty) {
      return const BrowseSuppliersEmptyBody(
        title: 'No matching suppliers found',
        subtitle: 'Try searching another supplier name, location, or payment keyword.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        20,
      ),
      children: [
        const Text(
          'Recommended Suppliers',
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
          'Tap a supplier to view details and available fish products.',
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
        ...filteredDocuments.map(
          (
            document,
          ) {
            final data = document.data();

            final supplier = supplierService.supplierFromProfile(
              data,
            );

            final paymentMethod = supplierService.getStringValue(
              data,
              'paymentMethod',
              'COD',
            );

            final status = supplierService.getStringValue(
              data,
              'status',
              'approved',
            );

            return SupplierProfileCard(
              supplier: supplier,
              paymentMethod: paymentMethod,
              status: status,
              onTap: () => openSupplierDetails(
                context: context,
                supplierId: document.id,
                data: data,
              ),
            );
          },
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
      body:
          StreamBuilder<
            QuerySnapshot<
              Map<
                String,
                dynamic
              >
            >
          >(
            stream: supplierService.suppliersStream,
            builder:
                (
                  context,
                  snapshot,
                ) {
                  final documents =
                      snapshot.data?.docs ??
                      [];
                  final approvedCount = supplierService
                      .approvedSuppliers(
                        documents,
                      )
                      .length;

                  return Column(
                    children: [
                      BrowseSuppliersHeader(
                        approvedCount: approvedCount,
                        searchController: searchController,
                        onSearchChanged:
                            (
                              value,
                            ) {
                              setState(
                                () {
                                  searchQuery = value;
                                },
                              );
                            },
                        onBack: () => Navigator.pop(
                          context,
                        ),
                      ),
                      Expanded(
                        child: Builder(
                          builder:
                              (
                                context,
                              ) {
                                if (snapshot.hasError) {
                                  return BrowseSuppliersErrorBody(
                                    error: snapshot.error!,
                                  );
                                }

                                if (!snapshot.hasData) {
                                  return const BrowseSuppliersLoadingBody();
                                }

                                return supplierListBody(
                                  context: context,
                                  documents: documents,
                                );
                              },
                        ),
                      ),
                    ],
                  );
                },
          ),
    );
  }
}

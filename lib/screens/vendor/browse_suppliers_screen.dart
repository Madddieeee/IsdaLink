import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/models/fish_product.dart';
import 'package:isdalink/models/supplier.dart';
import 'package:isdalink/screens/vendor/supplier_details_screen.dart';

class BrowseSuppliersScreen
    extends
        StatelessWidget {
  const BrowseSuppliersScreen({
    super.key,
  });

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  get suppliersStream {
    return FirebaseFirestore.instance
        .collection(
          'supplierProfiles',
        )
        .snapshots();
  }

  void openSupplierDetails(
    BuildContext context,
    String supplierId,
    Supplier supplier,
  ) {
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
    double fallback,
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
          fallback;
    }

    return fallback;
  }

  int getIntValue(
    Map<
      String,
      dynamic
    >
    data,
    String key,
    int fallback,
  ) {
    final value = data[key];

    if (value
        is int) {
      return value;
    }

    if (value
        is double) {
      return value.toInt();
    }

    if (value
        is String) {
      return int.tryParse(
            value,
          ) ??
          fallback;
    }

    return fallback;
  }

  Supplier supplierFromProfile(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final supplierName = getStringValue(
      data,
      'supplierName',
      getStringValue(
        data,
        'name',
        'Registered Supplier',
      ),
    );

    return Supplier(
      name: supplierName,
      location: getStringValue(
        data,
        'location',
        'Caraga Region',
      ),
      contactNumber: getStringValue(
        data,
        'phone',
        getStringValue(
          data,
          'contactNumber',
          'No contact number',
        ),
      ),
      description: getStringValue(
        data,
        'description',
        'Registered fish supplier in the IsdaLink platform for vendor-supplier coordination.',
      ),
      rating: getDoubleValue(
        data,
        'rating',
        4.5,
      ),
      reviews: getIntValue(
        data,
        'reviews',
        0,
      ),
      products:
          <
            FishProduct
          >[],
    );
  }

  Widget statsCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        height: 72,
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

  Widget supplierCard(
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
    final supplier = supplierFromProfile(
      data,
    );

    final paymentMethod = getStringValue(
      data,
      'paymentMethod',
      'COD',
    );

    final status = getStringValue(
      data,
      'status',
      'approved',
    );

    final statusLabel =
        status.toLowerCase() ==
            'approved'
        ? 'APPROVED'
        : status.toUpperCase();

    return GestureDetector(
      onTap: () => openSupplierDetails(
        context,
        document.id,
        supplier,
      ),
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            24,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x14000000,
              ),
              blurRadius: 16,
              offset: Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 96,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(
                    24,
                  ),
                ),
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
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -26,
                    top: -28,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(
                          28,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: -28,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFEAF7FB,
                        ),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '🐟',
                          style: TextStyle(
                            fontSize: 34,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(
                          42,
                        ),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Color(
                              0xFFFFB703,
                            ),
                            size: 14,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                36,
                18,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        size: 16,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          supplier.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(
                              0xFF7B8FA3,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    supplier.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(
                        0xFF52677A,
                      ),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEAF7FB,
                          ),
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.cloud_done,
                              color: Color(
                                0xFF146BFF,
                              ),
                              size: 15,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              'Firebase profile',
                              style: TextStyle(
                                color: Color(
                                  0xFF146BFF,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFFFF4E8,
                          ),
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.payments,
                              color: Color(
                                0xFFFF7A1A,
                              ),
                              size: 15,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              paymentMethod,
                              style: const TextStyle(
                                color: Color(
                                  0xFFFF7A1A,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF146BFF,
                          ),
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget loadingBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        20,
      ),
      children: List.generate(
        3,
        (
          index,
        ) => Container(
          height: 176,
          margin: const EdgeInsets.only(
            bottom: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget emptyBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        20,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(
            22,
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
                Icons.storefront_outlined,
                color: Color(
                  0xFF146BFF,
                ),
                size: 44,
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                'No supplier profiles yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(
                    0xFF102C44,
                  ),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                'Registered supplier accounts from Firebase will appear here.',
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
        ),
      ],
    );
  }

  Widget errorBody(
    Object error,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        20,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(
            18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              24,
            ),
          ),
          child: Text(
            'Unable to load supplier profiles: $error',
            style: const TextStyle(
              color: Color(
                0xFFD32F2F,
              ),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget supplierListBody(
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
    final approvedDocuments = documents.where(
      (
        document,
      ) {
        final data = document.data();
        final status = getStringValue(
          data,
          'status',
          'approved',
        ).toLowerCase();

        return status ==
                'approved' ||
            status ==
                'active';
      },
    ).toList();

    if (approvedDocuments.isEmpty) {
      return emptyBody();
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
        ...approvedDocuments.map(
          (
            document,
          ) => supplierCard(
            context,
            document,
          ),
        ),
      ],
    );
  }

  Widget header(
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
    final approvedCount = documents.where(
      (
        document,
      ) {
        final status = getStringValue(
          document.data(),
          'status',
          'approved',
        ).toLowerCase();

        return status ==
                'approved' ||
            status ==
                'active';
      },
    ).length;

    return Container(
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
                onTap: () => Navigator.pop(
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
                  'Browse Suppliers',
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
            height: 8,
          ),
          const Text(
            'Find registered fish suppliers and available stocks in Caraga.',
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
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                18,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(
                    0x22000000,
                  ),
                  blurRadius: 12,
                  offset: Offset(
                    0,
                    6,
                  ),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.search,
                  color: Color(
                    0xFF7B8FA3,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    'Search supplier, fish, or location...',
                    style: TextStyle(
                      color: Color(
                        0xFF7B8FA3,
                      ),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Row(
            children: [
              statsCard(
                value: '$approvedCount',
                label: 'Suppliers',
                icon: Icons.storefront,
              ),
              statsCard(
                value: 'Live',
                label: 'Database',
                icon: Icons.cloud_done,
              ),
              statsCard(
                value: 'COD',
                label: 'Payment',
                icon: Icons.payments,
              ),
            ],
          ),
        ],
      ),
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
            stream: suppliersStream,
            builder:
                (
                  context,
                  snapshot,
                ) {
                  final documents =
                      snapshot.data?.docs ??
                      [];

                  return Column(
                    children: [
                      header(
                        context,
                        documents,
                      ),
                      Expanded(
                        child: Builder(
                          builder:
                              (
                                context,
                              ) {
                                if (snapshot.hasError) {
                                  return errorBody(
                                    snapshot.error!,
                                  );
                                }

                                if (!snapshot.hasData) {
                                  return loadingBody();
                                }

                                return supplierListBody(
                                  context,
                                  documents,
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

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/welcome_screen.dart';

class AdminDashboardScreen
    extends
        StatelessWidget {
  const AdminDashboardScreen({
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
  get usersStream {
    return FirebaseFirestore.instance
        .collection(
          'users',
        )
        .snapshots();
  }

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  get supplierProfilesStream {
    return FirebaseFirestore.instance
        .collection(
          'supplierProfiles',
        )
        .snapshots();
  }

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  get fishStocksStream {
    return FirebaseFirestore.instance
        .collection(
          'fishStocks',
        )
        .snapshots();
  }

  Stream<
    QuerySnapshot<
      Map<
        String,
        dynamic
      >
    >
  >
  get ordersStream {
    return FirebaseFirestore.instance
        .collection(
          'orders',
        )
        .snapshots();
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

  Color statusColor(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
      case 'delivered':
        return const Color(
          0xFF2E7D32,
        );
      case 'pending':
        return const Color(
          0xFFFF7A1A,
        );
      case 'rejected':
      case 'cancelled':
        return const Color(
          0xFFD32F2F,
        );
      default:
        return const Color(
          0xFF7B8FA3,
        );
    }
  }

  Future<
    void
  >
  logout(
    BuildContext context,
  ) async {
    await FirebaseAuth.instance.signOut();

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
  approveSupplier(
    BuildContext context,
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    supplierDocument,
  ) async {
    final data = supplierDocument.data();
    final uid = getStringValue(
      data,
      'uid',
      supplierDocument.id,
    );

    try {
      final batch = FirebaseFirestore.instance.batch();

      final userRef = FirebaseFirestore.instance
          .collection(
            'users',
          )
          .doc(
            uid,
          );
      final supplierRef = FirebaseFirestore.instance
          .collection(
            'supplierProfiles',
          )
          .doc(
            uid,
          );

      batch.set(
        userRef,
        {
          'role': 'supplier',
          'supplierStatus': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      batch.set(
        supplierRef,
        {
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      await batch.commit();

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
  rejectSupplier(
    BuildContext context,
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    supplierDocument,
  ) async {
    final data = supplierDocument.data();
    final uid = getStringValue(
      data,
      'uid',
      supplierDocument.id,
    );

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
      final batch = FirebaseFirestore.instance.batch();

      final userRef = FirebaseFirestore.instance
          .collection(
            'users',
          )
          .doc(
            uid,
          );
      final supplierRef = FirebaseFirestore.instance
          .collection(
            'supplierProfiles',
          )
          .doc(
            uid,
          );

      batch.set(
        userRef,
        {
          'role': 'vendor',
          'supplierStatus': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      batch.set(
        supplierRef,
        {
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      await batch.commit();

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
                fontSize: 17,
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

  Widget statusChip(
    String status,
  ) {
    final color = statusColor(
      status,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(
          24,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: color.withAlpha(
            60,
          ),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget sectionTitle({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                const Color(
                  0xFF146BFF,
                ).withAlpha(
                  24,
                ),
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            color: const Color(
              0xFF146BFF,
            ),
            size: 20,
          ),
        ),
        const SizedBox(
          width: 10,
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
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 3,
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
      ],
    );
  }

  Widget header({
    required int usersCount,
    required int suppliersCount,
    required int pendingCount,
    required int ordersCount,
  }) {
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(
                    38,
                  ),
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              const Expanded(
                child: Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Builder(
                builder:
                    (
                      context,
                    ) {
                      return GestureDetector(
                        onTap: () => logout(
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
                            Icons.logout,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      );
                    },
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          const Text(
            'Monitor users, supplier applications, stocks, and COD orders.',
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
                value: '$usersCount',
                label: 'Users',
                icon: Icons.people,
              ),
              statCard(
                value: '$suppliersCount',
                label: 'Suppliers',
                icon: Icons.storefront,
              ),
              statCard(
                value: '$pendingCount',
                label: 'Pending',
                icon: Icons.hourglass_top,
              ),
              statCard(
                value: '$ordersCount',
                label: 'Orders',
                icon: Icons.receipt_long,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget pendingSupplierCard(
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

    final supplierName = getStringValue(
      data,
      'supplierName',
      'Supplier Application',
    );

    final ownerName = getStringValue(
      data,
      'ownerName',
      'Registered User',
    );

    final email = getStringValue(
      data,
      'email',
      'No email',
    );

    final phone = getStringValue(
      data,
      'phone',
      getStringValue(
        data,
        'contactNumber',
        'No contact number',
      ),
    );

    final location = getStringValue(
      data,
      'location',
      'Caraga Region',
    );

    final description = getStringValue(
      data,
      'description',
      'No description provided.',
    );

    return Container(
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
              0x12000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFF4E8,
                  ),
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: Color(
                    0xFFFF7A1A,
                  ),
                  size: 26,
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
                      supplierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Owner: $ownerName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              statusChip(
                'pending',
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
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
                  location,
                  style: const TextStyle(
                    color: Color(
                      0xFF52677A,
                    ),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 7,
          ),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
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
                  phone,
                  style: const TextStyle(
                    color: Color(
                      0xFF52677A,
                    ),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 7,
          ),
          Row(
            children: [
              const Icon(
                Icons.email_outlined,
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
                  email,
                  style: const TextStyle(
                    color: Color(
                      0xFF52677A,
                    ),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            description,
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => rejectSupplier(
                    context,
                    document,
                  ),
                  icon: const Icon(
                    Icons.close,
                  ),
                  label: const Text(
                    'Reject',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(
                      0xFFD32F2F,
                    ),
                    side: const BorderSide(
                      color: Color(
                        0xFFD32F2F,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => approveSupplier(
                    context,
                    document,
                  ),
                  icon: const Icon(
                    Icons.check_circle,
                  ),
                  label: const Text(
                    'Approve',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF146BFF,
                    ),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget approvedSupplierCard(
    QueryDocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
    document,
  ) {
    final data = document.data();

    final supplierName = getStringValue(
      data,
      'supplierName',
      'Approved Supplier',
    );

    final location = getStringValue(
      data,
      'location',
      'Caraga Region',
    );

    final status = getStringValue(
      data,
      'status',
      'approved',
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
              0x10000000,
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(
                0xFFEAF7FB,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.storefront,
              color: Color(
                0xFF146BFF,
              ),
              size: 23,
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
                  supplierName,
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
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          statusChip(
            status,
          ),
        ],
      ),
    );
  }

  Widget emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
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
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(
              0xFF146BFF,
            ),
            size: 42,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFF102C44,
              ),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
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
    final pendingSuppliers = suppliers.where(
      (
        document,
      ) {
        final status = getStringValue(
          document.data(),
          'status',
          'pending',
        ).toLowerCase();

        return status ==
            'pending';
      },
    ).toList();

    final approvedSuppliers = suppliers.where(
      (
        document,
      ) {
        final status = getStringValue(
          document.data(),
          'status',
          'pending',
        ).toLowerCase();

        return status ==
                'approved' ||
            status ==
                'active';
      },
    ).toList();

    return Column(
      children: [
        header(
          usersCount: users.length,
          suppliersCount: approvedSuppliers.length,
          pendingCount: pendingSuppliers.length,
          ordersCount: orders.length,
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
                title: 'Pending Supplier Applications',
                subtitle: 'Review vendor applications and approve or reject supplier access.',
                icon: Icons.hourglass_top,
              ),
              const SizedBox(
                height: 16,
              ),
              if (pendingSuppliers.isEmpty)
                emptyCard(
                  icon: Icons.check_circle_outline,
                  title: 'No pending supplier applications',
                  subtitle: 'Vendor applications will appear here after they tap Become a Supplier.',
                )
              else
                ...pendingSuppliers.map(
                  (
                    document,
                  ) => pendingSupplierCard(
                    context,
                    document,
                  ),
                ),
              const SizedBox(
                height: 26,
              ),
              sectionTitle(
                title: 'Approved Suppliers',
                subtitle: 'Suppliers with dashboard access and visible supplier profile status.',
                icon: Icons.verified,
              ),
              const SizedBox(
                height: 16,
              ),
              if (approvedSuppliers.isEmpty)
                emptyCard(
                  icon: Icons.storefront_outlined,
                  title: 'No approved suppliers yet',
                  subtitle: 'Approved suppliers will appear here after admin review.',
                )
              else
                ...approvedSuppliers.map(
                  approvedSupplierCard,
                ),
              const SizedBox(
                height: 26,
              ),
              sectionTitle(
                title: 'System Overview',
                subtitle: 'Quick snapshot of live Firestore records for thesis demonstration.',
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(
                height: 16,
              ),
              Container(
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
                child: Column(
                  children: [
                    overviewRow(
                      icon: Icons.people,
                      label: 'Registered users',
                      value: '${users.length}',
                    ),
                    overviewRow(
                      icon: Icons.storefront,
                      label: 'Supplier profiles',
                      value: '${suppliers.length}',
                    ),
                    overviewRow(
                      icon: Icons.inventory_2,
                      label: 'Fish stock posts',
                      value: '${stocks.length}',
                    ),
                    overviewRow(
                      icon: Icons.receipt_long,
                      label: 'COD orders',
                      value: '${orders.length}',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget overviewRow({
    required IconData icon,
    required String label,
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(
                0xFF146BFF,
              ),
              size: 21,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(
                    0xFF52677A,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(
                  0xFF102C44,
                ),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        if (showDivider)
          const Divider(
            height: 22,
          ),
      ],
    );
  }

  Widget loadingBody() {
    return const Scaffold(
      backgroundColor: Color(
        0xFFF4F8FB,
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget errorBody(
    Object error,
  ) {
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
          child: Text(
            'Unable to load admin dashboard: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(
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
    return StreamBuilder<
      QuerySnapshot<
        Map<
          String,
          dynamic
        >
      >
    >(
      stream: usersStream,
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
              stream: supplierProfilesStream,
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
                      stream: fishStocksStream,
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
                              stream: ordersStream,
                              builder:
                                  (
                                    context,
                                    ordersSnapshot,
                                  ) {
                                    if (usersSnapshot.hasError) {
                                      return errorBody(
                                        usersSnapshot.error!,
                                      );
                                    }

                                    if (suppliersSnapshot.hasError) {
                                      return errorBody(
                                        suppliersSnapshot.error!,
                                      );
                                    }

                                    if (stocksSnapshot.hasError) {
                                      return errorBody(
                                        stocksSnapshot.error!,
                                      );
                                    }

                                    if (ordersSnapshot.hasError) {
                                      return errorBody(
                                        ordersSnapshot.error!,
                                      );
                                    }

                                    if (!usersSnapshot.hasData ||
                                        !suppliersSnapshot.hasData ||
                                        !stocksSnapshot.hasData ||
                                        !ordersSnapshot.hasData) {
                                      return loadingBody();
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
}

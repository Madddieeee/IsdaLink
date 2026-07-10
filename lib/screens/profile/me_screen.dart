import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../supplier/supplier_dashboard_screen.dart';
import '../welcome_screen.dart';

class MeScreen
    extends
        StatelessWidget {
  const MeScreen({
    super.key,
  });

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<
    DocumentSnapshot<
      Map<
        String,
        dynamic
      >
    >
  >?
  get profileStream {
    final user = currentUser;

    if (user ==
        null) {
      return null;
    }

    return FirebaseFirestore.instance
        .collection(
          'users',
        )
        .doc(
          user.uid,
        )
        .snapshots();
  }

  String getStringValue(
    Map<
      String,
      dynamic
    >?
    data,
    String key,
    String fallback,
  ) {
    if (data ==
        null) {
      return fallback;
    }

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

  void openSupplierDashboard(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const SupplierDashboardScreen(),
      ),
    );
  }

  Future<
    void
  >
  submitSupplierApplication(
    BuildContext context,
    Map<
      String,
      dynamic
    >?
    profileData,
  ) async {
    final user = currentUser;

    if (user ==
        null) {
      showMessage(
        context,
        'Please log in first before applying as a supplier.',
        isError: true,
      );
      return;
    }

    final defaultName = getStringValue(
      profileData,
      'name',
      user.displayName ??
          'Registered Supplier',
    );

    final defaultEmail = getStringValue(
      profileData,
      'email',
      user.email ??
          '',
    );

    final defaultPhone = getStringValue(
      profileData,
      'phone',
      '',
    );

    final storeNameController = TextEditingController(
      text: defaultName,
    );
    final contactNumberController = TextEditingController(
      text: defaultPhone,
    );
    final locationController = TextEditingController(
      text: 'Caraga Region',
    );
    final descriptionController = TextEditingController(
      text: 'Fresh fish supplier serving vendors within Caraga Region.',
    );

    final applicationData =
        await showDialog<
          Map<
            String,
            String
          >
        >(
          context: context,
          barrierDismissible: false,
          builder:
              (
                dialogContext,
              ) {
                InputDecoration formStyle({
                  required String label,
                  required IconData icon,
                }) {
                  return InputDecoration(
                    labelText: label,
                    prefixIcon: Icon(
                      icon,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                  );
                }

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      22,
                    ),
                  ),
                  title: const Text(
                    'Supplier Application',
                    style: TextStyle(
                      color: Color(
                        0xFF102C44,
                      ),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Please provide supplier details for admin review. Supplier Dashboard access will be enabled only after approval.',
                          style: TextStyle(
                            color: Color(
                              0xFF52677A,
                            ),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextField(
                          controller: storeNameController,
                          decoration: formStyle(
                            label: 'Store / Business Name',
                            icon: Icons.storefront,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TextField(
                          controller: contactNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: formStyle(
                            label: 'Contact Number',
                            icon: Icons.phone_outlined,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TextField(
                          controller: locationController,
                          decoration: formStyle(
                            label: 'Market Location / Service Area',
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: formStyle(
                            label: 'Fish Supply Description',
                            icon: Icons.description_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                      ),
                      child: const Text(
                        'Cancel',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final storeName = storeNameController.text.trim();
                        final contactNumber = contactNumberController.text.trim();
                        final location = locationController.text.trim();
                        final description = descriptionController.text.trim();

                        if (storeName.isEmpty ||
                            contactNumber.isEmpty ||
                            location.isEmpty ||
                            description.isEmpty) {
                          ScaffoldMessenger.of(
                            dialogContext,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please complete all supplier details.',
                              ),
                              backgroundColor: Color(
                                0xFFD32F2F,
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(
                          dialogContext,
                          {
                            'storeName': storeName,
                            'contactNumber': contactNumber,
                            'location': location,
                            'description': description,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF146BFF,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Submit Application',
                      ),
                    ),
                  ],
                );
              },
        );

    if (applicationData ==
        null) {
      return;
    }

    final storeName = applicationData['storeName']!;
    final contactNumber = applicationData['contactNumber']!;
    final location = applicationData['location']!;
    final description = applicationData['description']!;

    try {
      await FirebaseFirestore.instance
          .collection(
            'users',
          )
          .doc(
            user.uid,
          )
          .set(
            {
              'uid': user.uid,
              'name': getStringValue(
                profileData,
                'name',
                user.displayName ??
                    'IsdaLink User',
              ),
              'email': defaultEmail,
              'phone': contactNumber,
              'role': 'vendor',
              'supplierStatus': 'pending',
              'supplierApplication': {
                'storeName': storeName,
                'contactNumber': contactNumber,
                'location': location,
                'description': description,
                'paymentMethod': 'COD',
                'submittedAt': FieldValue.serverTimestamp(),
              },
              'region': 'Caraga Region',
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );

      await FirebaseFirestore.instance
          .collection(
            'supplierProfiles',
          )
          .doc(
            user.uid,
          )
          .set(
            {
              'uid': user.uid,
              'supplierName': storeName,
              'ownerName': getStringValue(
                profileData,
                'name',
                user.displayName ??
                    'IsdaLink User',
              ),
              'email': defaultEmail,
              'phone': contactNumber,
              'contactNumber': contactNumber,
              'location': location,
              'description': description,
              'status': 'pending',
              'paymentMethod': 'COD',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(
              merge: true,
            ),
          );

      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Supplier application submitted. Please wait for admin approval.',
      );
    } catch (
      error
    ) {
      if (!context.mounted) {
        return;
      }

      showMessage(
        context,
        'Failed to submit supplier application: $error',
        isError: true,
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

  Widget menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(
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
            22,
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
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(
                  25,
                ),
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
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
                      fontWeight: FontWeight.w800,
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
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(
                0xFF9AAABD,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget profileStatusCard({
    required String role,
    required String supplierStatus,
  }) {
    String message;
    IconData icon;
    Color color;

    if (supplierStatus ==
        'approved') {
      message = 'Supplier account approved: Supplier Dashboard is now available for stock posting and COD order management.';
      icon = Icons.verified;
      color = const Color(
        0xFF2E7D32,
      );
    } else if (supplierStatus ==
        'pending') {
      message = 'Supplier application pending: Please wait for admin approval before accessing supplier tools.';
      icon = Icons.hourglass_top;
      color = const Color(
        0xFFFF7A1A,
      );
    } else {
      message = 'Vendor account: You can browse suppliers, place COD orders, and apply as a supplier when needed.';
      icon = Icons.info;
      color = const Color(
        0xFF146BFF,
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 18,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(
          22,
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: color.withAlpha(
            45,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(
                  0xFF52677A,
                ),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget header({
    required String name,
    required String role,
    required String supplierStatus,
  }) {
    final isSupplierApproved =
        supplierStatus ==
        'approved';
    final isPending =
        supplierStatus ==
        'pending';

    final accountLabel = isSupplierApproved
        ? 'Supplier Account • Caraga Region'
        : isPending
        ? 'Vendor Account • Supplier Application Pending'
        : 'Vendor Account • Caraga Region';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        54,
        20,
        28,
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
        children: [
          Row(
            children: [
              Builder(
                builder:
                    (
                      context,
                    ) {
                      return GestureDetector(
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
                      );
                    },
              ),
              const SizedBox(
                width: 12,
              ),
              const Expanded(
                child: Text(
                  'Me',
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
            height: 26,
          ),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                28,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(
                    0x22000000,
                  ),
                  blurRadius: 16,
                  offset: Offset(
                    0,
                    8,
                  ),
                ),
              ],
            ),
            child: Icon(
              isSupplierApproved
                  ? Icons.storefront
                  : Icons.person,
              color: const Color(
                0xFF146BFF,
              ),
              size: 46,
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            accountLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFFDCE9F5,
              ),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget bodyContent(
    BuildContext context,
    Map<
      String,
      dynamic
    >?
    profileData,
  ) {
    final user = currentUser;

    final fallbackName =
        user?.displayName?.trim().isNotEmpty ==
            true
        ? user!.displayName!.trim()
        : 'IsdaLink User';

    final name = getStringValue(
      profileData,
      'name',
      fallbackName,
    );

    final role = getStringValue(
      profileData,
      'role',
      'vendor',
    ).toLowerCase();

    final supplierStatus = getStringValue(
      profileData,
      'supplierStatus',
      'not_applicable',
    ).toLowerCase();

    final canOpenSupplierDashboard =
        role ==
            'supplier' ||
        supplierStatus ==
            'approved';

    final isPendingSupplier =
        supplierStatus ==
        'pending';

    return Column(
      children: [
        header(
          name: name,
          role: role,
          supplierStatus: supplierStatus,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(
              18,
            ),
            children: [
              profileStatusCard(
                role: role,
                supplierStatus: supplierStatus,
              ),
              if (canOpenSupplierDashboard)
                menuTile(
                  icon: Icons.dashboard_customize,
                  title: 'Supplier Dashboard',
                  subtitle: 'Open approved supplier tools for stocks, COD orders, and analytics.',
                  iconColor: const Color(
                    0xFF7B61FF,
                  ),
                  onTap: () => openSupplierDashboard(
                    context,
                  ),
                )
              else if (isPendingSupplier)
                menuTile(
                  icon: Icons.hourglass_top,
                  title: 'Supplier Application Pending',
                  subtitle: 'Admin approval is required before supplier tools become available.',
                  iconColor: const Color(
                    0xFFFF7A1A,
                  ),
                  onTap: () {
                    showMessage(
                      context,
                      'Your supplier application is still pending admin approval.',
                      isError: true,
                    );
                  },
                )
              else
                menuTile(
                  icon: Icons.inventory_2,
                  title: 'Become a Supplier',
                  subtitle: 'Submit store details for admin approval.',
                  onTap: () => submitSupplierApplication(
                    context,
                    profileData,
                  ),
                ),
              menuTile(
                icon: Icons.person_outline,
                title: 'Account Information',
                subtitle: 'View or update your profile information.',
                onTap: () {
                  showMessage(
                    context,
                    'Account information coming soon',
                  );
                },
              ),
              menuTile(
                icon: Icons.location_on_outlined,
                title: 'Region and Location',
                subtitle: 'Manage your market location and service area.',
                onTap: () {
                  showMessage(
                    context,
                    'Location settings coming soon',
                  );
                },
              ),
              menuTile(
                icon: Icons.help_outline,
                title: 'Help and Support',
                subtitle: 'Get help using IsdaLink features.',
                onTap: () {
                  showMessage(
                    context,
                    'Help and support coming soon',
                  );
                },
              ),
              menuTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Return to the welcome screen.',
                iconColor: const Color(
                  0xFFD32F2F,
                ),
                onTap: () => logout(
                  context,
                ),
              ),
            ],
          ),
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

  @override
  Widget build(
    BuildContext context,
  ) {
    final stream = profileStream;

    if (stream ==
        null) {
      return Scaffold(
        backgroundColor: const Color(
          0xFFF4F8FB,
        ),
        body: bodyContent(
          context,
          null,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body:
          StreamBuilder<
            DocumentSnapshot<
              Map<
                String,
                dynamic
              >
            >
          >(
            stream: stream,
            builder:
                (
                  context,
                  snapshot,
                ) {
                  if (!snapshot.hasData) {
                    return loadingBody();
                  }

                  return bodyContent(
                    context,
                    snapshot.data?.data(),
                  );
                },
          ),
    );
  }
}

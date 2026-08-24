import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/profile/supplier_verified_change_request_screen.dart';
import 'package:isdalink/services/supplier_notification_service.dart';
import 'package:isdalink/services/supplier_profile_service.dart';

class SupplierProfileScreen extends StatefulWidget {
  const SupplierProfileScreen({
    super.key,
  });

  @override
  State<SupplierProfileScreen> createState() =>
      _SupplierProfileScreenState();
}

class _SupplierProfileScreenState extends State<SupplierProfileScreen> {
  final profileService = const SupplierProfileService();
  final notificationService = const SupplierNotificationService();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String stringValue(
    Map<String, dynamic>? data,
    String key, [
    String fallback = '',
  ]) {
    final value = data?[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  List<String> supportedUnits(
    Map<String, dynamic>? data,
  ) {
    final raw = data?['supportedUnits'];

    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .map((value) => value.toString().trim().toLowerCase())
        .where(
          (value) => const {
            'kilo',
            'tab',
            'icebox',
          }.contains(value),
        )
        .toSet()
        .toList();
  }

  String unitLabel(String unit) {
    return switch (unit) {
      'kilo' => 'Kilogram',
      'tab' => 'Tab',
      'icebox' => 'Icebox',
      _ => unit,
    };
  }

  String storeImageUrl(Map<String, dynamic> data) {
    final storePhoto = stringValue(data, 'storePhotoUrl');
    if (storePhoto.isNotEmpty) {
      return storePhoto;
    }

    return stringValue(data, 'profileImageUrl');
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFD94A45)
              : const Color(0xFF147A5C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  Future<void> editPublicStoreInformation({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PublicStoreInformationEditSheet(
          initialContactNumber: stringValue(
            data,
            'contactNumber',
            stringValue(data, 'phone'),
          ),
          initialPrimaryMarketArea: stringValue(
            data,
            'primaryMarketArea',
            stringValue(data, 'serviceArea'),
          ),
          initialDescription: stringValue(
            data,
            'description',
          ),
          initialSupportedUnits: supportedUnits(data),
          unitLabel: unitLabel,
          onSave: ({
            required String contactNumber,
            required String primaryMarketArea,
            required String description,
            required List<String> supportedUnits,
          }) {
            return profileService.updatePublicStoreInformation(
              uid: uid,
              contactNumber: contactNumber,
              primaryMarketArea: primaryMarketArea,
              description: description,
              supportedUnits: supportedUnits,
            );
          },
        );
      },
    );

    if (updated == true) {
      showMessage(
        'Public store information updated.',
      );
    }
  }

  Future<void> withdrawVerifiedChangeRequest({
    required String uid,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Withdraw Change Request?',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'The pending request will be cancelled. Your currently approved supplier information will remain unchanged.',
            style: TextStyle(
              color: Color(0xFF52677A),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Keep Request'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFB06A17),
                foregroundColor: Colors.white,
              ),
              child: const Text('Withdraw'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await profileService.withdrawVerifiedChangeRequest(
        uid: uid,
      );

      showMessage(
        'Verified change request withdrawn.',
      );
    } catch (_) {
      showMessage(
        'Could not withdraw the request. Try again.',
        isError: true,
      );
    }
  }

  Future<void> acknowledgeProfileChangeNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notifications,
  ) async {
    try {
      await notificationService.markNotificationsRead(
        notifications,
      );
    } catch (_) {
      showMessage(
        'Could not dismiss the notification. Try again.',
        isError: true,
      );
    }
  }

  Future<void> openVerifiedChangeRequest({
    required String uid,
    required Map<String, dynamic> profileData,
    Map<String, dynamic>? previousRequestData,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SupplierVerifiedChangeRequestScreen(
          uid: uid,
          profileData: profileData,
          previousRequestData:
              previousRequestData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F8FB),
        body: Center(
          child: Text('No signed-in account.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: profileService.profileStream(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _SupplierProfileLoading();
            }

            final data = profileSnapshot.data?.data();

            if (data == null) {
              return _SupplierProfileUnavailable(
                onBack: () => Navigator.pop(context),
              );
            }

            final status = stringValue(
              data,
              'status',
              'approved',
            ).toLowerCase();

            if (status != 'approved' && status != 'active') {
              return _SupplierProfileUnavailable(
                onBack: () => Navigator.pop(context),
              );
            }

            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: profileService.changeRequestStream(user.uid),
              builder: (context, requestSnapshot) {
                final requestData = requestSnapshot.data?.data();
                final requestStatus = stringValue(
                  requestData,
                  'status',
                  'none',
                ).toLowerCase();
                final hasPendingRequest = requestStatus == 'pending';

                final storeName = stringValue(
                  data,
                  'storeName',
                  stringValue(
                    data,
                    'businessName',
                    'Fish Supplier',
                  ),
                );
                final ownerName = stringValue(
                  data,
                  'ownerName',
                  user.displayName ?? 'Supplier owner',
                );
                final contactNumber = stringValue(
                  data,
                  'contactNumber',
                  stringValue(data, 'phone', 'Not provided'),
                );
                final location = stringValue(
                  data,
                  'storeLocation',
                  stringValue(data, 'location', 'Location not available'),
                );
                final primaryMarketArea = stringValue(
                  data,
                  'primaryMarketArea',
                  stringValue(data, 'serviceArea', 'Not specified'),
                );
                final description = stringValue(
                  data,
                  'description',
                  'No store description added yet.',
                );
                final units = supportedUnits(data);

                return StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: notificationService.notificationsStream(
                    user.uid,
                  ),
                  builder: (context, notificationSnapshot) {
                    final notifications =
                        notificationSnapshot.data?.docs ??
                            <QueryDocumentSnapshot<
                                Map<String, dynamic>>>[];
                    final unreadProfileChanges = notificationService
                        .unreadProfileChangeNotifications(
                      notifications,
                    );
                    final matchingNotifications = unreadProfileChanges.where(
                      (notification) => stringValue(
                        notification.data(),
                        'status',
                      ).toLowerCase() == requestStatus,
                    );
                    final resolvedNotification = matchingNotifications.isEmpty
                        ? null
                        : matchingNotifications.first;
                    final showRequestStatus = hasPendingRequest ||
                        ((requestStatus == 'approved' ||
                                requestStatus == 'rejected') &&
                            resolvedNotification != null);

                    return Column(
                      children: [
                    _SupplierProfileTopBar(
                      onBack: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        children: [
                          _SupplierIdentityCard(
                            storeName: storeName,
                            location: location,
                            imageUrl: storeImageUrl(data),
                          ),
                          if (showRequestStatus) ...[
                            const SizedBox(height: 12),
                            _ChangeRequestStatusCard(
                              status: requestStatus,
                              adminNote: stringValue(
                                requestData,
                                'adminNote',
                              ),
                              changedFields: requestData?['changedFields'],
                              onWithdraw: hasPendingRequest
                                  ? () => withdrawVerifiedChangeRequest(
                                        uid: user.uid,
                                      )
                                  : null,
                              onAcknowledge: resolvedNotification == null
                                  ? null
                                  : () => acknowledgeProfileChangeNotifications(
                                        unreadProfileChanges,
                                      ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _SupplierProfileActionCard(
                            requestStatus: requestStatus,
                            onEditPublic: () => editPublicStoreInformation(
                              uid: user.uid,
                              data: data,
                            ),
                            onRequestVerified: () => openVerifiedChangeRequest(
                              uid: user.uid,
                              profileData: data,
                              previousRequestData:
                                  requestStatus == 'rejected' ||
                                          requestStatus == 'withdrawn'
                                      ? requestData
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ProfileSectionCard(
                            title: 'Public Storefront',
                            subtitle:
                                'Live information vendors can see and you can maintain directly',
                            icon: Icons.store_mall_directory_outlined,
                            children: [
                              _ProfileInfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Store contact',
                                value: contactNumber,
                              ),
                              _ProfileInfoRow(
                                icon: Icons.inventory_2_outlined,
                                label: 'Selling units',
                                value: units.isEmpty
                                    ? 'Not specified'
                                    : units.map(unitLabel).join(', '),
                              ),
                              _ProfileInfoRow(
                                icon: Icons.groups_2_outlined,
                                label: 'Primary market area',
                                value: primaryMarketArea,
                              ),
                              _ProfileDescriptionRow(
                                text: description,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ProfileSectionCard(
                            title: 'Protected Account Details',
                            subtitle:
                                'Owner identity and COD status remain tied to approval',
                            icon: Icons.shield_outlined,
                            locked: true,
                            children: [
                              _ProfileInfoRow(
                                icon: Icons.person_outline_rounded,
                                label: 'Verified owner',
                                value: ownerName,
                              ),
                              const _ProfileInfoRow(
                                icon: Icons.payments_outlined,
                                label: 'Payment method',
                                value: 'COD',
                                showDivider: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const _HybridPolicyNote(),
                        ],
                      ),
                    ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}


class _PublicStoreInformationEditSheet extends StatefulWidget {
  const _PublicStoreInformationEditSheet({
    required this.initialContactNumber,
    required this.initialPrimaryMarketArea,
    required this.initialDescription,
    required this.initialSupportedUnits,
    required this.unitLabel,
    required this.onSave,
  });

  final String initialContactNumber;
  final String initialPrimaryMarketArea;
  final String initialDescription;
  final List<String> initialSupportedUnits;
  final String Function(String unit) unitLabel;
  final Future<void> Function({
    required String contactNumber,
    required String primaryMarketArea,
    required String description,
    required List<String> supportedUnits,
  }) onSave;

  @override
  State<_PublicStoreInformationEditSheet> createState() =>
      _PublicStoreInformationEditSheetState();
}

class _PublicStoreInformationEditSheetState
    extends State<_PublicStoreInformationEditSheet> {
  late final TextEditingController contactController;
  late final TextEditingController marketAreaController;
  late final TextEditingController descriptionController;
  late final Set<String> selectedUnits;

  bool saving = false;

  @override
  void initState() {
    super.initState();
    contactController = TextEditingController(
      text: widget.initialContactNumber,
    );
    marketAreaController = TextEditingController(
      text: widget.initialPrimaryMarketArea,
    );
    descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    selectedUnits = widget.initialSupportedUnits.toSet();
  }

  @override
  void dispose() {
    contactController.dispose();
    marketAreaController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFD94A45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDCE7EF),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDCE7EF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF146BFF),
          width: 1.4,
        ),
      ),
    );
  }

  Future<void> save() async {
    if (saving) {
      return;
    }

    final contact = contactController.text.trim();
    final marketArea = marketAreaController.text.trim();
    final description = descriptionController.text.trim();

    if (contact.length < 7 || contact.length > 30) {
      showError('Enter a valid store contact number.');
      return;
    }

    if (marketArea.length < 2 || marketArea.length > 120) {
      showError('Enter a valid primary market area.');
      return;
    }

    if (description.length < 8 || description.length > 240) {
      showError(
        'Use 8 to 240 characters for the store description.',
      );
      return;
    }

    if (selectedUnits.isEmpty) {
      showError(
        'Select at least one supported selling unit.',
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final units = selectedUnits.toList()..sort();

      await widget.onSave(
        contactNumber: contact,
        primaryMarketArea: marketArea,
        description: description,
        supportedUnits: units,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        saving = false;
      });

      showError(
        'Could not update the supplier profile. Check your connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F9FC),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(29),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          22 + bottomInset,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0DCE5),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                _SheetIcon(
                  icon: Icons.edit_rounded,
                ),
                SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Public Storefront',
                        style: TextStyle(
                          color: Color(0xFF102C44),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'These storefront details update immediately and do not affect verified business identity.',
                        style: TextStyle(
                          color: Color(0xFF718699),
                          fontSize: 9.2,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: contactController,
              keyboardType: TextInputType.phone,
              decoration: inputDecoration(
                label: 'Store contact number',
                icon: Icons.phone_outlined,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: marketAreaController,
              decoration: inputDecoration(
                label: 'Primary market area',
                icon: Icons.groups_2_outlined,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Supported selling units',
              style: TextStyle(
                color: Color(0xFF17354D),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose the units currently offered by your store.',
              style: TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 8.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                'kilo',
                'tab',
                'icebox',
              ].map((unit) {
                final selected = selectedUnits.contains(unit);

                return FilterChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.inventory_2_outlined,
                    size: 16,
                  ),
                  label: Text(
                    widget.unitLabel(unit),
                  ),
                  onSelected: saving
                      ? null
                      : (value) {
                          setState(() {
                            if (value) {
                              selectedUnits.add(unit);
                            } else {
                              selectedUnits.remove(unit);
                            }
                          });
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: inputDecoration(
                label: 'Store description',
                icon: Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: saving ? null : save,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  saving ? 'Saving...' : 'Save Storefront Changes',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF146BFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierProfileTopBar extends StatelessWidget {
  const _SupplierProfileTopBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2EBF2)),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF146BFF),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supplier Profile',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Manage your supplier storefront and verified details',
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 9.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F8F2),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF1C9B6C),
                  size: 13,
                ),
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    color: Color(0xFF147650),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierIdentityCard extends StatelessWidget {
  const _SupplierIdentityCard({
    required this.storeName,
    required this.location,
    required this.imageUrl,
  });

  final String storeName;
  final String location;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF074F86),
            Color(0xFF087FC5),
            Color(0xFF13A9C9),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25125C89),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.17,
                  ),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.45,
                    ),
                    width: 1.3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: imageUrl.isEmpty
                      ? const ColoredBox(
                          color: Color(0x1AFFFFFF),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const ColoredBox(
                              color: Color(0x1AFFFFFF),
                              child: Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(
                              99,
                            ),
                          ),
                          child: const Text(
                            'YOUR SUPPLIER STORE',
                            style: TextStyle(
                              color: Color(0xFFD9F7FF),
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: Color(0xFFBFF5D8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFE7F5FB),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE7F5FB),
                              fontSize: 9.2,
                              height: 1.28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.14,
                ),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 15,
                  color: Color(0xFFDDF7FF),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Verified business details stay protected. Storefront details remain easy to maintain.',
                    style: TextStyle(
                      color: Color(0xFFE8F8FC),
                      fontSize: 8.6,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierProfileActionCard extends StatelessWidget {
  const _SupplierProfileActionCard({
    required this.requestStatus,
    required this.onEditPublic,
    required this.onRequestVerified,
  });

  final String requestStatus;
  final VoidCallback onEditPublic;
  final VoidCallback onRequestVerified;

  @override
  Widget build(BuildContext context) {
    final pending = requestStatus == 'pending';
    final rejected = requestStatus == 'rejected';
    final withdrawn = requestStatus == 'withdrawn';

    final requestSubtitle = pending
        ? 'Your verified request is waiting for Admin review'
        : rejected
            ? 'Revise the rejected request using the previous details'
            : withdrawn
                ? 'Continue from the withdrawn request or start fresh'
                : 'Store identity, location, store photo and permit';

    final requestLabel = pending
        ? 'Pending'
        : rejected
            ? 'Revise'
            : withdrawn
                ? 'Continue'
                : 'Request';

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE0EAF1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D102C44),
            blurRadius: 15,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Supplier Profile',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Choose the type of information you want to update.',
            style: TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 11),
          _ProfileManagementAction(
            icon: Icons.edit_note_rounded,
            iconBackground:
                const Color(0xFFEAF5FF),
            iconColor: const Color(0xFF146BFF),
            title: 'Edit Public Storefront',
            subtitle:
                'Contact, selling units, market area and description',
            trailingLabel: 'Edit now',
            onTap: onEditPublic,
          ),
          const SizedBox(height: 9),
          _ProfileManagementAction(
            icon: pending
                ? Icons.hourglass_top_rounded
                : rejected
                    ? Icons.refresh_rounded
                    : Icons.verified_user_outlined,
            iconBackground: pending
                ? const Color(0xFFFFF4DE)
                : rejected
                    ? const Color(0xFFFFEEEE)
                    : const Color(0xFFF1F4FF),
            iconColor: pending
                ? const Color(0xFFAF7516)
                : rejected
                    ? const Color(0xFFB53A36)
                    : const Color(0xFF5369D8),
            title: 'Verified Business Details',
            subtitle: requestSubtitle,
            trailingLabel: requestLabel,
            onTap: pending ? null : onRequestVerified,
          ),
        ],
      ),
    );
  }
}

class _ProfileManagementAction extends StatelessWidget {
  const _ProfileManagementAction({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailingLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailingLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Material(
      color: const Color(0xFFF8FBFD),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE4EDF3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF17354D),
                        fontSize: 11.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 8.6,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0xFFEAF4FF)
                      : const Color(0xFFFFF3DC),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  trailingLabel,
                  style: TextStyle(
                    color: enabled
                        ? const Color(0xFF146BFF)
                        : const Color(0xFFA76F15),
                    fontSize: 7.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChangeRequestStatusCard extends StatelessWidget {
  const _ChangeRequestStatusCard({
    required this.status,
    required this.adminNote,
    required this.changedFields,
    required this.onWithdraw,
    required this.onAcknowledge,
  });

  final String status;
  final String adminNote;
  final dynamic changedFields;
  final VoidCallback? onWithdraw;
  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    final approved = status == 'approved';

    final title = pending
        ? 'Pending Admin Review'
        : approved
            ? 'Verified change approved'
            : 'Change request needs revision';

    final subtitle = pending
        ? 'Your current approved profile stays public while Admin reviews the request.'
        : approved
            ? 'The approved verified changes are now live in your supplier profile.'
            : adminNote.isEmpty
                ? 'Your approved profile was not changed. Revise the request and submit again.'
                : 'Admin note: $adminNote';

    final icon = pending
        ? Icons.hourglass_top_rounded
        : approved
            ? Icons.check_circle_rounded
            : Icons.info_outline_rounded;

    final background = pending
        ? const Color(0xFFFFF8E9)
        : approved
            ? const Color(0xFFECF8F4)
            : const Color(0xFFFFEEEE);

    final foreground = pending
        ? const Color(0xFF956A15)
        : approved
            ? const Color(0xFF16845C)
            : const Color(0xFFB53A36);

    final changes = changedFields is List
        ? (changedFields as List)
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toList()
        : const <String>[];

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: foreground.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: foreground,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 11.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: foreground.withValues(
                          alpha: 0.84,
                        ),
                        fontSize: 9.1,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: changes
                  .map(
                    (change) => Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: foreground.withValues(
                          alpha: 0.09,
                        ),
                        borderRadius:
                            BorderRadius.circular(99),
                      ),
                      child: Text(
                        change,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 7.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (pending && onWithdraw != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: onWithdraw,
                icon: const Icon(
                  Icons.undo_rounded,
                  size: 15,
                ),
                label: const Text(
                  'Withdraw Pending Request',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: foreground,
                  side: BorderSide(
                    color: foreground.withValues(
                      alpha: 0.35,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (!pending && onAcknowledge != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: FilledButton.icon(
                onPressed: onAcknowledge,
                icon: const Icon(
                  Icons.done_rounded,
                  size: 16,
                ),
                label: const Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 9.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: foreground,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.locked = false,
  })  : actionLabel = null,
        onAction = null,
        actionDisabled = false;

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool actionDisabled;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0EAF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C102C44),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: locked
                      ? const Color(0xFFEDF8F3)
                      : const Color(0xFFEAF7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: locked
                      ? const Color(0xFF16845C)
                      : const Color(0xFF146BFF),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 9.1,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                const _ProtectedPill()
              else if (actionLabel != null)
                TextButton(
                  onPressed: actionDisabled ? null : onAction,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 9.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ProtectedPill extends StatelessWidget {
  const _ProtectedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF8F3),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_rounded,
            color: Color(0xFF16845C),
            size: 11,
          ),
          SizedBox(width: 3),
          Text(
            'Protected',
            style: TextStyle(
              color: Color(0xFF147650),
              fontSize: 7.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: Color(0xFFEDF2F6)),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4D7C9C),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 11.2,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDescriptionRow extends StatelessWidget {
  const _ProfileDescriptionRow({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFF5FAFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE1ECF3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Store description',
              style: TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 8.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF516B7E),
                fontSize: 10.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HybridPolicyNote extends StatelessWidget {
  const _HybridPolicyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFF1E2B8)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security_rounded,
            color: Color(0xFF9B721F),
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Storefront details can be maintained directly. Verified identity, business location, store photo, and permit changes are reviewed by the administrator before they replace the approved information shown to vendors.',
              style: TextStyle(
                color: Color(0xFF745A25),
                fontSize: 9.4,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetIcon extends StatelessWidget {
  const _SheetIcon({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF146BFF),
            Color(0xFF0B91C8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 21,
      ),
    );
  }
}

class _SupplierProfileLoading extends StatelessWidget {
  const _SupplierProfileLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SupplierProfileTopBar(
          onBack: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}

class _SupplierProfileUnavailable extends StatelessWidget {
  const _SupplierProfileUnavailable({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SupplierProfileTopBar(onBack: onBack),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE0EAF1)),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      color: Color(0xFF7B8FA3),
                      size: 36,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Supplier profile unavailable',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'An approved supplier profile is required to manage this page.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 10.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

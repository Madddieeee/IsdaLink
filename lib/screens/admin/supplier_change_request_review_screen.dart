import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/admin/widgets/admin_supplier_cards.dart';
import 'package:isdalink/screens/map/caraga_location_picker_screen.dart';
import 'package:isdalink/services/admin_dashboard_service.dart';

class SupplierChangeRequestReviewScreen extends StatelessWidget {
  const SupplierChangeRequestReviewScreen({
    super.key,
    required this.supplierId,
  });

  final String supplierId;

  AdminDashboardService get adminService => const AdminDashboardService();

  String stringValue(
    Map<String, dynamic>? data,
    String key, [
    String fallback = '',
  ]) {
    final value = data?[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  double? coordinate(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  Map<String, dynamic> supplierApplication(Map<String, dynamic>? userData) {
    final raw = userData?['supplierApplication'];

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return <String, dynamic>{};
  }

  String formattedDate(dynamic value) {
    final date = value is Timestamp ? value.toDate() : null;

    if (date == null) {
      return 'Recently submitted';
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} ${date.day}, ${date.year} • $hour:$minute $period';
  }

  Future<String?> requestAdminNote(
    BuildContext context, {
    required bool rejecting,
  }) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            rejecting ? 'Reject Change Request?' : 'Approve Change Request?',
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rejecting
                    ? 'The current approved supplier information will remain unchanged. Add a short reason so the supplier knows what to correct.'
                    : 'The requested verified information will replace the current approved supplier information shown to vendors. The requested store photo will also become the supplier/store profile image across IsdaLink.',
                style: const TextStyle(
                  color: Color(0xFF52677A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: rejecting
                      ? 'Rejection reason'
                      : 'Optional admin note',
                  hintText: rejecting
                      ? 'Example: Upload a clearer current store photo.'
                      : 'Optional note for the supplier',
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final note = controller.text.trim();

                if (rejecting && note.length < 3) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Add a short rejection reason.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, note);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: rejecting
                    ? const Color(0xFFD94A45)
                    : const Color(0xFF146BFF),
                foregroundColor: Colors.white,
              ),
              child: Text(rejecting ? 'Reject Request' : 'Approve Change'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> approve(
    BuildContext context,
  ) async {
    final note = await requestAdminNote(
      context,
      rejecting: false,
    );

    if (note == null || !context.mounted) {
      return;
    }

    try {
      await adminService.approveSupplierChangeRequest(
        supplierId,
        adminNote: note,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supplier verified changes approved.'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not approve request: $error'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  Future<void> reject(
    BuildContext context,
  ) async {
    final note = await requestAdminNote(
      context,
      rejecting: true,
    );

    if (note == null || !context.mounted) {
      return;
    }

    try {
      await adminService.rejectSupplierChangeRequest(
        supplierId,
        adminNote: note,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supplier change request rejected.'),
          backgroundColor: Color(0xFFB06A17),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not reject request: $error'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  void openMap(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String province,
    required String locality,
    required double? latitude,
    required double? longitude,
    required String markerTitle,
  }) {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid map pin is available for this location.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaragaLocationPickerScreen(
          title: title,
          subtitle: subtitle,
          province: province,
          locality: locality,
          initialLatitude: latitude,
          initialLongitude: longitude,
          instructionText:
              'Read-only business location reference for administrator review.',
          markerTitle: markerTitle,
          confirmButtonLabel: 'Close Map',
          readOnly: true,
        ),
      ),
    );
  }

  List<String> changedFields(
    Map<String, dynamic> request,
  ) {
    final raw = request['changedFields'];

    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  bool hasChange(
    Map<String, dynamic> request,
    String label,
  ) {
    return changedFields(request).contains(label);
  }

  @override
  Widget build(BuildContext context) {
    final requestRef = FirebaseFirestore.instance
        .collection('supplierChangeRequests')
        .doc(supplierId);
    final profileRef = FirebaseFirestore.instance
        .collection('supplierProfiles')
        .doc(supplierId);
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(supplierId);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102C44),
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Verified Change',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Current approved information vs supplier request',
              style: TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: requestRef.snapshots(),
        builder: (context, requestSnapshot) {
          if (!requestSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final request = requestSnapshot.data?.data();

          if (request == null) {
            return const Center(
              child: Text('Change request not found.'),
            );
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: profileRef.snapshots(),
            builder: (context, profileSnapshot) {
              if (!profileSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final profile = profileSnapshot.data?.data();

              if (profile == null) {
                return const Center(
                  child: Text('Supplier profile not found.'),
                );
              }

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: userRef.snapshots(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final application = supplierApplication(
                    userSnapshot.data?.data(),
                  );
                  final requestStatus = stringValue(
                    request,
                    'status',
                    'pending',
                  ).toLowerCase();
                  final isPending = requestStatus == 'pending';

                  final currentName = stringValue(
                    profile,
                    'storeName',
                    stringValue(profile, 'supplierName', 'Fish Supplier'),
                  );
                  final requestedName = stringValue(
                    request,
                    'requestedStoreName',
                    currentName,
                  );
                  final currentLocation = stringValue(
                    profile,
                    'storeLocation',
                    stringValue(profile, 'location', 'Not available'),
                  );
                  final requestedLocation = stringValue(
                    request,
                    'requestedLocation',
                    currentLocation,
                  );
                  final currentProvince = stringValue(
                    profile,
                    'storeProvince',
                  );
                  final requestedProvince = stringValue(
                    request,
                    'requestedStoreProvince',
                    currentProvince,
                  );
                  final currentCity = stringValue(
                    profile,
                    'storeCityMunicipality',
                  );
                  final requestedCity = stringValue(
                    request,
                    'requestedStoreCityMunicipality',
                    currentCity,
                  );
                  final currentPermitNumber = stringValue(
                    application,
                    'businessPermitNumber',
                    'Not available',
                  );
                  final requestedPermitNumber = stringValue(
                    request,
                    'requestedBusinessPermitNumber',
                    currentPermitNumber,
                  );
                  final currentPermitUrl = stringValue(
                    application,
                    'businessPermitUrl',
                  );
                  final requestedPermitUrl = stringValue(
                    request,
                    'requestedBusinessPermitUrl',
                  );
                  final currentStorePhoto = stringValue(
                    profile,
                    'storePhotoUrl',
                    stringValue(profile, 'profileImageUrl'),
                  );
                  final requestedStorePhoto = stringValue(
                    request,
                    'requestedStorePhotoUrl',
                  );

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      _RequestHeaderCard(
                        supplierName: currentName,
                        status: requestStatus,
                        submittedAt: formattedDate(request['submittedAt']),
                        changedFields: request['changedFields'],
                      ),
                      const SizedBox(height: 12),
                      _RequestReasonCard(
                        reason: stringValue(
                          request,
                          'reason',
                          'No reason provided',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _ApprovalImpactCard(),
                      const SizedBox(height: 12),
                      if (hasChange(request, 'Store name') ||
                          hasChange(request, 'Business permit'))
                        _CompareSection(
                        title: 'Business Identity',
                        icon: Icons.storefront_rounded,
                        currentChildren: [
                          _ReviewInfoRow(
                            label: 'Store / business name',
                            value: currentName,
                          ),
                          _ReviewInfoRow(
                            label: 'Permit number',
                            value: currentPermitNumber,
                            showDivider: false,
                          ),
                        ],
                        requestedChildren: [
                          _ReviewInfoRow(
                            label: 'Store / business name',
                            value: requestedName,
                          ),
                          _ReviewInfoRow(
                            label: 'Permit number',
                            value: requestedPermitNumber,
                            showDivider: false,
                          ),
                        ],
                      ),
                      if (hasChange(request, 'Store name') ||
                          hasChange(request, 'Business permit'))
                        const SizedBox(height: 12),
                      if (hasChange(request, 'Business location'))
                        _CompareSection(
                        title: 'Business Location',
                        icon: Icons.location_on_rounded,
                        currentChildren: [
                          _ReviewInfoRow(
                            label: 'Approved location',
                            value: currentLocation,
                          ),
                          _MapReviewButton(
                            label: 'View Current Map Pin',
                            onTap: () => openMap(
                              context,
                              title: '$currentName Current Location',
                              subtitle: '$currentCity, $currentProvince',
                              province: currentProvince,
                              locality: currentCity,
                              latitude: coordinate(profile['storeLatitude']),
                              longitude: coordinate(profile['storeLongitude']),
                              markerTitle: 'Current approved store',
                            ),
                          ),
                        ],
                        requestedChildren: [
                          _ReviewInfoRow(
                            label: 'Requested location',
                            value: requestedLocation,
                          ),
                          _MapReviewButton(
                            label: 'View Requested Map Pin',
                            onTap: () => openMap(
                              context,
                              title: '$currentName Requested Location',
                              subtitle: '$requestedCity, $requestedProvince',
                              province: requestedProvince,
                              locality: requestedCity,
                              latitude: coordinate(
                                request['requestedStoreLatitude'],
                              ),
                              longitude: coordinate(
                                request['requestedStoreLongitude'],
                              ),
                              markerTitle: 'Requested supplier store',
                            ),
                          ),
                        ],
                      ),
                      if (hasChange(request, 'Business location'))
                        const SizedBox(height: 12),
                      if (hasChange(request, 'Store photo') ||
                          hasChange(request, 'Business permit'))
                        _CompareSection(
                        title: 'Verification Evidence',
                        icon: Icons.photo_library_outlined,
                        currentChildren: [
                          _EvidencePreview(
                            label: 'Current store photo',
                            imageUrl: currentStorePhoto,
                          ),
                          const SizedBox(height: 10),
                          VerificationLinkButton(
                            label: 'Current Permit',
                            icon: Icons.description_outlined,
                            url: currentPermitUrl,
                          ),
                        ],
                        requestedChildren: [
                          _EvidencePreview(
                            label: 'Requested store photo',
                            imageUrl: requestedStorePhoto,
                          ),
                          const SizedBox(height: 10),
                          VerificationLinkButton(
                            label: 'Requested Permit',
                            icon: Icons.description_outlined,
                            url: requestedPermitUrl,
                          ),
                        ],
                      ),
                      if (!isPending) ...[
                        const SizedBox(height: 12),
                        _DecisionResultCard(
                          status: requestStatus,
                          adminNote: stringValue(request, 'adminNote'),
                        ),
                      ],
                      if (isPending) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => reject(context),
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD94A45),
                                  side: const BorderSide(
                                    color: Color(0xFFD94A45),
                                  ),
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => approve(context),
                                icon: const Icon(Icons.check_circle_rounded),
                                label: const Text('Approve Change'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF146BFF),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestHeaderCard extends StatelessWidget {
  const _RequestHeaderCard({
    required this.supplierName,
    required this.status,
    required this.submittedAt,
    required this.changedFields,
  });

  final String supplierName;
  final String status;
  final String submittedAt;
  final dynamic changedFields;

  @override
  Widget build(BuildContext context) {
    final changes = changedFields is List
        ? (changedFields as List)
            .map((value) => value.toString())
            .toList()
        : const <String>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102C44),
            Color(0xFF146BFF),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rule_folder_outlined,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Submitted $submittedAt',
            style: const TextStyle(
              color: Color(0xFFDCE9F5),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (changes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: changes
                  .map(
                    (change) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        change,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestReasonCard extends StatelessWidget {
  const _RequestReasonCard({
    required this.reason,
  });

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDDE8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF146BFF),
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supplier reason',
                  style: TextStyle(
                    color: Color(0xFF17354D),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    color: Color(0xFF5C7183),
                    fontSize: 9.2,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
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

class _ApprovalImpactCard extends StatelessWidget {
  const _ApprovalImpactCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF0E0B5),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            color: Color(0xFF9B721F),
            size: 19,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Approval replaces the currently approved verified business information. The requested store photo also becomes the main supplier/store profile image. Rejection leaves all current public information unchanged.',
              style: TextStyle(
                color: Color(0xFF745A25),
                fontSize: 9.3,
                height: 1.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareSection extends StatelessWidget {
  const _CompareSection({
    required this.title,
    required this.icon,
    required this.currentChildren,
    required this.requestedChildren,
  });

  final String title;
  final IconData icon;
  final List<Widget> currentChildren;
  final List<Widget> requestedChildren;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0EAF1)),
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
                  color: const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF146BFF),
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ComparisonColumn(
            label: 'CURRENT APPROVED',
            accent: const Color(0xFF5B7488),
            background: const Color(0xFFF6F9FB),
            children: currentChildren,
          ),
          const SizedBox(height: 10),
          _ComparisonColumn(
            label: 'REQUESTED',
            accent: const Color(0xFF146BFF),
            background: const Color(0xFFF1F7FF),
            children: requestedChildren,
          ),
        ],
      ),
    );
  }
}

class _ComparisonColumn extends StatelessWidget {
  const _ComparisonColumn({
    required this.label,
    required this.accent,
    required this.background,
    required this.children,
  });

  final String label;
  final Color accent;
  final Color background;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 8.4,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          ...children,
        ],
      ),
    );
  }
}

class _ReviewInfoRow extends StatelessWidget {
  const _ReviewInfoRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE2EBF1)),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 8.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF17354D),
              fontSize: 10.5,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapReviewButton extends StatelessWidget {
  const _MapReviewButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.map_outlined, size: 17),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF146BFF),
          side: const BorderSide(color: Color(0xFFB9D3F4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}

class _EvidencePreview extends StatelessWidget {
  const _EvidencePreview({
    required this.label,
    required this.imageUrl,
  });

  final String label;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7B8FA3),
            fontSize: 8.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: double.infinity,
            height: 145,
            color: const Color(0xFFEAF2F7),
            child: imageUrl.trim().isEmpty
                ? const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF7B8FA3),
                      size: 32,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF7B8FA3),
                        size: 32,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DecisionResultCard extends StatelessWidget {
  const _DecisionResultCard({
    required this.status,
    required this.adminNote,
  });

  final String status;
  final String adminNote;

  @override
  Widget build(BuildContext context) {
    final approved = status == 'approved';
    final foreground = approved
        ? const Color(0xFF16845C)
        : const Color(0xFFB53A36);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: approved
            ? const Color(0xFFECF8F4)
            : const Color(0xFFFFEEEE),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            approved ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: foreground,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              adminNote.isEmpty
                  ? (approved
                      ? 'This verified change request was approved.'
                      : 'This verified change request was rejected.')
                  : 'Admin note: $adminNote',
              style: TextStyle(
                color: foreground,
                fontSize: 9.6,
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

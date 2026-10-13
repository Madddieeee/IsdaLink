import 'package:flutter/material.dart';
import 'package:isdalink/screens/admin/widgets/admin_status_chip.dart';
import 'package:isdalink/screens/admin/widgets/admin_supplier_cards.dart';

class AdminSupplierDetailScreen extends StatefulWidget {
  const AdminSupplierDetailScreen({
    super.key,
    required this.supplierData,
    required this.userData,
    required this.status,
    this.onApprove,
    this.onReject,
  });

  final Map<String, dynamic> supplierData;
  final Map<String, dynamic> userData;
  final String status;
  final Future<bool> Function()? onApprove;
  final Future<bool> Function()? onReject;

  @override
  State<AdminSupplierDetailScreen> createState() =>
      _AdminSupplierDetailScreenState();
}

class _AdminSupplierDetailScreenState
    extends State<AdminSupplierDetailScreen> {
  bool actionRunning = false;

  Map<String, dynamic> get application {
    final raw = widget.userData['supplierApplication'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }

  String value(List<String> keys, String fallback) {
    for (final source in <Map<String, dynamic>>[
      widget.supplierData,
      application,
      widget.userData,
    ]) {
      for (final key in keys) {
        final text = source[key]?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
    }
    return fallback;
  }

  Future<void> runAction(Future<bool> Function()? action) async {
    if (action == null || actionRunning) return;
    setState(() => actionRunning = true);
    final succeeded = await action();
    if (!mounted) return;
    setState(() => actionRunning = false);
    if (succeeded) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final supplierName = value(
      const ['supplierName', 'storeName', 'businessName'],
      'Supplier',
    );
    final ownerName = value(const ['ownerName', 'fullName'], 'Not provided');
    final location = value(
      const ['storeLocation', 'location'],
      'Not provided',
    );
    final address = value(
      const ['storeAddress', 'ownerAddress'],
      'Not provided',
    );
    final serviceArea = value(const ['serviceArea'], location);
    final phone = value(
      const ['phone', 'contactNumber'],
      'Not provided',
    );
    final email = value(const ['email'], 'Not provided');
    final permitNumber = value(
      const ['businessPermitNumber'],
      'Not provided',
    );
    final description = value(
      const ['description'],
      'No business description provided.',
    );
    final rejectionReason = value(
      const ['rejectionReason'],
      'No rejection reason recorded.',
    );
    final storePhoto = value(
      const ['storePhotoUrl', 'profileImageUrl'],
      '',
    );
    final permitUrl = value(const ['businessPermitUrl'], '');
    final permitPath = value(const ['businessPermitStoragePath'], '');
    final pending = widget.status.toLowerCase() == 'pending';
    final rejected = widget.status.toLowerCase() == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102C44),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Supplier Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE1EAF1)),
              ),
              child: Row(
                children: [
                  SupplierPhotoPreview(
                    imageUrl: storePhoto,
                    size: 58,
                    fallbackColor: const Color(0xFFEAF3FF),
                    iconColor: const Color(0xFF146BFF),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplierName,
                          style: const TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Owner: $ownerName',
                          style: const TextStyle(
                            color: Color(0xFF71869A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdminStatusChip(status: widget.status),
                ],
              ),
            ),
            if (rejected) ...[
              const SizedBox(height: 14),
              _NoticeCard(
                title: 'Reason for decline',
                message: rejectionReason,
                color: const Color(0xFFD32F2F),
                icon: Icons.info_outline,
              ),
            ],
            const SizedBox(height: 18),
            _DetailSection(
              title: 'Business information',
              children: [
                _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: location),
                _DetailRow(icon: Icons.home_outlined, label: 'Address', value: address),
                _DetailRow(icon: Icons.map_outlined, label: 'Service area', value: serviceArea),
                _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: phone),
                _DetailRow(icon: Icons.email_outlined, label: 'Email', value: email),
                _DetailRow(icon: Icons.confirmation_number_outlined, label: 'Permit number', value: permitNumber),
              ],
            ),
            const SizedBox(height: 14),
            _DetailSection(
              title: 'Description',
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailSection(
              title: 'Verification evidence',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: VerificationLinkButton(
                        label: 'Permit',
                        icon: Icons.description_outlined,
                        url: permitUrl,
                        storagePath: permitPath,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: VerificationLinkButton(
                        label: 'Store photo',
                        icon: Icons.photo_outlined,
                        url: storePhoto,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (pending) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: actionRunning
                          ? null
                          : () => runAction(widget.onReject),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: actionRunning
                          ? null
                          : () => runAction(widget.onApprove),
                      icon: actionRunning
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF146BFF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF146BFF), size: 19),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF334B5F),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String title;
  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 12,
                    height: 1.4,
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

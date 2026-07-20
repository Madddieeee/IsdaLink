import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/admin/widgets/admin_status_chip.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingSupplierCard extends StatelessWidget {
  const PendingSupplierCard({
    super.key,
    required this.document,
    required this.onApprove,
    required this.onReject,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  String getStringValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  String supportedUnitLabel(
    Map<String, dynamic> data,
  ) {
    final units = data['supportedUnits'];

    if (units is List && units.isNotEmpty) {
      return units.map((unit) => unit.toString()).join(', ');
    }

    return 'No selected units';
  }

  @override
  Widget build(
    BuildContext context,
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

    final ownerAddress = getStringValue(
      data,
      'ownerAddress',
      'No owner address',
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

    final serviceArea = getStringValue(
      data,
      'serviceArea',
      location,
    );

    final permitNumber = getStringValue(
      data,
      'businessPermitNumber',
      'No permit number',
    );

    final businessPermitUrl = getStringValue(
      data,
      'businessPermitUrl',
      '',
    );

    final storePhotoUrl = getStringValue(
      data,
      'storePhotoUrl',
      '',
    );

    final description = getStringValue(
      data,
      'description',
      'No description provided.',
    );

    final verificationStatus = getStringValue(
      data,
      'verificationStatus',
      'pending',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SupplierPhotoPreview(
                imageUrl: storePhotoUrl,
                size: 50,
                fallbackColor: const Color(0xFFFFF4E8),
                iconColor: const Color(0xFFFF7A1A),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplierName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Owner: $ownerName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AdminStatusChip(
                status: verificationStatus,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SupplierInfoRow(
            icon: Icons.home_outlined,
            value: ownerAddress,
          ),
          const SizedBox(height: 7),
          SupplierInfoRow(
            icon: Icons.location_on_outlined,
            value: location,
          ),
          const SizedBox(height: 7),
          SupplierInfoRow(
            icon: Icons.map_outlined,
            value: 'Service Area: $serviceArea',
          ),
          const SizedBox(height: 7),
          SupplierInfoRow(
            icon: Icons.phone_outlined,
            value: phone,
          ),
          const SizedBox(height: 7),
          SupplierInfoRow(
            icon: Icons.email_outlined,
            value: email,
          ),
          const SizedBox(height: 7),
          SupplierInfoRow(
            icon: Icons.scale_outlined,
            value: 'Supported Units: ${supportedUnitLabel(data)}',
          ),
          const SizedBox(height: 7),
          SupplierInfoRow(
            icon: Icons.confirmation_number_outlined,
            value: 'Permit No.: $permitNumber',
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF52677A),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: VerificationLinkButton(
                  label: 'Permit',
                  icon: Icons.description,
                  url: businessPermitUrl,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: VerificationLinkButton(
                  label: 'Store Photo',
                  icon: Icons.photo,
                  url: storePhotoUrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(
                      color: Color(0xFFD32F2F),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF146BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
}

class ApprovedSupplierCard extends StatelessWidget {
  const ApprovedSupplierCard({
    super.key,
    required this.document,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  String getStringValue(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    final value = data[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  @override
  Widget build(
    BuildContext context,
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

    final profileImageUrl = getStringValue(
      data,
      'profileImageUrl',
      getStringValue(
        data,
        'storePhotoUrl',
        '',
      ),
    );

    final status = getStringValue(
      data,
      'status',
      'approved',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SupplierPhotoPreview(
            imageUrl: profileImageUrl,
            size: 42,
            fallbackColor: const Color(0xFFEAF7FB),
            iconColor: const Color(0xFF146BFF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 14,
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
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AdminStatusChip(
            status: status,
          ),
        ],
      ),
    );
  }
}

class VerificationLinkButton extends StatelessWidget {
  const VerificationLinkButton({
    super.key,
    required this.label,
    required this.icon,
    required this.url,
  });

  final String label;
  final IconData icon;
  final String url;

  bool get hasUrl {
    return url.trim().isNotEmpty;
  }

  Future<void> openUrl(
    BuildContext context,
  ) async {
    final uri = Uri.tryParse(url.trim());

    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid verification link.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open verification link.'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return OutlinedButton.icon(
      onPressed: hasUrl ? () => openUrl(context) : null,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF146BFF),
        disabledForegroundColor: const Color(0xFF7B8FA3),
        side: const BorderSide(
          color: Color(0xFF146BFF),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class SupplierPhotoPreview extends StatelessWidget {
  const SupplierPhotoPreview({
    super.key,
    required this.imageUrl,
    required this.size,
    required this.fallbackColor,
    required this.iconColor,
  });

  final String imageUrl;
  final double size;
  final Color fallbackColor;
  final Color iconColor;

  bool get hasImage {
    return imageUrl.trim().isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: size,
        height: size,
        color: fallbackColor,
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.storefront,
                    color: iconColor,
                    size: size * 0.54,
                  );
                },
              )
            : Icon(
                Icons.storefront,
                color: iconColor,
                size: size * 0.54,
              ),
      ),
    );
  }
}

class SupplierInfoRow extends StatelessWidget {
  const SupplierInfoRow({
    super.key,
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF7B8FA3),
          size: 16,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF52677A),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

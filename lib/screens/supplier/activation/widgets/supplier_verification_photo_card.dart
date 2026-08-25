import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/widgets/verification_evidence_image.dart';

class SupplierVerificationPhotoCard extends StatelessWidget {
  const SupplierVerificationPhotoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.permit,
    required this.localImage,
    required this.imageUrl,
    required this.storagePath,
    required this.uploading,
    required this.onUpload,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final bool permit;
  final XFile? localImage;
  final String imageUrl;
  final String storagePath;
  final bool uploading;
  final VoidCallback onUpload;
  final VoidCallback onRemove;

  bool get ready =>
      (storagePath.trim().isNotEmpty || imageUrl.trim().isNotEmpty) &&
      !uploading;

  @override
  Widget build(BuildContext context) {
    Widget preview;

    if (localImage != null) {
      preview = Image.file(File(localImage!.path), fit: BoxFit.cover);
    } else if (storagePath.trim().isNotEmpty || imageUrl.trim().isNotEmpty) {
      preview = VerificationEvidenceImage(
        storagePath: storagePath,
        legacyUrl: imageUrl,
        fit: BoxFit.cover,
      );
    } else {
      preview = _Placeholder(permit: permit);
    }

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFD),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: ready
              ? const Color(0xFF77D7B7)
              : const Color(0xFFE1EBF2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      preview,
                      if (uploading)
                        Container(
                          color: Colors.black.withAlpha(90),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF102C44),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: ready
                                ? const Color(0xFFE7F8F1)
                                : const Color(0xFFEAF7FB),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            uploading
                                ? 'Uploading'
                                : ready
                                    ? 'Ready'
                                    : 'Required',
                            style: TextStyle(
                              color: ready
                                  ? const Color(0xFF147D64)
                                  : const Color(0xFF146BFF),
                              fontSize: 8.3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 9.3,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: uploading ? null : onUpload,
                  icon: Icon(
                    ready
                        ? Icons.change_circle_outlined
                        : Icons.upload_rounded,
                    size: 18,
                  ),
                  label: Text(
                    ready ? 'Change Photo' : 'Upload Photo',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF146BFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF8BA6BD),
                    minimumSize: const Size.fromHeight(42),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (localImage != null ||
                  storagePath.trim().isNotEmpty ||
                  imageUrl.trim().isNotEmpty) ...[
                const SizedBox(width: 9),
                OutlinedButton(
                  onPressed: uploading ? null : onRemove,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD94A45),
                    side: const BorderSide(color: Color(0xFFF0B8B5)),
                    minimumSize: const Size(48, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 19),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.permit});

  final bool permit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEAF7FB),
      alignment: Alignment.center,
      child: Icon(
        permit ? Icons.badge_outlined : Icons.storefront_outlined,
        color: const Color(0xFF146BFF),
        size: 28,
      ),
    );
  }
}

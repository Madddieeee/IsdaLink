import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/widgets/verification_evidence_image.dart';

class SupplierReviewSection extends StatelessWidget {
  const SupplierReviewSection({
    super.key,
    required this.title,
    required this.icon,
    required this.onEdit,
    required this.rows,
    this.images = const [],
  });

  final String title;
  final IconData icon;
  final VoidCallback onEdit;
  final List<SupplierReviewRow> rows;
  final List<SupplierReviewImage> images;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE1EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0900152A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF087FCB), size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 12.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF087FCB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 9.2, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ...rows,
          if (images.isNotEmpty) ...[const SizedBox(height: 3), ...images],
        ],
      ),
    );
  }
}

class SupplierReviewRow extends StatelessWidget {
  const SupplierReviewRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8BA0B1),
                fontSize: 9.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'Not provided' : value.trim(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 9.8,
                height: 1.28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierReviewImage extends StatelessWidget {
  const SupplierReviewImage({
    super.key,
    required this.title,
    required this.localImage,
    required this.imageUrl,
    required this.storagePath,
  });

  final String title;
  final XFile? localImage;
  final String imageUrl;
  final String storagePath;

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
      preview = const ColoredBox(
        color: Color(0xFFEAF7FB),
        child: Icon(Icons.image_outlined, color: Color(0xFF8BA0B1)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 45, height: 45, child: preview),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 9.9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Uploaded for admin review',
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 8.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F8F1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, color: Color(0xFF147D64), size: 12),
                SizedBox(width: 3),
                Text(
                  'Ready',
                  style: TextStyle(
                    color: Color(0xFF147D64),
                    fontSize: 8.0,
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

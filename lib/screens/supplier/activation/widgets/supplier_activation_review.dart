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
    final items = <Widget>[...rows, ...images];
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE1EBF2)),
        boxShadow: const [
          BoxShadow(color: Color(0x0900152A), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF087FCB), size: 20),
              const SizedBox(width: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 9.3, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const Divider(height: 9, color: Color(0xFFE8EFF4)),
          for (var index = 0; index < items.length; index++) ...[
            items[index],
            if (index != items.length - 1)
              const Divider(height: 1, color: Color(0xFFEDF2F6)),
          ],
        ],
      ),
    );
  }
}

class SupplierReviewRow extends StatelessWidget {
  const SupplierReviewRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 9.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'Not provided' : value.trim(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 9.9,
                height: 1.3,
                fontWeight: FontWeight.w800,
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
    final Widget preview;
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 46, height: 46, child: preview),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 9.9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFF147D64), size: 18),
        ],
      ),
    );
  }
}

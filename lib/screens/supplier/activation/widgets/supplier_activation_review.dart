import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE1EBF2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF146BFF), size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
          if (images.isNotEmpty) ...[
            const SizedBox(height: 5),
            ...images,
          ],
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
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8BA0B1),
                fontSize: 8.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? 'Not provided' : value.trim(),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 9.5,
                height: 1.3,
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
  });

  final String title;
  final XFile? localImage;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget preview;

    if (localImage != null) {
      preview = Image.file(File(localImage!.path), fit: BoxFit.cover);
    } else if (imageUrl.trim().isNotEmpty) {
      preview = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xFFEAF7FB),
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Color(0xFF8BA0B1),
          ),
        ),
      );
    } else {
      preview = const ColoredBox(
        color: Color(0xFFEAF7FB),
        child: Icon(Icons.image_outlined, color: Color(0xFF8BA0B1)),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(width: 50, height: 50, child: preview),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 10.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Uploaded and ready for admin review.',
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
            child: const Text(
              'Ready',
              style: TextStyle(
                color: Color(0xFF147D64),
                fontSize: 8.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

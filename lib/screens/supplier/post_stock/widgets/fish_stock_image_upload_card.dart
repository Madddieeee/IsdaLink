import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_section_card.dart';

class FishStockImageUploadCard extends StatelessWidget {
  const FishStockImageUploadCard({
    super.key,
    required this.selectedImage,
    required this.uploadedImageUrl,
    required this.isUploading,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final XFile? selectedImage;
  final String uploadedImageUrl;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  bool get hasUploadedImage => uploadedImageUrl.trim().isNotEmpty;

  bool get hasLocalImage => selectedImage != null;

  @override
  Widget build(BuildContext context) {
    return PostStockSectionCard(
      title: 'Product Image',
      subtitle: 'Upload a clear fish photo that vendors will see.',
      icon: Icons.image_outlined,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              height: 120,
              color: const Color(0xFFEAF7FB),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasLocalImage)
                    Image.file(
                      File(selectedImage!.path),
                      fit: BoxFit.cover,
                    )
                  else if (hasUploadedImage)
                    Image.network(
                      uploadedImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const ProductImagePlaceholder();
                      },
                    )
                  else
                    const ProductImagePlaceholder(),
                  if (isUploading)
                    Container(
                      color: Colors.black.withAlpha(70),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : onPickImage,
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    size: 18,
                  ),
                  label: Text(
                    hasUploadedImage ? 'Change Photo' : 'Upload Photo',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF146BFF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(42),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (hasLocalImage || hasUploadedImage) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: isUploading ? null : onRemoveImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(
                      color: Color(0xFFD32F2F),
                    ),
                    minimumSize: const Size(46, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 19,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: Color(0xFF146BFF),
            size: 32,
          ),
          SizedBox(height: 5),
          Text(
            'Add fish product photo',
            style: TextStyle(
              color: Color(0xFF52677A),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

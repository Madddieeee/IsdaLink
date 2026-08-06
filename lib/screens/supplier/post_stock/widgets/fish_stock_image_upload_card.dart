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
    this.errorText,
  });

  final XFile? selectedImage;
  final String uploadedImageUrl;
  final bool isUploading;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final String? errorText;

  bool get hasUploadedImage => uploadedImageUrl.trim().isNotEmpty;
  bool get hasLocalImage => selectedImage != null;
  bool get hasImage => hasLocalImage || hasUploadedImage;

  @override
  Widget build(BuildContext context) {
    return PostStockSectionCard(
      title: 'Product Photo',
      subtitle: 'Use one clear image as the listing visual.',
      icon: Icons.add_photo_alternate_outlined,
      badge: 'STEP 2',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isUploading ? null : onPickImage,
              borderRadius: BorderRadius.circular(19),
              child: Ink(
                width: double.infinity,
                height: 148,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FB),
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: errorText == null
                        ? const Color(0xFFDCEBF3)
                        : const Color(0xFFD32F2F),
                    width: errorText == null ? 1 : 1.3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
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
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const ProductImagePlaceholder();
                          },
                        )
                      else
                        const ProductImagePlaceholder(),
                      if (hasImage)
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Color(0x7A001626),
                              ],
                              stops: [
                                0.55,
                                1.0,
                              ],
                            ),
                          ),
                        ),
                      if (hasImage)
                        Positioned(
                          left: 11,
                          right: 11,
                          bottom: 10,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF73E4B8),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Product photo ready',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
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
                                  color: Colors.white.withAlpha(38),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Text(
                                  'Tap to change',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isUploading)
                        Container(
                          color: Colors.black.withAlpha(105),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                                SizedBox(height: 9),
                                Text(
                                  'Uploading photo...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 7),
            Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : onPickImage,
                  icon: Icon(
                    hasImage
                        ? Icons.change_circle_outlined
                        : Icons.photo_library_outlined,
                    size: 18,
                  ),
                  label: Text(
                    hasImage ? 'Change Photo' : 'Choose Photo',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF146BFF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 9),
                OutlinedButton(
                  onPressed: isUploading ? null : onRemoveImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD32F2F),
                    side: const BorderSide(
                      color: Color(0xFFF0B8B5),
                    ),
                    minimumSize: const Size(48, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF7B8FA3),
                size: 16,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'JPG or PNG. Use a bright photo without unrelated text or objects.',
                  style: TextStyle(
                    color: Color(0xFF7B8FA3),
                    fontSize: 9.4,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
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
            size: 36,
          ),
          SizedBox(height: 6),
          Text(
            'Add a fish product photo',
            style: TextStyle(
              color: Color(0xFF52677A),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'Tap here or use Choose Photo',
            style: TextStyle(
              color: Color(0xFF8BA0B1),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

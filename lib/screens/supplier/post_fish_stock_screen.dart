import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/config/cloudinary_config.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_image_upload_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_preview_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_price_stock_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_product_information_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_submit_button.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_header.dart';
import 'package:isdalink/services/cloudinary_upload_service.dart';
import 'package:isdalink/services/fish_stock_service.dart';

class PostFishStockScreen extends StatefulWidget {
  const PostFishStockScreen({
    super.key,
  });

  @override
  State<PostFishStockScreen> createState() => _PostFishStockScreenState();
}

class _PostFishStockScreenState extends State<PostFishStockScreen> {
  final productNameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final lowStockController = TextEditingController();
  final descriptionController = TextEditingController();

  final FishStockService fishStockService = const FishStockService();
  final CloudinaryUploadService cloudinaryUploadService =
      const CloudinaryUploadService();
  final ImagePicker imagePicker = ImagePicker();

  String selectedCategory = 'Fresh Fish';
  String selectedUnit = 'kilo';
  String productImageUrl = '';

  XFile? selectedImage;

  bool isPosting = false;
  bool isUploadingImage = false;

  final List<String> categories = [
    'Fresh Fish',
    'Marine Fish',
    'Aquaculture Fish',
    'Bulk Fish Supply',
  ];

  final List<String> units = [
    'kilo',
    'tab',
    'icebox',
  ];

  @override
  void dispose() {
    productNameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    lowStockController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String emojiForProductName(String productName) {
    final name = productName.toLowerCase();

    if (name.contains('shrimp') || name.contains('hipon')) {
      return '🦐';
    }

    if (name.contains('squid') || name.contains('pusit')) {
      return '🦑';
    }

    if (name.contains('crab') ||
        name.contains('alimasag') ||
        name.contains('alimango')) {
      return '🦀';
    }

    if (name.contains('shark')) {
      return '🦈';
    }

    return '🐟';
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
      ),
    );
  }

  Future<void> pickAndUploadProductImage() async {
    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1400,
      );

      if (image == null) {
        return;
      }

      setState(() {
        selectedImage = image;
        productImageUrl = '';
        isUploadingImage = true;
      });

      final uploadedUrl = await cloudinaryUploadService.uploadImage(
        image,
        folder: CloudinaryConfig.fishStockFolder,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        productImageUrl = uploadedUrl;
        isUploadingImage = false;
      });

      showMessage('Product image uploaded successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isUploadingImage = false;
      });

      showMessage(
        'Failed to upload product image: $error',
        isError: true,
      );
    }
  }

  void removeProductImage() {
    setState(() {
      selectedImage = null;
      productImageUrl = '';
    });
  }

  FishStockInput? buildInputFromForm() {
    final productName = productNameController.text.trim();
    final description = descriptionController.text.trim();

    final price = double.tryParse(priceController.text.trim());
    final quantity = double.tryParse(quantityController.text.trim());
    final lowStockLevel = double.tryParse(lowStockController.text.trim());

    if (productName.isEmpty ||
        description.isEmpty ||
        price == null ||
        quantity == null ||
        lowStockLevel == null) {
      showMessage(
        'Please complete all fields with valid values.',
        isError: true,
      );
      return null;
    }

    if (price <= 0 || quantity <= 0 || lowStockLevel < 0) {
      showMessage(
        'Price and quantity must be valid positive values.',
        isError: true,
      );
      return null;
    }

    if (productImageUrl.trim().isEmpty) {
      showMessage(
        'Please upload a product image before posting.',
        isError: true,
      );
      return null;
    }

    return FishStockInput(
      productName: productName,
      description: description,
      category: selectedCategory,
      unit: selectedUnit,
      emoji: emojiForProductName(productName),
      price: price,
      quantity: quantity,
      lowStockLevel: lowStockLevel,
      productImageUrl: productImageUrl,
    );
  }

  Future<void> submitPost() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Please log in first before posting fish stock.',
        isError: true,
      );
      return;
    }

    if (isUploadingImage) {
      showMessage(
        'Please wait for the product image upload to finish.',
        isError: true,
      );
      return;
    }

    final input = buildInputFromForm();

    if (input == null) {
      return;
    }

    setState(() {
      isPosting = true;
    });

    try {
      await fishStockService.createFishStockPost(
        user: user,
        input: input,
      );

      if (!mounted) {
        return;
      }

      showStockPostedDialog();
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Failed to save stock post: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isPosting = false;
        });
      }
    }
  }

  void showStockPostedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Stock Posted',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Your fish stock post is now available for vendor browsing and COD ordering.',
            style: TextStyle(
              color: Color(0xFF52677A),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                clearForm();
              },
              child: const Text('Post Another'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF146BFF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Back to Dashboard'),
            ),
          ],
        );
      },
    );
  }

  void clearForm() {
    setState(() {
      productNameController.clear();
      priceController.clear();
      quantityController.clear();
      lowStockController.clear();
      descriptionController.clear();

      selectedCategory = 'Fresh Fish';
      selectedUnit = 'kilo';
      selectedImage = null;
      productImageUrl = '';
      isUploadingImage = false;
    });
  }

  void refreshPreview() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Column(
        children: [
          PostStockHeader(
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              children: [
                FishStockProductInformationCard(
                  productNameController: productNameController,
                  descriptionController: descriptionController,
                  categories: categories,
                  selectedCategory: selectedCategory,
                  onPreviewChanged: refreshPreview,
                  onCategoryChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                FishStockImageUploadCard(
                  selectedImage: selectedImage,
                  uploadedImageUrl: productImageUrl,
                  isUploading: isUploadingImage,
                  onPickImage: pickAndUploadProductImage,
                  onRemoveImage: removeProductImage,
                ),
                FishStockPriceStockCard(
                  priceController: priceController,
                  quantityController: quantityController,
                  lowStockController: lowStockController,
                  units: units,
                  selectedUnit: selectedUnit,
                  onPreviewChanged: refreshPreview,
                  onUnitChanged: (value) {
                    setState(() {
                      selectedUnit = value;
                    });
                  },
                ),
                FishStockPreviewCard(
                  productName: productNameController.text,
                  price: priceController.text,
                  selectedCategory: selectedCategory,
                  selectedUnit: selectedUnit,
                  productImageUrl: productImageUrl,
                ),
              ],
            ),
          ),
          FishStockSubmitButton(
            isPosting: isPosting || isUploadingImage,
            onPressed: submitPost,
          ),
        ],
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_emoji_selector_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_info_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_preview_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_price_stock_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_product_information_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_submit_button.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/post_stock_header.dart';
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

  String selectedCategory = 'Fresh Fish';
  String selectedUnit = 'kilo';
  String selectedEmoji = '🐟';

  bool isPosting = false;

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

  final List<String> emojis = [
    '🐟',
    '🐠',
    '🦈',
    '🦑',
    '🦐',
  ];

  @override
  void initState() {
    super.initState();

    productNameController.text = 'Bangus';
    priceController.text = '180';
    quantityController.text = '25';
    lowStockController.text = '5';
    descriptionController.text =
        'Fresh fish stock available for vendor orders within Caraga Region.';
  }

  @override
  void dispose() {
    productNameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    lowStockController.dispose();
    descriptionController.dispose();
    super.dispose();
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

  FishStockInput? buildInputFromForm() {
    final productName = productNameController.text.trim();
    final description = descriptionController.text.trim();

    final price = double.tryParse(
      priceController.text.trim(),
    );

    final quantity = double.tryParse(
      quantityController.text.trim(),
    );

    final lowStockLevel = double.tryParse(
      lowStockController.text.trim(),
    );

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

    return FishStockInput(
      productName: productName,
      description: description,
      category: selectedCategory,
      unit: selectedUnit,
      emoji: selectedEmoji,
      price: price,
      quantity: quantity,
      lowStockLevel: lowStockLevel,
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
            'Your fish stock post has been saved under this logged-in supplier account. Vendors can view available posts from approved suppliers.',
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
              child: const Text(
                'Post Another',
              ),
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
              child: const Text(
                'Back to Dashboard',
              ),
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
      selectedEmoji = '🐟';
    });
  }

  void refreshPreview() {
    setState(() {});
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Column(
        children: [
          PostStockHeader(
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
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
                FishStockEmojiSelectorCard(
                  emojis: emojis,
                  selectedEmoji: selectedEmoji,
                  onEmojiSelected: (value) {
                    setState(() {
                      selectedEmoji = value;
                    });
                  },
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
                  selectedEmoji: selectedEmoji,
                ),
                const FishStockInfoCard(),
              ],
            ),
          ),
          FishStockSubmitButton(
            isPosting: isPosting,
            onPressed: submitPost,
          ),
        ],
      ),
    );
  }
}
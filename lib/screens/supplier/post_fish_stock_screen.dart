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
  final percentageController = TextEditingController(text: '20');
  final descriptionController = TextEditingController();

  final FishStockService fishStockService = const FishStockService();

  String selectedCategory = 'Fresh Fish';
  String selectedUnit = 'kilo';
  String selectedEmoji = '🐟';
  bool isPosting = false;

  final List<String> categories = const [
    'Fresh Fish',
    'Marine Fish',
    'Aquaculture Fish',
    'Bulk Fish Supply',
  ];

  final List<String> units = const [
    'kilo',
    'tab',
    'icebox',
  ];

  final List<String> emojis = const [
    '🐟',
    '🐠',
    '🦈',
    '🦑',
    '🦐',
  ];

  @override
  void dispose() {
    productNameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    lowStockController.dispose();
    percentageController.dispose();
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String formatNumber(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  void calculateSuggestedThreshold() {
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    final percentage = double.tryParse(percentageController.text.trim()) ?? 20;

    if (quantity <= 0) {
      lowStockController.clear();
    } else {
      final safePercentage = percentage.clamp(1, 100).toDouble();
      lowStockController.text = formatNumber(
        quantity * safePercentage / 100,
      );
    }

    setState(() {});
  }

  FishStockInput? buildInputFromForm() {
    final productName = productNameController.text.trim();
    final description = descriptionController.text.trim();
    final price = double.tryParse(priceController.text.trim());
    final quantity = double.tryParse(quantityController.text.trim());
    final percentage = double.tryParse(percentageController.text.trim());
    final lowStockLevel = double.tryParse(lowStockController.text.trim());

    if (productName.isEmpty ||
        description.isEmpty ||
        price == null ||
        quantity == null ||
        percentage == null ||
        lowStockLevel == null) {
      showMessage(
        'Please complete all fields with valid values.',
        isError: true,
      );
      return null;
    }

    if (price <= 0 || quantity <= 0) {
      showMessage(
        'Price and available stock must be greater than zero.',
        isError: true,
      );
      return null;
    }

    if (percentage < 1 || percentage > 100) {
      showMessage(
        'Low-stock percentage must be between 1% and 100%.',
        isError: true,
      );
      return null;
    }

    if (lowStockLevel < 0 || lowStockLevel > quantity) {
      showMessage(
        'The alert level must be between zero and the available stock.',
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
      lowStockPercentage: percentage,
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

      showStockPostedDialog(input);
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

  void showStockPostedDialog(FishStockInput input) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
              ),
              SizedBox(width: 9),
              Text(
                'Stock Posted',
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          content: Text(
            '${input.productName} was posted with a low-stock alert at '
            '${formatNumber(input.lowStockLevel)} ${input.unit} '
            '(${formatNumber(input.lowStockPercentage)}%). The Supplier Dashboard '
            'will show an alert when the remaining quantity reaches this level.',
            style: const TextStyle(
              color: Color(0xFF52677A),
              height: 1.45,
              fontWeight: FontWeight.w600,
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
                backgroundColor: const Color(0xFF0875D1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'Back to Dashboard',
                style: TextStyle(fontWeight: FontWeight.w900),
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
      percentageController.text = '20';
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                  percentageController: percentageController,
                  units: units,
                  selectedUnit: selectedUnit,
                  onPreviewChanged: refreshPreview,
                  onPercentageChanged: calculateSuggestedThreshold,
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

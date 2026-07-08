import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PostFishStockScreen
    extends
        StatefulWidget {
  const PostFishStockScreen({
    super.key,
  });

  @override
  State<
    PostFishStockScreen
  >
  createState() => _PostFishStockScreenState();
}

class _PostFishStockScreenState
    extends
        State<
          PostFishStockScreen
        > {
  final productNameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final lowStockController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedCategory = 'Fresh Fish';
  String selectedUnit = 'kilo';
  String selectedEmoji = '🐟';

  bool isPosting = false;

  final List<
    String
  >
  categories = [
    'Fresh Fish',
    'Marine Fish',
    'Aquaculture Fish',
    'Bulk Fish Supply',
  ];

  final List<
    String
  >
  units = [
    'kilo',
    'tab',
    'icebox',
  ];

  final List<
    String
  >
  emojis = [
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
    descriptionController.text = 'Fresh fish stock available for vendor orders within Caraga Region.';
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

  Future<
    void
  >
  submitPost() async {
    final String productName = productNameController.text.trim();
    final String description = descriptionController.text.trim();
    final double? price = double.tryParse(
      priceController.text.trim(),
    );
    final double? quantity = double.tryParse(
      quantityController.text.trim(),
    );
    final double? lowStockLevel = double.tryParse(
      lowStockController.text.trim(),
    );

    if (productName.isEmpty ||
        description.isEmpty ||
        price ==
            null ||
        quantity ==
            null ||
        lowStockLevel ==
            null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all fields with valid values.',
          ),
          backgroundColor: Color(
            0xFFD32F2F,
          ),
        ),
      );
      return;
    }

    if (price <=
            0 ||
        quantity <=
            0 ||
        lowStockLevel <
            0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Price and quantity must be valid positive values.',
          ),
          backgroundColor: Color(
            0xFFD32F2F,
          ),
        ),
      );
      return;
    }

    setState(
      () {
        isPosting = true;
      },
    );

    try {
      await FirebaseFirestore.instance
          .collection(
            'fishStocks',
          )
          .add(
            {
              'productName': productName,
              'category': selectedCategory,
              'description': description,
              'emoji': selectedEmoji,
              'price': price,
              'priceUnit': 'per $selectedUnit',
              'quantity': quantity,
              'quantityUnit': selectedUnit,
              'lowStockLevel': lowStockLevel,
              'paymentMethod': 'COD',
              'supplierId': 'sample_supplier_001',
              'supplierName': 'Juan Fresh Fish Supply',
              'region': 'Caraga Region',
              'status': 'available',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (
              dialogContext,
            ) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    24,
                  ),
                ),
                title: const Text(
                  'Stock Posted',
                  style: TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: const Text(
                  'Your fish stock post has been saved to Firebase Firestore. '
                  'Vendors can later view this stock from the supplier listing.',
                  style: TextStyle(
                    color: Color(
                      0xFF52677A,
                    ),
                    height: 1.4,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                      clearForm();
                    },
                    child: const Text(
                      'Post Another',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                      Navigator.pop(
                        context,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF146BFF,
                      ),
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
    } catch (
      error
    ) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save stock post: $error',
          ),
          backgroundColor: const Color(
            0xFFD32F2F,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(
          () {
            isPosting = false;
          },
        );
      }
    }
  }

  void clearForm() {
    setState(
      () {
        productNameController.clear();
        priceController.clear();
        quantityController.clear();
        lowStockController.clear();
        descriptionController.clear();

        selectedCategory = 'Fresh Fish';
        selectedUnit = 'kilo';
        selectedEmoji = '🐟';
      },
    );
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
      labelStyle: const TextStyle(
        color: Color(
          0xFF7B8FA3,
        ),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(
          0xFF146BFF,
        ),
      ),
      filled: true,
      fillColor: const Color(
        0xFFF4F8FB,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          18,
        ),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          18,
        ),
        borderSide: const BorderSide(
          color: Color(
            0xFF146BFF,
          ),
          width: 1.4,
        ),
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          24,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x10000000,
            ),
            blurRadius: 14,
            offset: Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(
                        0xFF146BFF,
                      ).withAlpha(
                        24,
                      ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(
                    0xFF146BFF,
                  ),
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(
                          0xFF7B8FA3,
                        ),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          child,
        ],
      ),
    );
  }

  Widget emojiChoice(
    String emoji,
  ) {
    final bool isSelected =
        selectedEmoji ==
        emoji;

    return GestureDetector(
      onTap: () {
        setState(
          () {
            selectedEmoji = emoji;
          },
        );
      },
      child: Container(
        width: 52,
        height: 52,
        margin: const EdgeInsets.only(
          right: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(
                  0xFF146BFF,
                )
              : const Color(
                  0xFFEAF7FB,
                ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: isSelected
                ? const Color(
                    0xFF146BFF,
                  )
                : const Color(
                    0xFFE1E9F0,
                  ),
            width: 1.4,
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(
              fontSize: 26,
            ),
          ),
        ),
      ),
    );
  }

  Widget previewCard() {
    return Container(
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFFEAF7FB,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              const Color(
                0xFF146BFF,
              ).withAlpha(
                42,
              ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            child: Center(
              child: Text(
                selectedEmoji,
                style: const TextStyle(
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 13,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productNameController.text.isEmpty
                      ? 'Fish Product'
                      : productNameController.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(
                      0xFF102C44,
                    ),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  selectedCategory,
                  style: const TextStyle(
                    color: Color(
                      0xFF7B8FA3,
                    ),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(
                  height: 7,
                ),
                Text(
                  '₱${priceController.text.isEmpty ? '0' : priceController.text} per $selectedUnit',
                  style: const TextStyle(
                    color: Color(
                      0xFF146BFF,
                    ),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.visibility,
            color: Color(
              0xFF146BFF,
            ),
            size: 22,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F8FB,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              54,
              20,
              24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(
                    0xFF102C44,
                  ),
                  Color(
                    0xFF146BFF,
                  ),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(
                  32,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(
                        context,
                      ),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(
                            38,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    const Expanded(
                      child: Text(
                        'Post Fish Stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 18,
                ),
                const Text(
                  'Add fish stock details so vendors can view available supply and place COD orders.',
                  style: TextStyle(
                    color: Color(
                      0xFFDCE9F5,
                    ),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(
                  height: 18,
                ),
                Container(
                  padding: const EdgeInsets.all(
                    15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(
                      34,
                    ),
                    borderRadius: BorderRadius.circular(
                      22,
                    ),
                    border: Border.all(
                      color: Colors.white.withAlpha(
                        34,
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.payments,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Text(
                          'Payment scope: Cash on Delivery only',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                18,
                22,
                18,
                20,
              ),
              children: [
                sectionCard(
                  title: 'Product Information',
                  subtitle: 'Enter the fish product details shown to vendors.',
                  icon: Icons.set_meal,
                  child: Column(
                    children: [
                      TextField(
                        controller: productNameController,
                        onChanged:
                            (
                              _,
                            ) => setState(
                              () {},
                            ),
                        decoration: inputDecoration(
                          label: 'Fish Product Name',
                          icon: Icons.edit,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      DropdownButtonFormField<
                        String
                      >(
                        value: selectedCategory,
                        decoration: inputDecoration(
                          label: 'Category',
                          icon: Icons.category,
                        ),
                        items: categories
                            .map(
                              (
                                category,
                              ) => DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged:
                            (
                              value,
                            ) {
                              setState(
                                () {
                                  selectedCategory =
                                      value ??
                                      selectedCategory;
                                },
                              );
                            },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: inputDecoration(
                          label: 'Description',
                          icon: Icons.description,
                        ),
                      ),
                    ],
                  ),
                ),
                sectionCard(
                  title: 'Product Image Icon',
                  subtitle: 'Choose a sample icon for the prototype display.',
                  icon: Icons.image,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: emojis
                          .map(
                            emojiChoice,
                          )
                          .toList(),
                    ),
                  ),
                ),
                sectionCard(
                  title: 'Price and Stock',
                  subtitle: 'Set product price, unit, quantity, and alert level.',
                  icon: Icons.inventory_2,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              onChanged:
                                  (
                                    _,
                                  ) => setState(
                                    () {},
                                  ),
                              decoration: inputDecoration(
                                label: 'Price',
                                icon: Icons.sell,
                                suffixText: 'PHP',
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Expanded(
                            child:
                                DropdownButtonFormField<
                                  String
                                >(
                                  value: selectedUnit,
                                  decoration: inputDecoration(
                                    label: 'Unit',
                                    icon: Icons.scale,
                                  ),
                                  items: units
                                      .map(
                                        (
                                          unit,
                                        ) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(
                                            'per $unit',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged:
                                      (
                                        value,
                                      ) {
                                        setState(
                                          () {
                                            selectedUnit =
                                                value ??
                                                selectedUnit;
                                          },
                                        );
                                      },
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration(
                          label: 'Available Quantity',
                          icon: Icons.inventory,
                          suffixText: selectedUnit,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      TextField(
                        controller: lowStockController,
                        keyboardType: TextInputType.number,
                        decoration: inputDecoration(
                          label: 'Low Stock Alert Level',
                          icon: Icons.warning_amber,
                          suffixText: selectedUnit,
                        ),
                      ),
                    ],
                  ),
                ),
                sectionCard(
                  title: 'Post Preview',
                  subtitle: 'Sample preview of how vendors may see this stock.',
                  icon: Icons.visibility,
                  child: previewCard(),
                ),
                Container(
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFEAF7FB,
                    ),
                    borderRadius: BorderRadius.circular(
                      22,
                    ),
                    border: Border.all(
                      color:
                          const Color(
                            0xFF146BFF,
                          ).withAlpha(
                            42,
                          ),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.cloud_done,
                        color: Color(
                          0xFF146BFF,
                        ),
                        size: 22,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          'Firebase mode: New fish stock posts will be saved to Cloud Firestore under the fishStocks collection.',
                          style: TextStyle(
                            color: Color(
                              0xFF52677A,
                            ),
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(
                    0x14000000,
                  ),
                  blurRadius: 14,
                  offset: Offset(
                    0,
                    -4,
                  ),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isPosting
                      ? null
                      : submitPost,
                  icon: isPosting
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.add_box,
                        ),
                  label: Text(
                    isPosting
                        ? 'Saving to Firebase...'
                        : 'Post Fish Stock',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF146BFF,
                    ),
                    disabledBackgroundColor: const Color(
                      0xFF7B8FA3,
                    ),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

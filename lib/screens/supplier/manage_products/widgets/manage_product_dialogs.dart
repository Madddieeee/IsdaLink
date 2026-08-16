import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/services/cloudinary_upload_service.dart';
import 'package:isdalink/services/supplier_product_service.dart';
import 'package:isdalink/utils/order_helpers.dart';

class ManageProductDialogs {
  const ManageProductDialogs._();

  static Future<SupplierProductUpdateInput?> showEditSheet({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
  }) {
    return showModalBottomSheet<SupplierProductUpdateInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(165),
      builder: (
        context,
      ) {
        return _EditProductSheet(
          data: document.data(),
        );
      },
    );
  }

  static Future<bool> showAvailabilityDialog({
    required BuildContext context,
    required String productName,
    required bool currentlyHidden,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        final action = currentlyHidden ? 'show' : 'hide';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 25,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              21,
              20,
              18,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: currentlyHidden
                        ? const Color(0xFFE7F8F1)
                        : const Color(0xFFEAF2F7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    currentlyHidden
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: currentlyHidden
                        ? const Color(0xFF147D64)
                        : const Color(0xFF52677A),
                    size: 31,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  currentlyHidden
                      ? 'Show this product?'
                      : 'Hide this product?',
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  currentlyHidden
                      ? '$productName will become visible to vendors again.'
                      : '$productName will be removed from vendor browsing but retained in your inventory records.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF657C8E),
                    fontSize: 10.8,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF52677A),
                          side: const BorderSide(
                            color: Color(0xFFB9CBD7),
                          ),
                          minimumSize: const Size.fromHeight(47),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            true,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: currentlyHidden
                              ? const Color(0xFF147D64)
                              : const Color(0xFF52677A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(47),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          '${action[0].toUpperCase()}${action.substring(1)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  static Future<bool> showArchiveDialog({
    required BuildContext context,
    required String productName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (
        dialogContext,
      ) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 25,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              21,
              20,
              18,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDECEC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.archive_outlined,
                    color: Color(0xFFD94A45),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Archive this product?',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$productName will be hidden from vendors but kept in your inventory history. You can restore it later.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF657C8E),
                    fontSize: 10.8,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF52677A),
                          side: const BorderSide(
                            color: Color(0xFFB9CBD7),
                          ),
                          minimumSize: const Size.fromHeight(47),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Keep Active',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            true,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFB86500),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(47),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Archive',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }
}

class _EditProductSheet extends StatefulWidget {
  const _EditProductSheet({
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  State<_EditProductSheet> createState() =>
      _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  final formKey = GlobalKey<FormState>();
  final imagePicker = ImagePicker();
  final cloudinaryUploadService =
      const CloudinaryUploadService();

  late final TextEditingController productNameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late final TextEditingController quantityController;
  late final TextEditingController percentageController;

  final categories = const [
    'Fresh Fish',
    'Marine Fish',
    'Aquaculture Fish',
    'Bulk Fish Supply',
  ];
  final units = const [
    'kilo',
    'tab',
    'icebox',
  ];

  late String selectedCategory;
  late String selectedUnit;
  late String imageUrl;
  late bool customPercentage;

  XFile? selectedImage;
  bool isSaving = false;
  String? imageError;

  String firstString(
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = widget.data[key]?.toString().trim() ?? '';

      if (value.isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  double dataDouble(
    String key,
  ) {
    return OrderHelpers.getDoubleValue(
      widget.data,
      key,
    );
  }

  String formatInput(
    double value,
  ) {
    return value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  @override
  void initState() {
    super.initState();

    productNameController = TextEditingController(
      text: firstString(
        const [
          'productName',
        ],
        fallback: '',
      ),
    );
    descriptionController = TextEditingController(
      text: firstString(
        const [
          'description',
        ],
        fallback: '',
      ),
    );
    priceController = TextEditingController(
      text: formatInput(
        dataDouble('price'),
      ),
    );
    quantityController = TextEditingController(
      text: formatInput(
        dataDouble('quantity'),
      ),
    );

    selectedCategory = firstString(
      const [
        'category',
      ],
      fallback: 'Fresh Fish',
    );
    selectedUnit = firstString(
      const [
        'quantityUnit',
      ],
      fallback: 'kilo',
    );
    imageUrl = firstString(
      const [
        'productImageUrl',
        'imageUrl',
      ],
      fallback: '',
    );

    var percentage = dataDouble('lowStockPercentage');

    if (percentage <= 0) {
      final referenceQuantity =
          dataDouble('referenceStockQuantity');
      final lowStockLevel = dataDouble('lowStockLevel');

      percentage = referenceQuantity > 0
          ? lowStockLevel / referenceQuantity * 100
          : 20;
    }

    percentageController = TextEditingController(
      text: formatInput(percentage),
    );

    customPercentage = !const [
      '10',
      '20',
      '25',
      '30',
    ].contains(percentageController.text);
  }

  @override
  void dispose() {
    productNameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    quantityController.dispose();
    percentageController.dispose();
    super.dispose();
  }

  double get quantity {
    return double.tryParse(
          quantityController.text.trim(),
        ) ??
        0;
  }

  double get percentage {
    return double.tryParse(
          percentageController.text.trim(),
        ) ??
        0;
  }

  double get calculatedAlert {
    if (quantity <= 0 || percentage <= 0) {
      return 0;
    }

    return quantity *
        percentage.clamp(1, 100).toDouble() /
        100;
  }

  bool get hasImage {
    return selectedImage != null || imageUrl.isNotEmpty;
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixText: prefixText,
      suffixText: suffixText,
      errorMaxLines: 2,
      labelStyle: const TextStyle(
        color: Color(0xFF7B8FA3),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF146BFF),
        fontWeight: FontWeight.w900,
      ),
      helperStyle: const TextStyle(
        color: Color(0xFF8299AA),
        fontSize: 9.5,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE5F4FD),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF146BFF),
          size: 20,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFF2F7FB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFE1EBF2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF146BFF),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFD94A45),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFD94A45),
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> pickImage() async {
    if (isSaving) {
      return;
    }

    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        selectedImage = image;
        imageError = null;
      });
    } catch (_) {
      showMessage(
        'Unable to open the image gallery.',
        isError: true,
      );
    }
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),
          backgroundColor: isError
              ? const Color(0xFFB86500)
              : const Color(0xFF147D64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  Future<void> save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      imageError = hasImage
          ? null
          : 'Add a product photo before saving.';
    });

    final valid = formKey.currentState?.validate() ?? false;

    if (!valid || !hasImage || isSaving) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      var finalImageUrl = imageUrl;
      final image = selectedImage;

      if (image != null) {
        finalImageUrl =
            await cloudinaryUploadService.uploadImage(
          image,
          folder: 'isdalink/fish_stocks',
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        SupplierProductUpdateInput(
          productName:
              productNameController.text.trim(),
          description:
              descriptionController.text.trim(),
          category: selectedCategory,
          unit: selectedUnit,
          imageUrl: finalImageUrl,
          price: double.parse(
            priceController.text.trim(),
          ),
          quantity: double.parse(
            quantityController.text.trim(),
          ),
          lowStockPercentage: double.parse(
            percentageController.text.trim(),
          ),
        ),
      );
    } catch (_) {
      showMessage(
        'Unable to upload the product photo. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget photoPreview() {
    Widget image;

    if (selectedImage != null) {
      image = Image.file(
        File(selectedImage!.path),
        fit: BoxFit.cover,
      );
    } else if (imageUrl.isNotEmpty) {
      image = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const _PhotoPlaceholder();
        },
      );
    } else {
      image = const _PhotoPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSaving ? null : pickImage,
            borderRadius: BorderRadius.circular(19),
            child: Ink(
              width: double.infinity,
              height: 155,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7FB),
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: imageError == null
                      ? const Color(0xFFDCEBF3)
                      : const Color(0xFFD94A45),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    image,
                    if (hasImage)
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0x7400182A),
                            ],
                            stops: [
                              0.56,
                              1.0,
                            ],
                          ),
                        ),
                      ),
                    if (hasImage)
                      const Positioned(
                        left: 12,
                        bottom: 11,
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF73E4B8),
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Product photo ready',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (imageError != null) ...[
          const SizedBox(height: 6),
          Text(
            imageError!,
            style: const TextStyle(
              color: Color(0xFFD94A45),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 9),
        SizedBox(
          width: double.infinity,
          height: 43,
          child: OutlinedButton.icon(
            onPressed: isSaving ? null : pickImage,
            icon: const Icon(
              Icons.photo_library_outlined,
              size: 18,
            ),
            label: Text(
              hasImage ? 'Change Product Photo' : 'Choose Product Photo',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF146BFF),
              side: const BorderSide(
                color: Color(0xFF9BD6FF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget percentageChoices() {
    final current = percentageController.text.trim();

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final value in const [
          '10',
          '20',
          '25',
          '30',
        ])
          _PercentageChoice(
            label:
                value == '20' ? '20% Recommended' : '$value%',
            selected:
                !customPercentage && current == value,
            onTap: () {
              percentageController.text = value;
              percentageController.selection =
                  TextSelection.collapsed(
                offset: value.length,
              );

              setState(() {
                customPercentage = false;
              });
            },
          ),
        _PercentageChoice(
          label: 'Custom',
          selected: customPercentage,
          onTap: () {
            setState(() {
              customPercentage = true;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height * 0.94,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF7FAFC),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 30,
              offset: Offset(0, -12),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFBED0DC),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                14,
                10,
                13,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF146BFF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Product',
                          style: TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Update the marketplace listing and automatic stock alert.',
                          style: TextStyle(
                            color: Color(0xFF7B8FA3),
                            fontSize: 10.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: isSaving
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF52677A),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: Colors.black.withAlpha(15),
            ),
            Expanded(
              child: Form(
                key: formKey,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    22,
                  ),
                  children: [
                    photoPreview(),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: productNameController,
                      enabled: !isSaving,
                      textCapitalization:
                          TextCapitalization.words,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(60),
                      ],
                      validator: (
                        value,
                      ) {
                        final text = value?.trim() ?? '';

                        if (text.length < 2) {
                          return 'Enter a valid fish product name.';
                        }

                        return null;
                      },
                      decoration: inputDecoration(
                        label: 'Fish product name',
                        icon: Icons.set_meal_outlined,
                      ),
                    ),
                    const SizedBox(height: 11),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      isExpanded: true,
                      decoration: inputDecoration(
                        label: 'Category',
                        icon: Icons.category_outlined,
                      ),
                      items: categories.map(
                        (
                          category,
                        ) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        },
                      ).toList(),
                      onChanged: isSaving
                          ? null
                          : (
                              value,
                            ) {
                              if (value != null) {
                                setState(() {
                                  selectedCategory = value;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 11),
                    TextFormField(
                      controller: descriptionController,
                      enabled: !isSaving,
                      minLines: 2,
                      maxLines: 3,
                      textCapitalization:
                          TextCapitalization.sentences,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(240),
                      ],
                      validator: (
                        value,
                      ) {
                        if ((value?.trim().length ?? 0) < 8) {
                          return 'Add a description with at least 8 characters.';
                        }

                        return null;
                      },
                      decoration: inputDecoration(
                        label: 'Description',
                        icon: Icons.description_outlined,
                        helperText:
                            'Freshness, size, or handling details.',
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceController,
                            enabled: !isSaving,
                            keyboardType:
                                const TextInputType
                                    .numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            validator: (
                              value,
                            ) {
                              final price = double.tryParse(
                                value?.trim() ?? '',
                              );

                              if (price == null || price <= 0) {
                                return 'Enter a valid price.';
                              }

                              return null;
                            },
                            decoration: inputDecoration(
                              label: 'Selling price',
                              icon: Icons.sell_outlined,
                              prefixText: '₱ ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child:
                              DropdownButtonFormField<String>(
                            initialValue: selectedUnit,
                            isExpanded: true,
                            decoration: inputDecoration(
                              label: 'Selling unit',
                              icon: Icons.scale_outlined,
                            ),
                            items: units.map(
                              (
                                unit,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: unit,
                                  child: Text('per $unit'),
                                );
                              },
                            ).toList(),
                            onChanged: isSaving
                                ? null
                                : (
                                    value,
                                  ) {
                                    if (value != null) {
                                      setState(() {
                                        selectedUnit = value;
                                      });
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    TextFormField(
                      controller: quantityController,
                      enabled: !isSaving,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (
                        _,
                      ) {
                        setState(() {});
                      },
                      validator: (
                        value,
                      ) {
                        final quantity = double.tryParse(
                          value?.trim() ?? '',
                        );

                        if (quantity == null || quantity < 0) {
                          return 'Enter a valid stock quantity.';
                        }

                        return null;
                      },
                      decoration: inputDecoration(
                        label: 'Available stock',
                        icon: Icons.inventory_2_outlined,
                        suffixText: selectedUnit,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFEAF8FF),
                            Color(0xFFEAFBF5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              const Color(0xFF75CFEA).withAlpha(88),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons
                                    .notifications_active_outlined,
                                color: Color(0xFFFF7A1A),
                                size: 21,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Automatic Low-Stock Alert',
                                  style: TextStyle(
                                    color: Color(0xFF102C44),
                                    fontSize: 12.3,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Choose when the stock alert should appear.',
                            style: TextStyle(
                              color: Color(0xFF657C8E),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 11),
                          percentageChoices(),
                          if (customPercentage) ...[
                            const SizedBox(height: 11),
                            TextFormField(
                              controller:
                                  percentageController,
                              enabled: !isSaving,
                              keyboardType:
                                  const TextInputType
                                      .numberWithOptions(
                                decimal: true,
                              ),
                              autofocus: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d{0,1}'),
                                ),
                              ],
                              onChanged: (
                                _,
                              ) {
                                setState(() {});
                              },
                              validator: (
                                value,
                              ) {
                                final valueNumber =
                                    double.tryParse(
                                  value?.trim() ?? '',
                                );

                                if (valueNumber == null ||
                                    valueNumber < 1 ||
                                    valueNumber > 100) {
                                  return 'Enter a percentage from 1% to 100%.';
                                }

                                return null;
                              },
                              decoration: inputDecoration(
                                label:
                                    'Custom alert percentage',
                                icon: Icons.percent_rounded,
                                suffixText: '%',
                              ),
                            ),
                          ],
                          const SizedBox(height: 11),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                              12,
                              11,
                              12,
                              11,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(210),
                              borderRadius:
                                  BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFDDEAF1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 39,
                                  height: 39,
                                  decoration: BoxDecoration(
                                    color: quantity >= 0 &&
                                            percentage > 0
                                        ? const Color(0xFFE7F8F1)
                                        : const Color(0xFFFFF2E8),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons
                                        .notifications_active_rounded,
                                    color: quantity >= 0 &&
                                            percentage > 0
                                        ? const Color(0xFF147D64)
                                        : const Color(0xFFFF7A1A),
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CALCULATED ALERT LEVEL',
                                        style: TextStyle(
                                          color:
                                              Color(0xFF7B8FA3),
                                          fontSize: 8.4,
                                          letterSpacing: 0.5,
                                          fontWeight:
                                              FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${formatInput(calculatedAlert)} $selectedUnit',
                                        style: const TextStyle(
                                          color:
                                              Color(0xFF102C44),
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'The alert threshold updates automatically.',
                                        style: TextStyle(
                                          color:
                                              Color(0xFF657C8E),
                                          fontSize: 9.3,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                18,
                10,
                18,
                15,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 18,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : save,
                    icon: isSaving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save_rounded,
                            size: 20,
                          ),
                    label: Text(
                      isSaving
                          ? 'Saving Changes...'
                          : 'Save Product Changes',
                      style: const TextStyle(
                        fontSize: 14.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF146BFF),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          const Color(0xFF7397B8),
                      elevation: isSaving ? 0 : 6,
                      shadowColor:
                          const Color(0x55146BFF),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      color: const Color(0xFFEAF7FB),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: Color(0xFF146BFF),
            size: 39,
          ),
          SizedBox(height: 6),
          Text(
            'Add a product photo',
            style: TextStyle(
              color: Color(0xFF52677A),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentageChoice extends StatelessWidget {
  const _PercentageChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF146BFF)
                : Colors.white.withAlpha(205),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? const Color(0xFF146BFF)
                  : const Color(0xFFD8E7EF),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : const Color(0xFF52677A),
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

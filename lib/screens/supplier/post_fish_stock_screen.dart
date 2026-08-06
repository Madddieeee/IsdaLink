import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_image_upload_card.dart';
import 'package:isdalink/screens/supplier/post_stock/widgets/fish_stock_info_card.dart';
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
  State<PostFishStockScreen> createState() =>
      _PostFishStockScreenState();
}

class _PostFishStockScreenState extends State<PostFishStockScreen> {
  final productNameController = TextEditingController();
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final lowStockController = TextEditingController();
  final percentageController = TextEditingController(
    text: '20',
  );
  final descriptionController = TextEditingController();

  final FishStockService fishStockService = const FishStockService();
  final CloudinaryUploadService cloudinaryUploadService =
      const CloudinaryUploadService();
  final ImagePicker imagePicker = ImagePicker();
  final ScrollController scrollController = ScrollController();

  String selectedCategory = 'Fresh Fish';
  String selectedUnit = 'kilo';

  XFile? selectedImage;
  String uploadedImageUrl = '';

  bool isPosting = false;
  bool isUploadingImage = false;
  bool useCustomPercentage = false;
  bool allowPop = false;

  String? productNameError;
  String? descriptionError;
  String? imageError;
  String? priceError;
  String? quantityError;
  String? percentageError;

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

  @override
  void dispose() {
    productNameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    lowStockController.dispose();
    percentageController.dispose();
    descriptionController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  bool get hasProductImage {
    return selectedImage != null ||
        uploadedImageUrl.trim().isNotEmpty;
  }

  double? get enteredPrice {
    return double.tryParse(
      priceController.text.trim(),
    );
  }

  double? get enteredQuantity {
    return double.tryParse(
      quantityController.text.trim(),
    );
  }

  double? get enteredPercentage {
    return double.tryParse(
      percentageController.text.trim(),
    );
  }

  bool get productInformationComplete {
    return productNameController.text.trim().length >= 2 &&
        descriptionController.text.trim().length >= 8;
  }

  bool get priceAndStockComplete {
    final price = enteredPrice;
    final quantity = enteredQuantity;
    final percentage = enteredPercentage;
    final threshold = double.tryParse(
      lowStockController.text.trim(),
    );

    return price != null &&
        price > 0 &&
        quantity != null &&
        quantity > 0 &&
        percentage != null &&
        percentage >= 1 &&
        percentage <= 100 &&
        threshold != null &&
        threshold >= 0 &&
        threshold <= quantity;
  }

  bool get listingReady {
    return productInformationComplete &&
        hasProductImage &&
        priceAndStockComplete;
  }

  bool get hasUnsavedListing {
    return productNameController.text.trim().isNotEmpty ||
        descriptionController.text.trim().isNotEmpty ||
        priceController.text.trim().isNotEmpty ||
        quantityController.text.trim().isNotEmpty ||
        hasProductImage ||
        selectedCategory != 'Fresh Fish' ||
        selectedUnit != 'kilo' ||
        percentageController.text.trim() != '20';
  }

  Future<bool> confirmDiscardListing() async {
    if (!hasUnsavedListing) {
      return true;
    }

    if (isPosting || isUploadingImage) {
      return false;
    }

    final shouldDiscard = await showDialog<bool>(
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
                    color: Color(0xFFFFF2E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFFFF7A1A),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Discard this listing?',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your entered fish stock details have not been published.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                              const Color(0xFF146BFF),
                          side: const BorderSide(
                            color: Color(0xFF9BD6FF),
                          ),
                          minimumSize: const Size.fromHeight(47),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Continue Editing',
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
                              const Color(0xFFD94A45),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(47),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Discard',
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

    return shouldDiscard ?? false;
  }

  void allowRoutePop([Object? result]) {
    if (!mounted) {
      return;
    }

    setState(() {
      allowPop = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    });
  }

  Future<void> handlePopInvoked(
    bool didPop,
    Object? result,
  ) async {
    if (didPop) {
      return;
    }

    final canLeave = await confirmDiscardListing();

    if (!mounted || !canLeave) {
      return;
    }

    allowRoutePop(result);
  }

  Future<void> handleBack() async {
    final canLeave = await confirmDiscardListing();

    if (!mounted || !canLeave) {
      return;
    }

    allowRoutePop();
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError
              ? const Color(0xFFB3261E)
              : const Color(0xFF147D64),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      );
  }

  String formatNumber(
    double value,
  ) {
    return value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  void clearFieldErrors() {
    productNameError = null;
    descriptionError = null;
    imageError = null;
    priceError = null;
    quantityError = null;
    percentageError = null;
  }

  void refreshPreview() {
    setState(() {
      productNameError = null;
      descriptionError = null;
      priceError = null;
    });
  }

  void calculateSuggestedThreshold() {
    final quantity =
        double.tryParse(quantityController.text.trim()) ?? 0;
    final percentage =
        double.tryParse(percentageController.text.trim()) ?? 20;

    if (quantity <= 0) {
      lowStockController.clear();
    } else {
      final safePercentage =
          percentage.clamp(1, 100).toDouble();

      lowStockController.text = formatNumber(
        quantity * safePercentage / 100,
      );
    }

    setState(() {
      quantityError = null;
      percentageError = null;
    });
  }

  Future<void> pickProductImage() async {
    if (isPosting || isUploadingImage) {
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
        uploadedImageUrl = '';
        imageError = null;
      });
    } catch (_) {
      showMessage(
        'Unable to open the image gallery. Please try again.',
        isError: true,
      );
    }
  }

  void removeProductImage() {
    if (isPosting || isUploadingImage) {
      return;
    }

    setState(() {
      selectedImage = null;
      uploadedImageUrl = '';
    });
  }

  FishStockInput? buildInputFromForm({
    required String imageUrl,
  }) {
    final productName = productNameController.text.trim();
    final description = descriptionController.text.trim();
    final price = double.tryParse(
      priceController.text.trim(),
    );
    final quantity = double.tryParse(
      quantityController.text.trim(),
    );
    final percentage = double.tryParse(
      percentageController.text.trim(),
    );
    final lowStockLevel = double.tryParse(
      lowStockController.text.trim(),
    );

    clearFieldErrors();

    if (productName.length < 2) {
      productNameError = 'Enter a valid fish product name.';
    }

    if (description.length < 8) {
      descriptionError =
          'Add a short description with at least 8 characters.';
    }

    if (imageUrl.trim().isEmpty) {
      imageError = 'Add a clear product photo before publishing.';
    }

    if (price == null || price <= 0) {
      priceError = 'Enter a selling price greater than zero.';
    }

    if (quantity == null || quantity <= 0) {
      quantityError =
          'Enter available stock greater than zero.';
    }

    if (percentage == null ||
        percentage < 1 ||
        percentage > 100) {
      percentageError =
          'Use a low-stock percentage from 1% to 100%.';
    }

    final hasErrors = productNameError != null ||
        descriptionError != null ||
        imageError != null ||
        priceError != null ||
        quantityError != null ||
        percentageError != null;

    if (hasErrors ||
        price == null ||
        quantity == null ||
        percentage == null ||
        lowStockLevel == null) {
      setState(() {});

      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );

      showMessage(
        'Please review the highlighted listing details.',
        isError: true,
      );
      return null;
    }

    return FishStockInput(
      productName: productName,
      description: description,
      category: selectedCategory,
      unit: selectedUnit,
      emoji: '🐟',
      imageUrl: imageUrl,
      price: price,
      quantity: quantity,
      lowStockLevel: lowStockLevel,
      lowStockPercentage: percentage,
    );
  }

  Future<String?> uploadSelectedImage() async {
    if (uploadedImageUrl.trim().isNotEmpty) {
      return uploadedImageUrl;
    }

    final image = selectedImage;

    if (image == null) {
      setState(() {
        imageError = 'Add a clear product photo before publishing.';
      });
      return null;
    }

    setState(() {
      isUploadingImage = true;
    });

    try {
      final imageUrl =
          await cloudinaryUploadService.uploadImage(
        image,
        folder: 'isdalink/fish_stocks',
      );

      if (!mounted) {
        return null;
      }

      setState(() {
        uploadedImageUrl = imageUrl;
        imageError = null;
      });

      return imageUrl;
    } catch (_) {
      showMessage(
        'The product photo could not be uploaded. Check your connection and try again.',
        isError: true,
      );
      return null;
    } finally {
      if (mounted) {
        setState(() {
          isUploadingImage = false;
        });
      }
    }
  }

  Future<void> submitPost() async {
    if (isPosting || isUploadingImage) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Please log in before publishing fish stock.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    if (!hasProductImage) {
      setState(() {
        imageError = 'Add a clear product photo before publishing.';
      });

      showMessage(
        'Add a product photo before publishing.',
        isError: true,
      );
      return;
    }

    setState(() {
      isPosting = true;
    });

    try {
      final imageUrl = await uploadSelectedImage();

      if (imageUrl == null || !mounted) {
        return;
      }

      final input = buildInputFromForm(
        imageUrl: imageUrl,
      );

      if (input == null) {
        return;
      }

      await fishStockService.createFishStockPost(
        user: user,
        input: input,
      );

      if (!mounted) {
        return;
      }

      await showStockPostedDialog(input);
    } on FirebaseException {
      showMessage(
        'The stock listing could not be published. Please check your connection and try again.',
        isError: true,
      );
    } on StateError catch (error) {
      showMessage(
        error.message,
        isError: true,
      );
    } catch (_) {
      showMessage(
        'Something went wrong while publishing the stock listing.',
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

  Future<void> showStockPostedDialog(
    FishStockInput input,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
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
              borderRadius: BorderRadius.circular(26),
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
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F8F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF147D64),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Fish Stock Published',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${input.productName} is now available for vendor COD orders.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF657C8E),
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    13,
                    12,
                    13,
                    12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F7FB),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Column(
                    children: [
                      _DialogSummaryRow(
                        label: 'Price',
                        value:
                            '₱${formatNumber(input.price)} per ${input.unit}',
                      ),
                      const SizedBox(height: 8),
                      _DialogSummaryRow(
                        label: 'Available',
                        value:
                            '${formatNumber(input.quantity)} ${input.unit}',
                      ),
                      const SizedBox(height: 8),
                      _DialogSummaryRow(
                        label: 'Low-stock alert',
                        value:
                            '${formatNumber(input.lowStockLevel)} ${input.unit} (${formatNumber(input.lowStockPercentage)}%)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          clearForm();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF146BFF),
                          side: const BorderSide(
                            color: Color(0xFF9BD6FF),
                          ),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Post Another',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          allowRoutePop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF146BFF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Dashboard',
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
      selectedImage = null;
      uploadedImageUrl = '';
      useCustomPercentage = false;
      clearFieldErrors();
    });

    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope<Object?>(
        canPop: allowPop || !hasUnsavedListing,
        onPopInvokedWithResult: handlePopInvoked,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFF4F8FB),
        body: CustomScrollView(
          controller: scrollController,
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            PostStockHeader(
              onBack: handleBack,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                18,
                17,
                18,
                24,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    FishStockProductInformationCard(
                      productNameController: productNameController,
                      descriptionController: descriptionController,
                      categories: categories,
                      selectedCategory: selectedCategory,
                      productNameError: productNameError,
                      descriptionError: descriptionError,
                      onPreviewChanged: refreshPreview,
                      onCategoryChanged: (
                        value,
                      ) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    FishStockImageUploadCard(
                      selectedImage: selectedImage,
                      uploadedImageUrl: uploadedImageUrl,
                      isUploading: isUploadingImage,
                      errorText: imageError,
                      onPickImage: pickProductImage,
                      onRemoveImage: removeProductImage,
                    ),
                    FishStockPriceStockCard(
                      priceController: priceController,
                      quantityController: quantityController,
                      lowStockController: lowStockController,
                      percentageController: percentageController,
                      units: units,
                      selectedUnit: selectedUnit,
                      isCustomPercentage: useCustomPercentage,
                      priceError: priceError,
                      quantityError: quantityError,
                      percentageError: percentageError,
                      onPreviewChanged: refreshPreview,
                      onPercentageChanged:
                          calculateSuggestedThreshold,
                      onCustomPercentageChanged: (
                        value,
                      ) {
                        setState(() {
                          useCustomPercentage = value;
                        });
                      },
                      onUnitChanged: (
                        value,
                      ) {
                        setState(() {
                          selectedUnit = value;
                        });
                        calculateSuggestedThreshold();
                      },
                    ),
                    FishStockPreviewCard(
                      productName: productNameController.text,
                      price: priceController.text,
                      quantity: quantityController.text,
                      lowStockLevel: lowStockController.text,
                      selectedCategory: selectedCategory,
                      selectedUnit: selectedUnit,
                      selectedImage: selectedImage,
                      uploadedImageUrl: uploadedImageUrl,
                    ),
                    FishStockInfoCard(
                      productInformationComplete:
                          productInformationComplete,
                      photoComplete: hasProductImage,
                      priceAndStockComplete:
                          priceAndStockComplete,
                      listingReady: listingReady,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          bottomNavigationBar: FishStockSubmitButton(
            isPosting: isPosting || isUploadingImage,
            isEnabled: listingReady,
            onPressed: submitPost,
          ),
        ),
      ),
    );
  }
}

class _DialogSummaryRow extends StatelessWidget {
  const _DialogSummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7B8FA3),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF102C44),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

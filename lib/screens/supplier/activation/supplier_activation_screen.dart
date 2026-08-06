import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/screens/supplier/activation/supplier_caraga_locations.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_common.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_header.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_review.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_unit_card.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_verification_photo_card.dart';
import 'package:isdalink/services/cloudinary_upload_service.dart';
import 'package:isdalink/services/supplier_activation_service.dart';

class SupplierActivationScreen extends StatefulWidget {
  const SupplierActivationScreen({super.key});

  @override
  State<SupplierActivationScreen> createState() =>
      _SupplierActivationScreenState();
}

class _SupplierActivationScreenState extends State<SupplierActivationScreen> {
  static const stepTitles = <String>[
    'Owner',
    'Store',
    'Units',
    'Verify',
    'Review',
  ];

  final ownerNameController = TextEditingController();
  final ownerAddressController = TextEditingController();
  final emailController = TextEditingController();
  final contactNumberController = TextEditingController();
  final businessNameController = TextEditingController();
  final storeAddressController = TextEditingController();
  final primaryMarketAreaController = TextEditingController();
  final storeDescriptionController = TextEditingController();
  final businessPermitNumberController = TextEditingController();

  final activationService = const SupplierActivationService();
  final uploadService = const CloudinaryUploadService();
  final imagePicker = ImagePicker();
  final scrollController = ScrollController();

  int currentStep = 0;
  bool kiloUnit = false;
  bool tabUnit = false;
  bool iceboxUnit = false;
  bool confirmedAccuracy = false;
  bool isLoadingProfile = true;
  bool isSubmitting = false;
  bool isUploadingPermit = false;
  bool isUploadingStorePhoto = false;
  bool applicationSubmitted = false;
  bool allowPop = false;

  String? selectedProvince;
  String? selectedLocality;
  XFile? permitImage;
  XFile? storeImage;
  String permitImageUrl = '';
  String storeImageUrl = '';
  String baselineFingerprint = '';

  List<TextEditingController> get controllers => [
        ownerNameController,
        ownerAddressController,
        emailController,
        contactNumberController,
        businessNameController,
        storeAddressController,
        primaryMarketAreaController,
        storeDescriptionController,
        businessPermitNumberController,
      ];

  int get enabledUnitCount =>
      [kiloUnit, tabUnit, iceboxUnit].where((value) => value).length;

  List<String> get supportedUnits {
    return <String>[
      if (kiloUnit) 'kilo',
      if (tabUnit) 'tab',
      if (iceboxUnit) 'icebox',
    ];
  }

  bool get uploadsInProgress => isUploadingPermit || isUploadingStorePhoto;
  bool get isLastStep => currentStep == stepTitles.length - 1;

  bool get ownerComplete =>
      ownerNameController.text.trim().length >= 2 &&
      ownerAddressController.text.trim().length >= 5 &&
      isValidEmail(emailController.text) &&
      isValidMobile(contactNumberController.text);

  bool get storeComplete =>
      businessNameController.text.trim().length >= 2 &&
      SupplierCaragaLocations.isValidSelection(
        province: selectedProvince,
        locality: selectedLocality,
      ) &&
      storeAddressController.text.trim().length >= 5 &&
      primaryMarketAreaController.text.trim().length >= 2 &&
      storeDescriptionController.text.trim().length >= 8;

  bool get unitComplete => supportedUnits.isNotEmpty;

  bool get verificationComplete =>
      isValidPermitNumber(businessPermitNumberController.text) &&
      permitImageUrl.isNotEmpty &&
      storeImageUrl.isNotEmpty &&
      !uploadsInProgress;

  bool get reviewComplete =>
      ownerComplete &&
      storeComplete &&
      unitComplete &&
      verificationComplete &&
      confirmedAccuracy;

  bool get currentStepComplete {
    return switch (currentStep) {
      0 => ownerComplete,
      1 => storeComplete,
      2 => unitComplete,
      3 => verificationComplete,
      _ => reviewComplete,
    };
  }

  String get formattedStoreLocation {
    final parts = <String>[
      storeAddressController.text.trim(),
      selectedLocality ?? '',
      ?selectedProvince,
      'Caraga Region',
    ];

    return parts.where((part) => part.isNotEmpty).join(', ');
  }

  String get fingerprint => <String>[
        for (final controller in controllers) controller.text.trim(),
        selectedProvince ?? '',
        selectedLocality ?? '',
        kiloUnit.toString(),
        tabUnit.toString(),
        iceboxUnit.toString(),
        permitImageUrl,
        storeImageUrl,
        confirmedAccuracy.toString(),
      ].join('|');

  bool get hasUnsavedChanges =>
      !applicationSubmitted &&
      !isLoadingProfile &&
      fingerprint != baselineFingerprint;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    ownerNameController.text = user?.displayName ?? '';
    emailController.text = user?.email ?? '';

    for (final controller in controllers) {
      controller.addListener(refreshState);
    }

    loadProfileDefaults();
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.removeListener(refreshState);
      controller.dispose();
    }
    scrollController.dispose();
    super.dispose();
  }

  void refreshState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadProfileDefaults() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        isLoadingProfile = false;
        baselineFingerprint = fingerprint;
      });
      return;
    }

    try {
      final data = await activationService.loadApplicationDefaults(user);

      if (!mounted) {
        return;
      }

      final supplierStatus = activationService.getStringValue(
        data,
        'supplierStatus',
        activationService.getStringValue(data, 'status', 'not_applicable'),
      ).toLowerCase();

      applicationSubmitted = supplierStatus == 'pending';

      ownerNameController.text = activationService.getStringValue(
        data,
        'name',
        activationService.getStringValue(
          data,
          'ownerName',
          ownerNameController.text,
        ),
      );
      emailController.text = activationService.getStringValue(
        data,
        'email',
        user.email ?? '',
      );
      contactNumberController.text = activationService.getStringValue(
        data,
        'phone',
        activationService.getStringValue(data, 'contactNumber', ''),
      );
      ownerAddressController.text = activationService.getStringValue(
        data,
        'ownerAddress',
        activationService.getStringValue(data, 'location', ''),
      );
      businessNameController.text = activationService.getStringValue(
        data,
        'businessName',
        activationService.getStringValue(data, 'storeName', ''),
      );
      storeAddressController.text =
          activationService.getStringValue(data, 'storeAddress', '');
      primaryMarketAreaController.text = activationService.getStringValue(
        data,
        'primaryMarketArea',
        activationService.getStringValue(data, 'serviceArea', ''),
      );
      storeDescriptionController.text =
          activationService.getStringValue(data, 'description', '');
      businessPermitNumberController.text = activationService.getStringValue(
        data,
        'businessPermitNumber',
        '',
      );
      permitImageUrl =
          activationService.getStringValue(data, 'businessPermitUrl', '');
      storeImageUrl =
          activationService.getStringValue(data, 'storePhotoUrl', '');

      final savedProvince =
          activationService.getStringValue(data, 'storeProvince', '');
      final savedLocality = activationService.getStringValue(
        data,
        'storeCityMunicipality',
        '',
      );

      selectedProvince = SupplierCaragaLocations.byProvince
              .containsKey(savedProvince)
          ? savedProvince
          : null;

      if (savedLocality == 'City of Butuan' ||
          savedLocality == 'Butuan City') {
        selectedProvince = 'Agusan del Norte';
        selectedLocality = 'Butuan City';
      } else if (selectedProvince != null &&
          SupplierCaragaLocations.localitiesFor(selectedProvince)
              .contains(savedLocality)) {
        selectedLocality = savedLocality;
      }

      final unitValues = data['supportedUnits'];
      final units = unitValues is Iterable
          ? unitValues.map((value) => value.toString().toLowerCase()).toSet()
          : <String>{};

      kiloUnit = units.contains('kilo') || units.contains('kilogram');
      tabUnit = units.contains('tab');
      iceboxUnit = units.contains('icebox');
    } catch (_) {
      showMessage(
        'Some saved account details could not be loaded. You may still complete the application.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingProfile = false;
          baselineFingerprint = fingerprint;
        });
      }
    }
  }

  String cleanPhone(String value) {
    return value
        .trim()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');
  }

  bool isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  bool isValidMobile(String value) {
    return RegExp(r'^(09\d{9}|\+639\d{9})$').hasMatch(cleanPhone(value));
  }

  bool isValidPermitNumber(String value) {
    final cleaned = value.trim();
    return cleaned.length >= 6 &&
        cleaned.length <= 30 &&
        RegExp(r'^[A-Za-z0-9-]+$').hasMatch(cleaned);
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          backgroundColor: isError
              ? const Color(0xFFD94A45)
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

  Future<bool> confirmDiscard() async {
    if (!hasUnsavedChanges) {
      return true;
    }

    if (isSubmitting || uploadsInProgress) {
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: const Icon(
            Icons.edit_note_rounded,
            color: Color(0xFFFF7A1A),
            size: 34,
          ),
          title: const Text(
            'Discard supplier application?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF102C44),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Your entered details and selected verification photos have not been submitted.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF657C8E),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Continue Editing'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD94A45),
                foregroundColor: Colors.white,
              ),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return result ?? false;
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

    final canLeave = await confirmDiscard();

    if (!mounted || !canLeave) {
      return;
    }

    allowRoutePop(result);
  }

  Future<void> closeScreen() async {
    final canClose = await confirmDiscard();

    if (!mounted || !canClose) {
      return;
    }

    allowRoutePop();
  }

  void scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void previousStep() {
    FocusScope.of(context).unfocus();

    if (currentStep == 0) {
      closeScreen();
      return;
    }

    setState(() => currentStep -= 1);
    scrollToTop();
  }

  void nextStep() {
    if (!currentStepComplete || isSubmitting || uploadsInProgress) {
      showMessage(incompleteMessage(), isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    if (isLastStep) {
      submitApplication();
      return;
    }

    setState(() => currentStep += 1);
    scrollToTop();
  }

  String incompleteMessage() {
    return switch (currentStep) {
      0 => 'Complete the valid owner and contact details before continuing.',
      1 => 'Complete the structured Caraga store location and store details.',
      2 => 'Select at least one supported selling unit.',
      3 => 'Enter the matching permit number and upload both verification photos.',
      _ => 'Review the details and confirm their accuracy before submitting.',
    };
  }

  Future<void> selectProvince() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SupplierSelectionSheet(
        title: 'Select Province',
        subtitle: 'Choose one of Caraga Region’s five provinces.',
        items: SupplierCaragaLocations.provinces,
        selectedValue: selectedProvince,
      ),
    );

    if (!mounted || value == null) {
      return;
    }

    setState(() {
      selectedProvince = value;
      if (!SupplierCaragaLocations.localitiesFor(value)
          .contains(selectedLocality)) {
        selectedLocality = null;
      }
    });
  }

  void clearProvince() {
    setState(() {
      selectedProvince = null;
      selectedLocality = null;
    });
  }

  Future<void> selectLocality() async {
    if (selectedProvince == null) {
      showMessage(
        'Select a province before choosing a city or municipality.',
        isError: true,
      );
      return;
    }

    final items = SupplierCaragaLocations.localitiesFor(selectedProvince);
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SupplierSelectionSheet(
        title: 'Select City or Municipality',
        subtitle: 'Choose a locality within $selectedProvince.',
        items: items,
        selectedValue: selectedLocality,
      ),
    );

    if (!mounted || value == null) {
      return;
    }

    setState(() {
      selectedLocality = value;
      if (primaryMarketAreaController.text.trim().isEmpty) {
        primaryMarketAreaController.text = value;
      }
    });
  }

  Future<ImageSource?> chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFBED0DC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Choose Photo Source',
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          ImageSource.camera,
                        ),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(
                          sheetContext,
                          ImageSource.gallery,
                        ),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
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

  Future<void> pickAndUploadPhoto({required bool permit}) async {
    if (isSubmitting || uploadsInProgress) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showMessage('Please log in before uploading photos.', isError: true);
      return;
    }

    final source = await chooseImageSource();
    if (source == null) {
      return;
    }

    try {
      final image = await imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1600,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        if (permit) {
          permitImage = image;
          permitImageUrl = '';
          isUploadingPermit = true;
        } else {
          storeImage = image;
          storeImageUrl = '';
          isUploadingStorePhoto = true;
        }
      });

      final folder = permit
          ? 'isdalink/supplier_verification/${user.uid}/permits'
          : 'isdalink/supplier_verification/${user.uid}/stores';

      final url = await uploadService.uploadImage(image, folder: folder);

      if (!mounted) {
        return;
      }

      setState(() {
        if (permit) {
          permitImageUrl = url;
        } else {
          storeImageUrl = url;
        }
      });

      showMessage(
        permit
            ? 'Business permit photo uploaded.'
            : 'Store photo uploaded.',
      );
    } catch (_) {
      showMessage(
        'The verification photo could not be uploaded. Check your connection and try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          if (permit) {
            isUploadingPermit = false;
          } else {
            isUploadingStorePhoto = false;
          }
        });
      }
    }
  }

  void removePhoto({required bool permit}) {
    setState(() {
      if (permit) {
        permitImage = null;
        permitImageUrl = '';
      } else {
        storeImage = null;
        storeImageUrl = '';
      }
    });
  }

  Future<void> submitApplication() async {
    if (!reviewComplete || isSubmitting) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showMessage('Please log in before submitting.', isError: true);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await activationService.submitSupplierApplication(
        user: user,
        input: SupplierApplicationInput(
          ownerName: ownerNameController.text.trim(),
          ownerAddress: ownerAddressController.text.trim(),
          email: emailController.text.trim(),
          contactNumber: contactNumberController.text.trim(),
          businessName: businessNameController.text.trim(),
          storeProvince: selectedProvince,
          storeCityMunicipality: selectedLocality!,
          storeAddress: storeAddressController.text.trim(),
          primaryMarketArea: primaryMarketAreaController.text.trim(),
          storeDescription: storeDescriptionController.text.trim(),
          supportedUnits: supportedUnits,
          businessPermitNumber:
              businessPermitNumberController.text.trim(),
          businessPermitUrl: permitImageUrl,
          storePhotoUrl: storeImageUrl,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        applicationSubmitted = true;
        baselineFingerprint = fingerprint;
      });
      scrollToTop();
    } on StateError catch (error) {
      showMessage(error.message.toString(), isError: true);
    } catch (_) {
      showMessage(
        'The supplier application could not be submitted. Check your connection and try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  InputDecoration fieldDecoration({
    required String label,
    required IconData icon,
    String? helperText,
    bool valid = false,
    bool locked = false,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperMaxLines: 2,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: Color(0xFF6B7F93),
        fontSize: 11.3,
        fontWeight: FontWeight.w900,
      ),
      helperStyle: const TextStyle(
        color: Color(0xFF7B8FA3),
        fontSize: 9.7,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        width: 31,
        height: 31,
        decoration: BoxDecoration(
          color: const Color(0xFFE6F9FF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: const Color(0xFF146BFF), size: 19),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 52, minHeight: 50),
      suffixIcon: valid || locked
          ? Icon(
              locked ? Icons.lock_outline_rounded : Icons.check_circle_rounded,
              color: locked
                  ? const Color(0xFF8BA0B1)
                  : const Color(0xFF1DBB8A),
              size: 19,
            )
          : null,
      filled: true,
      fillColor: const Color(0xFFF6FAFD),
      contentPadding: const EdgeInsets.fromLTRB(12, 14, 13, 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: BorderSide(
          color: valid
              ? const Color(0xFF77D7B7)
              : const Color(0xFFE5EEF6),
          width: valid ? 1.25 : 1,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: Color(0xFFE5EEF6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: Color(0xFF146BFF), width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(19),
        borderSide: const BorderSide(color: Color(0xFFE5EEF6)),
      ),
    );
  }

  Widget gap() => const SizedBox(height: 11);

  Widget ownerStep() {
    return Column(
      children: [
        const SupplierActivationIntroCard(
          icon: Icons.verified_user_outlined,
          title: 'Account Verification',
          message:
              'Use the real owner name, complete address, and active Philippine mobile number.',
        ),
        SupplierActivationSectionCard(
          icon: Icons.badge_outlined,
          title: 'Owner Information',
          subtitle: 'Identity and contact details for admin review.',
          children: [
            TextField(
              controller: ownerNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(80)],
              decoration: fieldDecoration(
                label: 'Owner Full Name',
                icon: Icons.person_outline_rounded,
                helperText: 'Use the legal name of the account owner.',
                valid: ownerNameController.text.trim().length >= 2,
              ),
            ),
            gap(),
            TextField(
              controller: ownerAddressController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              minLines: 1,
              maxLines: 2,
              inputFormatters: [LengthLimitingTextInputFormatter(180)],
              decoration: fieldDecoration(
                label: 'Complete Owner Address',
                icon: Icons.home_outlined,
                helperText: 'Include street or barangay and city or municipality.',
                valid: ownerAddressController.text.trim().length >= 5,
              ),
            ),
            gap(),
            TextField(
              controller: emailController,
              enabled: false,
              decoration: fieldDecoration(
                label: 'Registered Email Address',
                icon: Icons.email_outlined,
                helperText: 'Email changes require account verification.',
                valid: isValidEmail(emailController.text),
                locked: true,
              ),
            ),
            gap(),
            TextField(
              controller: contactNumberController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                LengthLimitingTextInputFormatter(13),
              ],
              decoration: fieldDecoration(
                label: 'Philippine Mobile Number',
                icon: Icons.phone_android_outlined,
                helperText: 'Accepted: 09XXXXXXXXX or +639XXXXXXXXX.',
                valid: isValidMobile(contactNumberController.text),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget storeStep() {
    return Column(
      children: [
        const SupplierActivationIntroCard(
          icon: Icons.storefront_outlined,
          title: 'Store Profile',
          message:
              'These approved details will appear in the supplier marketplace profile.',
        ),
        SupplierActivationSectionCard(
          icon: Icons.storefront_outlined,
          title: 'Store Information',
          subtitle: 'Business name and structured Caraga location.',
          children: [
            TextField(
              controller: businessNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              decoration: fieldDecoration(
                label: 'Business or Store Name',
                icon: Icons.store_outlined,
                helperText: 'This name will be shown to vendors.',
                valid: businessNameController.text.trim().length >= 2,
              ),
            ),
            gap(),
            SupplierSelectionField(
              label: 'Province',
              icon: Icons.map_outlined,
              value: selectedProvince,
              placeholder: 'Select province',
              onTap: selectProvince,
              onClear: selectedProvince == null ? null : clearProvince,
              helperText:
                  'Select the province where the supplier store is located.',
            ),
            gap(),
            SupplierSelectionField(
              label: 'City or Municipality',
              icon: Icons.location_city_outlined,
              value: selectedLocality,
              placeholder: selectedProvince == null
                  ? 'Select a province first'
                  : 'Select city or municipality',
              onTap: selectLocality,
              helperText: selectedProvince == null
                  ? 'Choose a province before selecting the locality.'
                  : 'Choose from the listed localities of $selectedProvince.',
            ),
            gap(),
            TextField(
              controller: storeAddressController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              minLines: 1,
              maxLines: 2,
              inputFormatters: [LengthLimitingTextInputFormatter(180)],
              decoration: fieldDecoration(
                label: 'Specific Store Address',
                icon: Icons.pin_drop_outlined,
                helperText: 'Street, barangay, landmark, or market location.',
                valid: storeAddressController.text.trim().length >= 5,
              ),
            ),
            gap(),
            TextField(
              controller: primaryMarketAreaController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              decoration: fieldDecoration(
                label: 'Primary Market Area',
                icon: Icons.location_searching_rounded,
                helperText:
                    'Main area served by the supplier. This does not calculate routes.',
                valid: primaryMarketAreaController.text.trim().length >= 2,
              ),
            ),
            gap(),
            TextField(
              controller: storeDescriptionController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 4,
              inputFormatters: [LengthLimitingTextInputFormatter(260)],
              decoration: fieldDecoration(
                label: 'Store Description',
                icon: Icons.description_outlined,
                helperText:
                    'Describe the fish source, selling setup, and regular stocks.',
                valid: storeDescriptionController.text.trim().length >= 8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget unitsStep() {
    return Column(
      children: [
        const SupplierActivationIntroCard(
          icon: Icons.scale_outlined,
          title: 'Supported Selling Units',
          message:
              'Select only the units this supplier can consistently post and fulfill.',
        ),
        SupplierActivationUnitCard(
          kiloUnit: kiloUnit,
          tabUnit: tabUnit,
          iceboxUnit: iceboxUnit,
          onKiloChanged: (value) => setState(() => kiloUnit = value),
          onTabChanged: (value) => setState(() => tabUnit = value),
          onIceboxChanged: (value) => setState(() => iceboxUnit = value),
        ),
      ],
    );
  }

  Widget verificationStep() {
    return Column(
      children: [
        const SupplierActivationIntroCard(
          icon: Icons.policy_outlined,
          title: 'Supplier Verification',
          message:
              'Admin compares the entered permit number with the uploaded permit photo.',
        ),
        SupplierActivationSectionCard(
          icon: Icons.verified_user_outlined,
          title: 'Verification Requirements',
          subtitle: 'Permit number, permit photo, and store photo.',
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F0),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFC69D)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF7A1A),
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Enter the exact permit number printed on the uploaded business permit photo.',
                      style: TextStyle(
                        color: Color(0xFF7A5328),
                        fontSize: 9.7,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            gap(),
            TextField(
              controller: businessPermitNumberController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                LengthLimitingTextInputFormatter(30),
              ],
              decoration: fieldDecoration(
                label: 'Business Permit Number',
                icon: Icons.confirmation_number_outlined,
                helperText:
                    'Use the exact letters, numbers, and hyphens shown on the permit.',
                valid: isValidPermitNumber(
                  businessPermitNumberController.text,
                ),
              ),
            ),
            gap(),
            SupplierVerificationPhotoCard(
              title: 'Business Permit Photo',
              subtitle:
                  'Upload a readable photo showing the permit number and business name.',
              permit: true,
              localImage: permitImage,
              imageUrl: permitImageUrl,
              uploading: isUploadingPermit,
              onUpload: () => pickAndUploadPhoto(permit: true),
              onRemove: () => removePhoto(permit: true),
            ),
            gap(),
            SupplierVerificationPhotoCard(
              title: 'Store Photo',
              subtitle:
                  'Upload a clear store photo used as the supplier profile cover after approval.',
              permit: false,
              localImage: storeImage,
              imageUrl: storeImageUrl,
              uploading: isUploadingStorePhoto,
              onUpload: () => pickAndUploadPhoto(permit: false),
              onRemove: () => removePhoto(permit: false),
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4E2FF)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF146BFF),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use readable photos. Blurry or mismatched records may be rejected during admin review.',
                      style: TextStyle(
                        color: Color(0xFF52677A),
                        fontSize: 9.5,
                        height: 1.32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String unitDisplayName(String value) {
    return switch (value) {
      'kilo' => 'Kilogram',
      'tab' => 'Tab',
      'icebox' => 'Icebox',
      _ => value,
    };
  }

  void editStep(int step) {
    setState(() => currentStep = step);
    scrollToTop();
  }

  Widget reviewStep() {
    return Column(
      children: [
        const SupplierActivationIntroCard(
          icon: Icons.fact_check_outlined,
          title: 'Final Review',
          message:
              'Review every section. Supplier tools remain locked until admin approval.',
        ),
        SupplierReviewSection(
          title: 'Owner Information',
          icon: Icons.person_outline_rounded,
          onEdit: () => editStep(0),
          rows: [
            SupplierReviewRow(label: 'Owner', value: ownerNameController.text),
            SupplierReviewRow(label: 'Email', value: emailController.text),
            SupplierReviewRow(
              label: 'Contact',
              value: contactNumberController.text,
            ),
            SupplierReviewRow(
              label: 'Address',
              value: ownerAddressController.text,
            ),
          ],
        ),
        SupplierReviewSection(
          title: 'Store Information',
          icon: Icons.storefront_outlined,
          onEdit: () => editStep(1),
          rows: [
            SupplierReviewRow(label: 'Store', value: businessNameController.text),
            SupplierReviewRow(label: 'Location', value: formattedStoreLocation),
            SupplierReviewRow(
              label: 'Market Area',
              value: primaryMarketAreaController.text,
            ),
            const SupplierReviewRow(
              label: 'Payment',
              value: 'Cash on Delivery only',
            ),
          ],
        ),
        SupplierReviewSection(
          title: 'Selling Units',
          icon: Icons.scale_outlined,
          onEdit: () => editStep(2),
          rows: [
            SupplierReviewRow(
              label: 'Units',
              value: supportedUnits.map(unitDisplayName).join(', '),
            ),
          ],
        ),
        SupplierReviewSection(
          title: 'Verification',
          icon: Icons.verified_user_outlined,
          onEdit: () => editStep(3),
          rows: [
            SupplierReviewRow(
              label: 'Permit No.',
              value: businessPermitNumberController.text,
            ),
          ],
          images: [
            SupplierReviewImage(
              title: 'Permit Photo',
              localImage: permitImage,
              imageUrl: permitImageUrl,
            ),
            SupplierReviewImage(
              title: 'Store Photo',
              localImage: storeImage,
              imageUrl: storeImageUrl,
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: confirmedAccuracy
                ? const Color(0xFFE8F8F2)
                : const Color(0xFFEAF7FB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: confirmedAccuracy
                  ? const Color(0xFF77D7B7)
                  : const Color(0xFFD8E8F1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: confirmedAccuracy,
                activeColor: const Color(0xFF147D64),
                onChanged: (value) {
                  setState(() => confirmedAccuracy = value ?? false);
                },
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 9),
                  child: Text(
                    'I confirm that the permit number, contact number, store details, selling units, and verification photos are accurate and valid.',
                    style: TextStyle(
                      color: Color(0xFF52677A),
                      fontSize: 10.3,
                      height: 1.38,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget submittedStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE1EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F00152A),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5FD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFF146BFF),
              size: 37,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Supplier Application Submitted',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF102C44),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Your application is awaiting admin review. You can continue using your vendor account while waiting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF657C8E),
              fontSize: 10.8,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E9),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFFFD49C)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.pending_actions_rounded,
                  color: Color(0xFFFF7A1A),
                  size: 21,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS',
                        style: TextStyle(
                          color: Color(0xFFB95A10),
                          fontSize: 8.5,
                          letterSpacing: 0.55,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Pending Admin Review',
                        style: TextStyle(
                          color: Color(0xFF7A5328),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'A second application cannot be submitted while this one is pending. Supplier tools unlock only after approval.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF52677A),
              fontSize: 9.7,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget currentStepBody() {
    if (applicationSubmitted) {
      return submittedStep();
    }

    return switch (currentStep) {
      0 => ownerStep(),
      1 => storeStep(),
      2 => unitsStep(),
      3 => verificationStep(),
      _ => reviewStep(),
    };
  }

  Widget bottomNavigation() {
    if (applicationSubmitted) {
      return _BottomBar(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.account_circle_outlined, size: 20),
            label: const Text(
              'Return to Account Center',
              style: TextStyle(fontSize: 14.2, fontWeight: FontWeight.w900),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF146BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    final canContinue = currentStepComplete &&
        !isLoadingProfile &&
        !isSubmitting &&
        !uploadsInProgress;

    return _BottomBar(
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isSubmitting || uploadsInProgress
                  ? null
                  : previousStep,
              icon: Icon(
                currentStep == 0
                    ? Icons.close_rounded
                    : Icons.arrow_back_rounded,
                size: 19,
              ),
              label: Text(
                currentStep == 0 ? 'Cancel' : 'Back',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF146BFF),
                side: const BorderSide(color: Color(0xFF146BFF)),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: canContinue ? nextStep : null,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Icon(
                      isLastStep
                          ? Icons.send_rounded
                          : Icons.arrow_forward_rounded,
                      size: 19,
                    ),
              label: Text(
                isSubmitting
                    ? 'Submitting...'
                    : canContinue
                        ? isLastStep
                            ? 'Submit Application'
                            : 'Continue'
                        : 'Complete Required Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF146BFF),
                disabledBackgroundColor: const Color(0xFFDCE7EF),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF7B8FA3),
                minimumSize: const Size.fromHeight(52),
                elevation: canContinue ? 5 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: PopScope<Object?>(
        canPop: allowPop || !hasUnsavedChanges,
        onPopInvokedWithResult: handlePopInvoked,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFFF4F8FB),
          body: CustomScrollView(
            controller: scrollController,
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SupplierActivationHeader(
                currentStep: currentStep,
                totalSteps: stepTitles.length,
                enabledUnitCount: enabledUnitCount,
                submitted: applicationSubmitted,
                onBack: closeScreen,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 25),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (!applicationSubmitted)
                      SupplierActivationProgressCard(
                        currentStep: currentStep,
                        stepTitles: stepTitles,
                        onStepTap: (step) {
                          setState(() => currentStep = step);
                          scrollToTop();
                        },
                      ),
                    if (isLoadingProfile)
                      const _LoadingCard()
                    else
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 210),
                        child: KeyedSubtree(
                          key: ValueKey<String>(
                            applicationSubmitted
                                ? 'submitted'
                                : 'step-$currentStep',
                          ),
                          child: currentStepBody(),
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
          bottomNavigationBar: bottomNavigation(),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 10, 17, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE1EBF2)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Color(0xFF146BFF),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading your account details...',
              style: TextStyle(
                color: Color(0xFF52677A),
                fontSize: 10.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

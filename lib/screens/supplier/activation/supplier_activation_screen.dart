import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/screens/map/caraga_location_picker_screen.dart';
import 'package:isdalink/screens/map/caraga_map_defaults.dart';
import 'package:isdalink/screens/supplier/activation/supplier_caraga_locations.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_common.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_header.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_review.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_verification_photo_card.dart';
import 'package:isdalink/services/cloudinary_upload_service.dart';
import 'package:isdalink/services/supplier_activation_service.dart';
import 'package:isdalink/services/supplier_verification_storage_service.dart';
import 'package:isdalink/utils/app_error_message.dart';

class _RejectionNextStep extends StatelessWidget {
  const _RejectionNextStep({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE5F3FB),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF087FCB),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF526D7D),
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RejectedApplicationFeedbackCard extends StatelessWidget {
  const _RejectedApplicationFeedbackCard({
    required this.reason,
    required this.onViewFeedback,
  });

  final String reason;
  final VoidCallback onViewFeedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1C4BC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.feedback_outlined,
              color: Color(0xFFD94E42),
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin feedback',
                  style: TextStyle(
                    color: Color(0xFF713B34),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF87554E),
                    fontSize: 11.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onViewFeedback,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF087FCB),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'View',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class SupplierActivationScreen extends StatefulWidget {
  const SupplierActivationScreen({
    super.key,
    this.rejectionNotificationId = '',
  });

  final String rejectionNotificationId;

  @override
  State<SupplierActivationScreen> createState() =>
      _SupplierActivationScreenState();
}

class _SupplierActivationScreenState extends State<SupplierActivationScreen> {
  static const stepTitles = <String>['Owner', 'Store', 'Verify', 'Review'];

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
  final verificationStorageService = const SupplierVerificationStorageService();
  final imagePicker = ImagePicker();
  final scrollController = ScrollController();

  int currentStep = 0;
  bool confirmedAccuracy = false;
  bool isLoadingProfile = true;
  bool isSubmitting = false;
  bool isUploadingPermit = false;
  bool isUploadingStorePhoto = false;
  bool applicationSubmitted = false;
  bool allowPop = false;
  bool rejectionReasonHandled = false;

  String activeRejectionReason = '';

  String? selectedProvince;
  String? selectedLocality;
  double? storeLatitude;
  double? storeLongitude;
  XFile? permitImage;
  XFile? storeImage;
  String permitImageUrl = '';
  String permitStoragePath = '';
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

  bool get uploadsInProgress => isUploadingPermit || isUploadingStorePhoto;
  bool get isLastStep => currentStep == stepTitles.length - 1;

  bool get ownerComplete =>
      ownerNameController.text.trim().length >= 2 &&
      ownerAddressController.text.trim().length >= 5 &&
      isValidEmail(emailController.text) &&
      isValidMobile(contactNumberController.text);

  bool get hasValidStorePin {
    final latitude = storeLatitude;
    final longitude = storeLongitude;

    if (latitude == null || longitude == null) {
      return false;
    }

    return CaragaMapDefaults.containsCoordinates(
      latitude: latitude,
      longitude: longitude,
      province: selectedProvince,
      locality: selectedLocality,
    );
  }

  bool get storeComplete =>
      businessNameController.text.trim().length >= 2 &&
      SupplierCaragaLocations.isValidSelection(
        province: selectedProvince,
        locality: selectedLocality,
      ) &&
      storeAddressController.text.trim().length >= 5 &&
      hasValidStorePin &&
      primaryMarketAreaController.text.trim().length >= 2 &&
      storeDescriptionController.text.trim().length >= 8;

  bool get verificationComplete =>
      isValidPermitNumber(businessPermitNumberController.text) &&
      (permitStoragePath.isNotEmpty || permitImageUrl.isNotEmpty) &&
      storeImageUrl.isNotEmpty &&
      !uploadsInProgress;

  bool get reviewDetailsComplete =>
      ownerComplete && storeComplete && verificationComplete;

  bool get reviewComplete => reviewDetailsComplete && confirmedAccuracy;

  bool get currentStepComplete {
    return switch (currentStep) {
      0 => ownerComplete,
      1 => storeComplete,
      2 => verificationComplete,
      _ => reviewComplete,
    };
  }

  List<String> get missingRequirements {
    final missing = <String>[];

    switch (currentStep) {
      case 0:
        if (ownerNameController.text.trim().length < 2) {
          missing.add('owner’s legal name');
        }
        if (ownerAddressController.text.trim().length < 5) {
          missing.add('complete owner address');
        }
        if (!isValidEmail(emailController.text)) {
          missing.add('registered email address');
        }
        if (!isValidMobile(contactNumberController.text)) {
          missing.add('valid Philippine mobile number');
        }
        break;
      case 1:
        if (businessNameController.text.trim().length < 2) {
          missing.add('business or store name');
        }
        if (selectedProvince == null) {
          missing.add('province');
        }
        if (selectedLocality == null) {
          missing.add('city or municipality');
        }
        if (storeAddressController.text.trim().length < 5) {
          missing.add('specific store address');
        }
        if (!hasValidStorePin) {
          missing.add('valid business location pin');
        }
        if (primaryMarketAreaController.text.trim().length < 2) {
          missing.add('primary market area');
        }
        if (storeDescriptionController.text.trim().length < 8) {
          missing.add('store description');
        }
        break;
      case 2:
        if (!isValidPermitNumber(businessPermitNumberController.text)) {
          missing.add('valid business permit number');
        }
        if (permitStoragePath.isEmpty && permitImageUrl.isEmpty) {
          missing.add('business permit photo');
        }
        if (storeImageUrl.isEmpty) {
          missing.add('store verification photo');
        }
        if (uploadsInProgress) {
          missing.add('photo upload to finish');
        }
        break;
      default:
        if (!ownerComplete) {
          missing.add('complete owner details');
        }
        if (!storeComplete) {
          missing.add('complete store details');
        }
        if (!verificationComplete) {
          missing.add('complete verification details');
        }
        if (!confirmedAccuracy) {
          missing.add('accuracy confirmation');
        }
        break;
    }

    return missing;
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
    storeLatitude?.toStringAsFixed(6) ?? '',
    storeLongitude?.toStringAsFixed(6) ?? '',
    permitImageUrl,
    permitStoragePath,
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

      final supplierStatus = activationService
          .getStringValue(
            data,
            'supplierStatus',
            activationService.getStringValue(data, 'status', 'not_applicable'),
          )
          .toLowerCase();

      applicationSubmitted = supplierStatus == 'pending';
      activeRejectionReason =
          supplierStatus == 'rejected' || supplierStatus == 'declined'
          ? activationService.getStringValue(data, 'rejectionReason', '')
          : '';

      ownerNameController.text = activationService.getStringValue(
        data,
        'name',
        activationService.getStringValue(
          data,
          'ownerName',
          ownerNameController.text,
        ),
      );
      emailController.text = user.email?.trim() ?? '';
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
      storeAddressController.text = activationService.getStringValue(
        data,
        'storeAddress',
        '',
      );
      primaryMarketAreaController.text = activationService.getStringValue(
        data,
        'primaryMarketArea',
        activationService.getStringValue(data, 'serviceArea', ''),
      );
      storeDescriptionController.text = activationService.getStringValue(
        data,
        'description',
        '',
      );
      businessPermitNumberController.text = activationService.getStringValue(
        data,
        'businessPermitNumber',
        '',
      );
      permitImageUrl = activationService.getStringValue(
        data,
        'businessPermitUrl',
        '',
      );
      permitStoragePath = activationService.getStringValue(
        data,
        'businessPermitStoragePath',
        '',
      );
      storeImageUrl = activationService.getStringValue(
        data,
        'storePhotoUrl',
        '',
      );

      final savedLatitude = data['storeLatitude'];
      final savedLongitude = data['storeLongitude'];

      storeLatitude = savedLatitude is num
          ? savedLatitude.toDouble()
          : double.tryParse(savedLatitude?.toString() ?? '');
      storeLongitude = savedLongitude is num
          ? savedLongitude.toDouble()
          : double.tryParse(savedLongitude?.toString() ?? '');

      final savedProvince = activationService.getStringValue(
        data,
        'storeProvince',
        '',
      );
      final savedLocality = activationService.getStringValue(
        data,
        'storeCityMunicipality',
        '',
      );

      selectedProvince =
          SupplierCaragaLocations.byProvince.containsKey(savedProvince)
          ? savedProvince
          : null;

      if (savedLocality == 'City of Butuan' || savedLocality == 'Butuan City') {
        selectedProvince = 'Agusan del Norte';
        selectedLocality = 'Butuan City';
      } else if (selectedProvince != null &&
          SupplierCaragaLocations.localitiesFor(
            selectedProvince,
          ).contains(savedLocality)) {
        selectedLocality = savedLocality;
      }

      if (!hasValidStorePin) {
        storeLatitude = null;
        storeLongitude = null;
      }
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

    await showRejectionReasonIfNeeded(user);
  }

  Future<void> showRejectionReasonIfNeeded(User user) async {
    if (rejectionReasonHandled || !mounted) {
      return;
    }

    rejectionReasonHandled = true;

    try {
      final notice = await activationService.loadUnseenRejectionNotice(
        user: user,
        notificationId: widget.rejectionNotificationId,
      );

      if (notice == null || notice.reason.trim().isEmpty || !mounted) {
        return;
      }

      activeRejectionReason = notice.reason.trim();
      if (mounted) {
        setState(() {});
      }

      await showRejectionFeedbackDialog(activeRejectionReason);

      await activationService.markRejectionReasonViewed(
        user: user,
        notificationId: notice.notificationId,
      );
    } catch (error) {
      debugPrint('Could not show rejection reason: $error');
    }
  }

  Future<void> showRejectionFeedbackDialog(String reason) async {
    final feedback = reason.trim();
    if (!mounted || feedback.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0xB3001322),
      builder: (dialogContext) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;

        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: screenHeight * 0.84,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF073B5C),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF2A789E), width: 0.8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33001322),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF073B5C), Color(0xFF075D89)],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE9E5),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFFD94E42),
                                  size: 15,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'UPDATE REQUIRED',
                                  style: TextStyle(
                                    color: Color(0xFFB74339),
                                    fontSize: 9.2,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x26001322),
                                  blurRadius: 14,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.assignment_late_rounded,
                              color: Color(0xFFE25C4B),
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Supplier Application Declined',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Admin review found details that need to be updated before you resubmit.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFD9EEF7),
                              fontSize: 12.2,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings_outlined,
                                color: Color(0xFF315B73),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Admin Feedback',
                                style: TextStyle(
                                  color: Color(0xFF183C52),
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7F5),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(color: const Color(0xFFF2C2BA)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.format_quote_rounded,
                                  color: Color(0xFFD95A4D),
                                  size: 20,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    feedback,
                                    style: const TextStyle(
                                      color: Color(0xFF713B34),
                                      fontSize: 13.5,
                                      height: 1.45,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F8FB),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(color: const Color(0xFFDCEAF2)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'What to do next',
                                  style: TextStyle(
                                    color: Color(0xFF183C52),
                                    fontSize: 12.4,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 10),
                                _RejectionNextStep(
                                  number: '1',
                                  text: 'Review the admin feedback above.',
                                ),
                                SizedBox(height: 7),
                                _RejectionNextStep(
                                  number: '2',
                                  text: 'Update the requested details or verification photo.',
                                ),
                                SizedBox(height: 7),
                                _RejectionNextStep(
                                  number: '3',
                                  text: 'Review everything, then resubmit for admin review.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.edit_rounded, size: 19),
                              label: const Text(
                                'Continue Updating',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFF087FCB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
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
        );
      },
    );
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

  String applicationSubmissionError(Object error) {
    final message = AppErrorMessage.from(
      error,
      fallback:
          'The supplier application could not be submitted. Please try again.',
      allowBusinessMessage: true,
    );

    if (message.toLowerCase().contains('permission')) {
      return 'We couldn’t submit the application because the account session or saved profile is out of date. Sign out, sign in again, and retry.';
    }

    return message;
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

  Future<void> handlePopInvoked(bool didPop, Object? result) async {
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
    final missing = missingRequirements;
    if (missing.isEmpty) {
      return 'Please wait a moment, then try again.';
    }

    return 'Still needed: ${missing.join(', ')}.';
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
      final provinceChanged = selectedProvince != value;

      selectedProvince = value;

      if (!SupplierCaragaLocations.localitiesFor(
        value,
      ).contains(selectedLocality)) {
        selectedLocality = null;
      }

      if (provinceChanged) {
        storeLatitude = null;
        storeLongitude = null;
      }
    });
  }

  void clearProvince() {
    setState(() {
      selectedProvince = null;
      selectedLocality = null;
      storeLatitude = null;
      storeLongitude = null;
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
      final localityChanged = selectedLocality != value;

      selectedLocality = value;

      if (localityChanged) {
        storeLatitude = null;
        storeLongitude = null;
      }

      if (primaryMarketAreaController.text.trim().isEmpty) {
        primaryMarketAreaController.text = value;
      }
    });
  }

  Future<void> selectBusinessLocationPin() async {
    if (selectedProvince == null || selectedLocality == null) {
      showMessage(
        'Select the store province and city or municipality before placing the business location pin.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final result = await Navigator.of(context).push<CaragaLocationResult>(
      MaterialPageRoute(
        builder: (_) => CaragaLocationPickerScreen(
          title: 'Business Location Pin',
          subtitle: '$selectedLocality, $selectedProvince',
          province: selectedProvince,
          locality: selectedLocality,
          initialLatitude: storeLatitude,
          initialLongitude: storeLongitude,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      storeLatitude = result.latitude;
      storeLongitude = result.longitude;
    });

    showMessage('Business location pin saved.');
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
                        onPressed: () =>
                            Navigator.pop(sheetContext, ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pop(sheetContext, ImageSource.gallery),
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
          permitStoragePath = '';
          isUploadingPermit = true;
        } else {
          storeImage = image;
          storeImageUrl = '';
          isUploadingStorePhoto = true;
        }
      });

      final uploadedValue = permit
          ? await verificationStorageService.uploadBusinessPermit(
              uid: user.uid,
              image: image,
            )
          : await uploadService.uploadImage(
              image,
              folder: 'isdalink/supplier_verification/${user.uid}/stores',
            );

      if (!mounted) {
        return;
      }

      setState(() {
        if (permit) {
          permitStoragePath = uploadedValue;
        } else {
          storeImageUrl = uploadedValue;
        }
      });

      showMessage(
        permit
            ? 'Business permit photo uploaded.'
            : 'Store verification photo uploaded.',
      );
    } on StateError catch (error) {
      showMessage(error.message.toString(), isError: true);
    } catch (error) {
      showMessage(
        AppErrorMessage.from(
          error,
          fallback:
              'The verification photo could not be uploaded. Please try again.',
          allowBusinessMessage: true,
        ),
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
        permitStoragePath = '';
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
          storeLatitude: storeLatitude!,
          storeLongitude: storeLongitude!,
          primaryMarketArea: primaryMarketAreaController.text.trim(),
          storeDescription: storeDescriptionController.text.trim(),
          businessPermitNumber: businessPermitNumberController.text.trim(),
          businessPermitUrl: permitImageUrl,
          businessPermitStoragePath: permitStoragePath,
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
    } catch (error, stackTrace) {
      // Keep the exact Firebase/Firestore failure visible in flutter run logs
      // while still showing the user a clean message in the UI.
      debugPrint('Supplier application submission failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      showMessage(applicationSubmissionError(error), isError: true);
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
        fontSize: 10.3,
        fontWeight: FontWeight.w900,
      ),
      helperStyle: const TextStyle(
        color: Color(0xFF7B8FA3),
        fontSize: 9.1,
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
        child: Icon(icon, color: const Color(0xFF087FCB), size: 18),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 48),
      suffixIcon: valid || locked
          ? Icon(
              locked ? Icons.lock_outline_rounded : Icons.check_circle_rounded,
              color: locked ? const Color(0xFF8BA0B1) : const Color(0xFF1DBB8A),
              size: 19,
            )
          : null,
      filled: true,
      fillColor: const Color(0xFFF6FAFD),
      contentPadding: const EdgeInsets.fromLTRB(11, 12, 12, 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: valid ? const Color(0xFF77D7B7) : const Color(0xFFE5EEF6),
          width: valid ? 1.25 : 1,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFFE5EEF6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFF087FCB), width: 1.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: Color(0xFFE5EEF6)),
      ),
    );
  }

  Widget gap() => const SizedBox(height: 11);

  Widget ownerStep() {
    return SupplierActivationSectionCard(
      icon: Icons.person_outline_rounded,
      title: 'Owner Information',
      subtitle: 'Use the account owner’s real contact details for admin review.',
      children: [
        TextField(
          controller: ownerNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          inputFormatters: [LengthLimitingTextInputFormatter(80)],
          decoration: fieldDecoration(
            label: 'Full Name (as legal name)',
            icon: Icons.person_outline_rounded,
            helperText: 'Use the legal name of the account owner.',
            valid: ownerNameController.text.trim().length >= 2,
          ),
        ),
        gap(),
        TextField(
          controller: emailController,
          enabled: false,
          decoration: fieldDecoration(
            label: 'Email Address',
            icon: Icons.email_outlined,
            helperText: 'This is your registered IsdaLink email.',
            valid: isValidEmail(emailController.text),
            locked: true,
          ),
        ),
        gap(),
        TextField(
          controller: contactNumberController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            LengthLimitingTextInputFormatter(13),
          ],
          decoration: fieldDecoration(
            label: 'Philippine Mobile Number',
            icon: Icons.phone_android_outlined,
            helperText: 'Use 09XXXXXXXXX or +639XXXXXXXXX.',
            valid: isValidMobile(contactNumberController.text),
          ),
        ),
        gap(),
        TextField(
          controller: ownerAddressController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
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
      ],
    );
  }

  Widget storeStep() {
    final hasPin = storeLatitude != null && storeLongitude != null;

    return SupplierActivationSectionCard(
      icon: Icons.storefront_outlined,
      title: 'Store Information',
      subtitle: 'Tell us about your store and business location in Caraga.',
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
          helperText: 'Choose the province where the supplier store is located.',
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
            helperText: 'Street, barangay, landmark, or market location only.',
            valid: storeAddressController.text.trim().length >= 5,
          ),
        ),
        gap(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasPin ? const Color(0xFFEAF8F3) : const Color(0xFFF5F9FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasPin ? const Color(0xFF8EDBC2) : const Color(0xFFDCE7EF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasPin ? Icons.location_on_rounded : Icons.add_location_alt_outlined,
                      color: const Color(0xFF087FCB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Location Pin',
                          style: TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 11.4,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pin the physical store for vendor reference and admin review.',
                          style: TextStyle(
                            color: Color(0xFF657C8E),
                            fontSize: 8.9,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasPin ? Icons.check_circle_rounded : Icons.location_searching_rounded,
                      color: hasPin ? const Color(0xFF147D64) : const Color(0xFF7B8FA3),
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        hasPin
                            ? 'Location pin selected${selectedLocality == null ? '' : ' · $selectedLocality'}'
                            : 'No business location pin selected.',
                        style: const TextStyle(
                          color: Color(0xFF52677A),
                          fontSize: 9.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                height: 43,
                child: OutlinedButton.icon(
                  onPressed: selectBusinessLocationPin,
                  icon: Icon(
                    hasPin ? Icons.edit_location_alt_outlined : Icons.map_outlined,
                    size: 18,
                  ),
                  label: Text(
                    hasPin ? 'Update Map Pin' : 'Choose on Caraga Map',
                    style: const TextStyle(fontSize: 10.1, fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF087FCB),
                    side: const BorderSide(color: Color(0xFF087FCB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                ),
              ),
            ],
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
            helperText: 'Main market area served by this supplier.',
            valid: primaryMarketAreaController.text.trim().length >= 2,
          ),
        ),
        gap(),
        TextField(
          controller: storeDescriptionController,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 4,
          inputFormatters: [LengthLimitingTextInputFormatter(240)],
          decoration: fieldDecoration(
            label: 'Store Description',
            icon: Icons.description_outlined,
            helperText: 'Briefly describe your fish source, selling setup, and regular stocks.',
            valid: storeDescriptionController.text.trim().length >= 8,
          ),
        ),
        const SizedBox(height: 3),
        const Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF7B8FA3)),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Selling unit is chosen separately when posting each fish stock.',
                style: TextStyle(
                  color: Color(0xFF7B8FA3),
                  fontSize: 8.9,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget verificationStep() {
    return SupplierActivationSectionCard(
      icon: Icons.verified_user_outlined,
      title: 'Business Verification',
      subtitle: 'Upload the permit and store photo that admin will review.',
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD4A3)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFE57612), size: 19),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The permit number must match the uploaded business permit photo.',
                  style: TextStyle(
                    color: Color(0xFF7A5328),
                    fontSize: 9.5,
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
            helperText: 'Enter the letters, numbers, and hyphens exactly as printed.',
            valid: isValidPermitNumber(businessPermitNumberController.text),
          ),
        ),
        gap(),
        SupplierVerificationPhotoCard(
          title: 'Business Permit Photo',
          subtitle: 'Upload a clear photo showing the permit number and business name.',
          permit: true,
          localImage: permitImage,
          imageUrl: permitImageUrl,
          storagePath: permitStoragePath,
          uploading: isUploadingPermit,
          onUpload: () => pickAndUploadPhoto(permit: true),
          onRemove: () => removePhoto(permit: true),
        ),
        gap(),
        SupplierVerificationPhotoCard(
          title: 'Store Verification Photo',
          subtitle: 'Upload a clear photo of the physical store for admin verification.',
          permit: false,
          localImage: storeImage,
          imageUrl: storeImageUrl,
          storagePath: '',
          uploading: isUploadingStorePhoto,
          onUpload: () => pickAndUploadPhoto(permit: false),
          onRemove: () => removePhoto(permit: false),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F7FF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFD4E2FF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF087FCB), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use readable, current photos. Blurry or mismatched records may be declined.',
                  style: TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 9.3,
                    height: 1.32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void editStep(int step) {
    setState(() => currentStep = step);
    scrollToTop();
  }

  Widget reviewStep() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 11),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF5FAFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCEBF3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.fact_check_outlined, color: Color(0xFF087FCB), size: 20),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Final Review',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Check your details before submitting. You can still edit any section.',
                      style: TextStyle(
                        color: Color(0xFF657C8E),
                        fontSize: 9.6,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SupplierReviewSection(
          title: 'Owner Information',
          icon: Icons.person_outline_rounded,
          onEdit: () => editStep(0),
          rows: [
            SupplierReviewRow(label: 'Owner', value: ownerNameController.text),
            SupplierReviewRow(label: 'Email', value: emailController.text),
            SupplierReviewRow(label: 'Contact', value: contactNumberController.text),
            SupplierReviewRow(label: 'Address', value: ownerAddressController.text),
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
              label: 'Map Pin',
              value: storeLatitude != null && storeLongitude != null
                  ? 'Location pin selected'
                  : '',
            ),
            SupplierReviewRow(label: 'Market Area', value: primaryMarketAreaController.text),
            SupplierReviewRow(label: 'Description', value: storeDescriptionController.text),
            const SupplierReviewRow(label: 'Payment', value: 'Cash on Delivery (COD)'),
          ],
        ),
        SupplierReviewSection(
          title: 'Verification',
          icon: Icons.verified_user_outlined,
          onEdit: () => editStep(2),
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
              storagePath: permitStoragePath,
            ),
            SupplierReviewImage(
              title: 'Store Verification Photo',
              localImage: storeImage,
              imageUrl: storeImageUrl,
              storagePath: '',
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 13),
          padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
          decoration: BoxDecoration(
            color: confirmedAccuracy
                ? const Color(0xFFEAF8F3)
                : const Color(0xFFF5F9FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: confirmedAccuracy
                  ? const Color(0xFF8EDBC2)
                  : const Color(0xFFDCE7EF),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: confirmedAccuracy,
                activeColor: const Color(0xFF147D64),
                visualDensity: VisualDensity.compact,
                onChanged: (value) {
                  setState(() => confirmedAccuracy = value ?? false);
                },
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'I confirm that my contact, store, location, permit, and verification details are accurate.',
                  style: TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 9.7,
                    height: 1.36,
                    fontWeight: FontWeight.w700,
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
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
          SizedBox(
            height: 115,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/supplier_application_header_bg.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x42073B63), Color(0xD90869BA)],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(238),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x2800152A),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.mark_email_read_outlined, color: Color(0xFF146BFF), size: 38),
                        Positioned(
                          right: 9,
                          bottom: 10,
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Color(0xFF1DBB8A),
                            child: Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              children: [
                const Text(
                  'Application Under Review',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your supplier application has been received and is waiting for admin review. You can keep using your vendor account while you wait.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF657C8E),
                    fontSize: 10.2,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8ED),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0xFFFFD4A3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: Color(0xFFE57612), size: 21),
                      SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STATUS',
                              style: TextStyle(
                                color: Color(0xFFB95A10),
                                fontSize: 8.2,
                                letterSpacing: 0.55,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pending Admin Review',
                              style: TextStyle(
                                color: Color(0xFF7A5328),
                                fontSize: 10.8,
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
                  'Supplier tools unlock after approval. We’ll keep this application locked while it is under review so duplicate submissions are avoided.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 9.5,
                    height: 1.36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
      2 => verificationStep(),
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
              backgroundColor: const Color(0xFF087FCB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    final isReady = currentStepComplete;
    final isBusy = isLoadingProfile || isSubmitting || uploadsInProgress;

    return _BottomBar(
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: isSubmitting || uploadsInProgress
                    ? null
                    : previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF087FCB),
                  side: const BorderSide(color: Color(0xFF087FCB)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      currentStep == 0
                          ? Icons.close_rounded
                          : Icons.arrow_back_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        currentStep == 0 ? 'Cancel' : 'Back',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isBusy ? null : nextStep,
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
                      !isReady
                          ? Icons.info_outline_rounded
                          : isLastStep
                          ? Icons.send_rounded
                          : Icons.arrow_forward_rounded,
                      size: 19,
                    ),
              label: Text(
                isSubmitting
                    ? 'Submitting...'
                    : uploadsInProgress
                    ? 'Uploading Photos...'
                    : isLoadingProfile
                    ? 'Loading Application...'
                    : isReady
                    ? isLastStep
                          ? 'Submit Application'
                          : 'Continue'
                    : isLastStep && reviewDetailsComplete && !confirmedAccuracy
                    ? 'Confirm Above to Submit'
                    : 'Complete Required Details',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isReady
                    ? const Color(0xFF087FCB)
                    : const Color(0xFFE8F0F6),
                disabledBackgroundColor: const Color(0xFFDCE7EF),
                foregroundColor: isReady
                    ? Colors.white
                    : const Color(0xFF52677A),
                disabledForegroundColor: const Color(0xFF7B8FA3),
                minimumSize: const Size.fromHeight(52),
                elevation: isReady ? 5 : 0,
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
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SupplierActivationHeader(
                currentStep: currentStep,
                totalSteps: stepTitles.length,
                submitted: applicationSubmitted,
                onBack: closeScreen,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 34),
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
                    if (!applicationSubmitted &&
                        !isLoadingProfile &&
                        activeRejectionReason.trim().isNotEmpty)
                      _RejectedApplicationFeedbackCard(
                        reason: activeRejectionReason.trim(),
                        onViewFeedback: () => showRejectionFeedbackDialog(
                          activeRejectionReason,
                        ),
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
                    if (!applicationSubmitted &&
                        !isLoadingProfile &&
                        !currentStepComplete)
                      SupplierStepStatusCard(
                        complete: currentStepComplete,
                        missingItems: missingRequirements,
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isdalink/config/cloudinary_config.dart';
import 'package:isdalink/services/cloudinary_upload_service.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_header.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_unit_card.dart';
import 'package:isdalink/services/supplier_activation_service.dart';

class SupplierActivationScreen extends StatefulWidget {
  const SupplierActivationScreen({
    super.key,
  });

  @override
  State<SupplierActivationScreen> createState() =>
      _SupplierActivationScreenState();
}

class _SupplierActivationScreenState extends State<SupplierActivationScreen> {
  final ownerNameController = TextEditingController();
  final ownerAddressController = TextEditingController();
  final emailController = TextEditingController();
  final contactNumberController = TextEditingController();

  final businessNameController = TextEditingController();
  final storeLocationController = TextEditingController();
  final serviceAreaController = TextEditingController();
  final storeDescriptionController = TextEditingController();

  final businessPermitNumberController = TextEditingController();
  final businessPermitUrlController = TextEditingController();
  final storePhotoUrlController = TextEditingController();

  final SupplierActivationService activationService =
      const SupplierActivationService();
  final CloudinaryUploadService cloudinaryUploadService =
      const CloudinaryUploadService();
  final ImagePicker imagePicker = ImagePicker();

  bool kiloUnit = false;
  bool tabUnit = false;
  bool iceboxUnit = false;
  bool confirmedAccuracy = false;
  bool isSubmitting = false;
  bool isUploadingBusinessPermit = false;
  bool isUploadingStorePhoto = false;
  bool applicationSubmitted = false;

  int currentStep = 0;

  final List<String> stepTitles = const [
    'Owner',
    'Store',
    'Units',
    'Verify',
    'Review',
  ];

  int get enabledUnitCount {
    return [
      kiloUnit,
      tabUnit,
      iceboxUnit,
    ].where((enabled) => enabled).length;
  }

  List<String> get supportedUnits {
    final units = <String>[];

    if (kiloUnit) {
      units.add('kilo');
    }

    if (tabUnit) {
      units.add('tab');
    }

    if (iceboxUnit) {
      units.add('icebox');
    }

    return units;
  }

  bool get isLastStep {
    return currentStep == stepTitles.length - 1;
  }

  double get progressValue {
    if (applicationSubmitted) {
      return 1;
    }

    return (currentStep + 1) / stepTitles.length;
  }

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    emailController.text = user?.email ?? '';
    ownerNameController.text = user?.displayName ?? '';
  }

  @override
  void dispose() {
    ownerNameController.dispose();
    ownerAddressController.dispose();
    emailController.dispose();
    contactNumberController.dispose();

    businessNameController.dispose();
    storeLocationController.dispose();
    serviceAreaController.dispose();
    storeDescriptionController.dispose();

    businessPermitNumberController.dispose();
    businessPermitUrlController.dispose();
    storePhotoUrlController.dispose();

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

  bool isValidUrl(
    String value,
  ) {
    final uri = Uri.tryParse(value);

    if (uri == null) {
      return false;
    }

    return uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String compactText(
    String value,
  ) {
    return value
        .trim()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');
  }

  bool isValidPhilippineMobileNumber(
    String value,
  ) {
    final cleaned = compactText(value);

    return RegExp(r'^(09\d{9}|\+639\d{9})$').hasMatch(cleaned);
  }

  bool isValidPermitNumber(
    String value,
  ) {
    final cleaned = value.trim();

    if (cleaned.length < 6 || cleaned.length > 30) {
      return false;
    }

    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(cleaned)) {
      return false;
    }

    final digitsOnly = cleaned.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length >= 6) {
      if (RegExp(r'^(\d)\1+$').hasMatch(digitsOnly)) {
        return false;
      }

      if (digitsOnly.contains('123456') ||
          digitsOnly.contains('654321') ||
          digitsOnly.contains('000000')) {
        return false;
      }
    }

    return true;
  }

  bool validateOwnerStep() {
    final ownerName = ownerNameController.text.trim();
    final ownerAddress = ownerAddressController.text.trim();
    final email = emailController.text.trim();
    final contactNumber = contactNumberController.text.trim();

    if (ownerName.isEmpty ||
        ownerAddress.isEmpty ||
        email.isEmpty ||
        contactNumber.isEmpty) {
      showMessage(
        'Please complete all owner information fields.',
        isError: true,
      );
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      showMessage(
        'Please enter a valid email address.',
        isError: true,
      );
      return false;
    }

    if (!isValidPhilippineMobileNumber(contactNumber)) {
      showMessage(
        'Please enter a valid Philippine mobile number. Example: 09171234567 or +639171234567.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  bool validateStoreStep() {
    final businessName = businessNameController.text.trim();
    final storeLocation = storeLocationController.text.trim();
    final serviceArea = serviceAreaController.text.trim();
    final storeDescription = storeDescriptionController.text.trim();

    if (businessName.isEmpty ||
        storeLocation.isEmpty ||
        serviceArea.isEmpty ||
        storeDescription.isEmpty) {
      showMessage(
        'Please complete all store information fields.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  bool validateUnitStep() {
    if (supportedUnits.isEmpty) {
      showMessage(
        'Please select at least one supported selling unit.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  bool validateVerificationStep() {
    final businessPermitNumber = businessPermitNumberController.text.trim();
    final businessPermitUrl = businessPermitUrlController.text.trim();
    final storePhotoUrl = storePhotoUrlController.text.trim();

    if (businessPermitNumber.isEmpty) {
      showMessage(
        'Please enter the business permit number.',
        isError: true,
      );
      return false;
    }

    if (!isValidPermitNumber(businessPermitNumber)) {
      showMessage(
        'Please enter the correct business permit number shown in the permit photo.',
        isError: true,
      );
      return false;
    }

    if (businessPermitUrl.isEmpty) {
      showMessage(
        'Please upload a clear business permit photo.',
        isError: true,
      );
      return false;
    }

    if (storePhotoUrl.isEmpty) {
      showMessage(
        'Please upload a clear store photo.',
        isError: true,
      );
      return false;
    }

    if (!isValidUrl(businessPermitUrl)) {
      showMessage(
        'The business permit photo was not uploaded correctly. Please upload it again.',
        isError: true,
      );
      return false;
    }

    if (!isValidUrl(storePhotoUrl)) {
      showMessage(
        'The store photo was not uploaded correctly. Please upload it again.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  bool validateReviewStep() {
    final validOwner = validateOwnerStep();
    final validStore = validateStoreStep();
    final validUnits = validateUnitStep();
    final validVerification = validateVerificationStep();

    if (!validOwner || !validStore || !validUnits || !validVerification) {
      return false;
    }

    if (!confirmedAccuracy) {
      showMessage(
        'Please confirm that the submitted information is accurate.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  bool validateCurrentStep() {
    if (currentStep == 0) {
      return validateOwnerStep();
    }

    if (currentStep == 1) {
      return validateStoreStep();
    }

    if (currentStep == 2) {
      return validateUnitStep();
    }

    if (currentStep == 3) {
      return validateVerificationStep();
    }

    return validateReviewStep();
  }

  void goToNextStep() {
    if (applicationSubmitted) {
      return;
    }

    if (!validateCurrentStep()) {
      return;
    }

    if (isLastStep) {
      submitSupplierApplication();
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      currentStep += 1;
    });
  }

  void goToPreviousStep() {
    FocusScope.of(context).unfocus();

    if (applicationSubmitted || currentStep == 0) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      currentStep -= 1;
    });
  }

  SupplierApplicationInput? buildApplicationInput() {
    if (!validateReviewStep()) {
      return null;
    }

    return SupplierApplicationInput(
      ownerName: ownerNameController.text.trim(),
      ownerAddress: ownerAddressController.text.trim(),
      email: emailController.text.trim(),
      contactNumber: contactNumberController.text.trim(),
      businessName: businessNameController.text.trim(),
      storeLocation: storeLocationController.text.trim(),
      serviceArea: serviceAreaController.text.trim(),
      storeDescription: storeDescriptionController.text.trim(),
      supportedUnits: supportedUnits,
      businessPermitNumber: businessPermitNumberController.text.trim(),
      businessPermitUrl: businessPermitUrlController.text.trim(),
      storePhotoUrl: storePhotoUrlController.text.trim(),
    );
  }

  Future<void> submitSupplierApplication() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Please log in first before submitting a supplier application.',
        isError: true,
      );
      return;
    }

    if (applicationSubmitted) {
      showMessage(
        'Your supplier application has already been submitted.',
      );
      return;
    }

    final input = buildApplicationInput();

    if (input == null) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await activationService.submitSupplierApplication(
        user: user,
        input: input,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        applicationSubmitted = true;
        currentStep = stepTitles.length - 1;
      });

      showApplicationSubmittedDialog();
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Failed to submit supplier application: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  Future<void> pickAndUploadVerificationImage({
    required bool isBusinessPermit,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(
        'Please log in first before uploading a verification photo.',
        isError: true,
      );
      return;
    }

    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1600,
      );

      if (image == null) {
        return;
      }

      setState(() {
        if (isBusinessPermit) {
          isUploadingBusinessPermit = true;
        } else {
          isUploadingStorePhoto = true;
        }
      });

      final folder = isBusinessPermit
          ? '${CloudinaryConfig.supplierVerificationFolder}/permits/${user.uid}'
          : '${CloudinaryConfig.supplierVerificationFolder}/stores/${user.uid}';

      final imageUrl = await cloudinaryUploadService.uploadImage(
        image,
        folder: folder,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (isBusinessPermit) {
          businessPermitUrlController.text = imageUrl;
        } else {
          storePhotoUrlController.text = imageUrl;
        }
      });

      showMessage(
        isBusinessPermit
            ? 'Business permit photo uploaded.'
            : 'Store photo uploaded. This will become your supplier profile picture after approval.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Photo upload failed: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          if (isBusinessPermit) {
            isUploadingBusinessPermit = false;
          } else {
            isUploadingStorePhoto = false;
          }
        });
      }
    }
  }

  void showApplicationSubmittedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Application Submitted',
            style: TextStyle(
              color: Color(0xFF102C44),
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Your supplier application and verification photos have been submitted for admin review. '
            'You can now return to your profile while waiting for approval.',
            style: TextStyle(
              color: Color(0xFF52677A),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('View Status'),
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
              child: const Text('Back to Profile'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      helperMaxLines: 3,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: Color(0xFF6B7F93),
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.1,
      ),
      helperStyle: const TextStyle(
        color: Color(0xFF7B8FA3),
        fontSize: 10.4,
        height: 1.32,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 9, 10),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE6F9FF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF146BFF),
          size: 19,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 58,
        minHeight: 56,
      ),
      filled: true,
      fillColor: const Color(0xFFF6FAFD),
      contentPadding: const EdgeInsets.fromLTRB(14, 18, 15, 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: Color(0xFFE5EEF6),
          width: 1,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: Color(0xFFE5EEF6),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: Color(0xFF146BFF),
          width: 1.5,
        ),
      ),
    );
  }

  Widget stepProgressCard() {
    final stepIcons = <IconData>[
      Icons.person,
      Icons.storefront,
      Icons.inventory_2_outlined,
      Icons.verified_user_outlined,
      Icons.fact_check_outlined,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE4EDF5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF146BFF),
                      Color(0xFF10B7D4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification progress',
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      applicationSubmitted
                          ? 'Submitted for admin review'
                          : 'Step ${currentStep + 1} of ${stepTitles.length} • ${stepTitles[currentStep]} details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F8FF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  applicationSubmitted ? 'Pending' : stepTitles[currentStep],
                  style: const TextStyle(
                    color: Color(0xFF146BFF),
                    fontSize: 10.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFEAF0F5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF146BFF),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              stepTitles.length,
              (index) {
                final isActive = index == currentStep && !applicationSubmitted;
                final isDone = index < currentStep || applicationSubmitted;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (applicationSubmitted) {
                        return;
                      }

                      if (index <= currentStep) {
                        setState(() {
                          currentStep = index;
                        });
                      }
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: isActive ? 36 : 32,
                          height: isActive ? 36 : 32,
                          decoration: BoxDecoration(
                            color: isDone || isActive
                                ? const Color(0xFF146BFF)
                                : const Color(0xFFEAF0F5),
                            shape: BoxShape.circle,
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF146BFF).withAlpha(45),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : const [],
                          ),
                          child: Icon(
                            isDone ? Icons.check : stepIcons[index],
                            color: isDone || isActive
                                ? Colors.white
                                : const Color(0xFF9AADBC),
                            size: isActive ? 17 : 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stepTitles[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDone || isActive
                                ? const Color(0xFF146BFF)
                                : const Color(0xFF8CA0B3),
                            fontSize: 9.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget stepIntroCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD8ECF7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF146BFF),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 13.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF61778A),
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF7FF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF146BFF),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 15.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF7B8FA3),
                  fontSize: 10.6,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8EE),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'Required',
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5EEF6),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          sectionTitle(
            icon: icon,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget verticalGap() {
    return const SizedBox(height: 14);
  }

  Widget verificationPhotoUploadCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required IconData icon,
    required bool isUploading,
    required bool isBusinessPermit,
  }) {
    final hasImage = imageUrl.trim().startsWith('http://') ||
        imageUrl.trim().startsWith('https://');

    return GestureDetector(
      onTap: isUploading
          ? null
          : () => pickAndUploadVerificationImage(
                isBusinessPermit: isBusinessPermit,
              ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: hasImage ? const Color(0xFFF4FCF6) : const Color(0xFFFAFCFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasImage
                ? const Color(0xFF2E7D32).withAlpha(45)
                : const Color(0xFFDDECF5),
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasImage
                          ? const Color(0xFF2E7D32).withAlpha(36)
                          : const Color(0xFFDDECF5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: hasImage
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                icon,
                                color: const Color(0xFF146BFF),
                                size: 28,
                              );
                            },
                          )
                        : Icon(
                            icon,
                            color: const Color(0xFF146BFF),
                            size: 28,
                          ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: hasImage
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF146BFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      hasImage ? Icons.check : Icons.add_a_photo,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF102C44),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasImage
                              ? const Color(0xFFEAF8EE)
                              : const Color(0xFFF0F6FF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          isUploading
                              ? 'Uploading'
                              : hasImage
                                  ? 'Ready'
                                  : 'Upload',
                          style: TextStyle(
                            color: hasImage
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF146BFF),
                            fontSize: 9.6,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF607486),
                      fontSize: 10.8,
                      height: 1.32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isUploading
                            ? Icons.autorenew_rounded
                            : hasImage
                                ? Icons.check_circle
                                : Icons.file_upload_outlined,
                        color: hasImage
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF146BFF),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isUploading
                            ? 'Uploading photo...'
                            : hasImage
                                ? 'Tap to change photo'
                                : 'Tap to upload',
                        style: TextStyle(
                          color: hasImage
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF146BFF),
                          fontSize: 10.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9AADBC),
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget requirementNoticeCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(42),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withAlpha(30),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF5E7386),
                    fontSize: 10.6,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget ownerInformationStep() {
    return Column(
      children: [
        stepIntroCard(
          icon: Icons.verified_user_outlined,
          title: 'Account verification',
          message:
              'Use the real owner name and a valid Philippine mobile number. These details will be checked during admin review.',
        ),
        sectionCard(
          icon: Icons.badge,
          title: 'Owner Information',
          subtitle: 'Identity and contact details for verification.',
          children: [
            TextField(
              controller: ownerNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Owner Full Name',
                icon: Icons.person,
                helperText: 'Use the real name of the account owner.',
              ),
            ),
            verticalGap(),
            TextField(
              controller: ownerAddressController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Owner Address',
                icon: Icons.home,
                helperText: 'Enter your complete address for verification.',
              ),
            ),
            verticalGap(),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Email Address',
                icon: Icons.email,
              ),
            ),
            verticalGap(),
            TextField(
              controller: contactNumberController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9+]'),
                ),
                LengthLimitingTextInputFormatter(13),
              ],
              decoration: inputDecoration(
                label: 'Philippine Mobile Number',
                icon: Icons.phone_iphone,
                helperText:
                    'Required format: 09XXXXXXXXX or +639XXXXXXXXX.',
              ),
            ),
            const SizedBox(height: 14),
            requirementNoticeCard(
              icon: Icons.verified_outlined,
              title: 'Contact number validation',
              message:
                  'Random or incomplete numbers are not accepted. Use an active Philippine mobile number so admin can verify the supplier account.',
              color: const Color(0xFF146BFF),
            ),
          ],
        ),
      ],
    );
  }

  Widget storeInformationStep() {
    return Column(
      children: [
        stepIntroCard(
          icon: Icons.storefront,
          title: 'Store profile',
          message:
              'Add clear store details that vendors will see after the supplier account is approved.',
        ),
        sectionCard(
          icon: Icons.storefront,
          title: 'Store Information',
          subtitle: 'Business name, address, service area, and description.',
          children: [
            TextField(
              controller: businessNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Business / Store Name',
                icon: Icons.store,
                helperText: 'This name will be shown to vendors.',
              ),
            ),
            verticalGap(),
            TextField(
              controller: storeLocationController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Store Address',
                icon: Icons.place_outlined,
                helperText: 'Enter the actual store or selling location.',
              ),
            ),
            verticalGap(),
            TextField(
              controller: serviceAreaController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Service Area',
                icon: Icons.travel_explore,
                helperText:
                    'Example: Bayugan City, Agusan del Sur, or Caraga Region.',
              ),
            ),
            verticalGap(),
            TextField(
              controller: storeDescriptionController,
              minLines: 4,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              decoration: inputDecoration(
                label: 'Store Description',
                icon: Icons.description,
                helperText:
                    'Describe the fish source, selling setup, and regular available stocks.',
              ),
            ),
            const SizedBox(height: 14),
            requirementNoticeCard(
              icon: Icons.store_mall_directory_outlined,
              title: 'Vendor-facing profile',
              message:
                  'After approval, these details help vendors identify your store and available supply coverage.',
              color: const Color(0xFF10B7D4),
            ),
          ],
        ),
      ],
    );
  }

  Widget unitStep() {
    return Column(
      children: [
        stepIntroCard(
          icon: Icons.scale,
          title: 'Supported selling units',
          message:
              'Select the units this supplier can actually support for fish stock posting and COD ordering.',
        ),
        SupplierActivationUnitCard(
          kiloUnit: kiloUnit,
          tabUnit: tabUnit,
          iceboxUnit: iceboxUnit,
          onKiloChanged: (value) {
            setState(() {
              kiloUnit = value;
            });
          },
          onTabChanged: (value) {
            setState(() {
              tabUnit = value;
            });
          },
          onIceboxChanged: (value) {
            setState(() {
              iceboxUnit = value;
            });
          },
        ),
      ],
    );
  }

  Widget verificationStep() {
    return Column(
      children: [
        stepIntroCard(
          icon: Icons.policy,
          title: 'Supplier verification',
          message:
              'Upload readable proof of business operation. Admin will compare the permit number with the uploaded permit photo.',
        ),
        sectionCard(
          icon: Icons.verified_user,
          title: 'Verification Requirements',
          subtitle: 'Permit number, permit photo, and store photo.',
          children: [
            requirementNoticeCard(
              icon: Icons.warning_amber_rounded,
              title: 'Permit number must match',
              message:
                  'Make sure the Business Permit Number entered below is the same number shown in the uploaded permit photo. If it does not match, the application may be denied during admin review.',
              color: const Color(0xFFFF7A1A),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: businessPermitNumberController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-z0-9-]'),
                ),
                LengthLimitingTextInputFormatter(30),
              ],
              decoration: inputDecoration(
                label: 'Business Permit Number',
                icon: Icons.confirmation_number,
                helperText:
                    'Enter the exact permit number printed on the uploaded permit photo.',
              ),
            ),
            verticalGap(),
            verificationPhotoUploadCard(
              title: 'Business Permit Photo',
              subtitle:
                  'Upload a clear photo where the permit number and business name are readable.',
              imageUrl: businessPermitUrlController.text,
              icon: Icons.badge_outlined,
              isUploading: isUploadingBusinessPermit,
              isBusinessPermit: true,
            ),
            verticalGap(),
            verificationPhotoUploadCard(
              title: 'Store Photo',
              subtitle:
                  'Upload a clear store photo. After approval, this will automatically become your supplier profile picture.',
              imageUrl: storePhotoUrlController.text,
              icon: Icons.storefront,
              isUploading: isUploadingStorePhoto,
              isBusinessPermit: false,
            ),
            const SizedBox(height: 14),
            requirementNoticeCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Photo quality reminder',
              message:
                  'Use bright and readable photos. Blurry, cropped, mismatched, or incomplete verification photos may be rejected by admin.',
              color: const Color(0xFF146BFF),
            ),
          ],
        ),
      ],
    );
  }

  Widget reviewStep() {
    return Column(
      children: [
        stepIntroCard(
          icon: Icons.fact_check,
          title: 'Final review',
          message:
              'Review all details before submitting. The permit number must match the uploaded permit photo for approval.',
        ),
        sectionCard(
          icon: Icons.summarize,
          title: 'Application Summary',
          subtitle: 'Final details for admin review.',
          children: [
            SummaryRow(
              label: 'Owner',
              value: ownerNameController.text.trim(),
            ),
            SummaryRow(
              label: 'Contact',
              value: contactNumberController.text.trim(),
            ),
            SummaryRow(
              label: 'Store',
              value: businessNameController.text.trim(),
            ),
            SummaryRow(
              label: 'Location',
              value: storeLocationController.text.trim(),
            ),
            SummaryRow(
              label: 'Service Area',
              value: serviceAreaController.text.trim(),
            ),
            SummaryRow(
              label: 'Units',
              value: supportedUnits.join(', '),
            ),
            SummaryRow(
              label: 'Permit No.',
              value: businessPermitNumberController.text.trim(),
            ),
            SummaryImageRow(
              label: 'Permit Photo',
              imageUrl: businessPermitUrlController.text.trim(),
              icon: Icons.badge_outlined,
            ),
            SummaryImageRow(
              label: 'Store Photo',
              imageUrl: storePhotoUrlController.text.trim(),
              icon: Icons.storefront,
              note:
                  'This photo will become your supplier profile picture after approval.',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: confirmedAccuracy,
                    activeColor: const Color(0xFF146BFF),
                    onChanged: applicationSubmitted
                        ? null
                        : (value) {
                            setState(() {
                              confirmedAccuracy = value ?? false;
                            });
                          },
                  ),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'I confirm that the permit number, contact number, store details, and verification photos are accurate and valid.',
                        style: TextStyle(
                          color: Color(0xFF52677A),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget submittedStep() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7FB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top,
                  color: Color(0xFF146BFF),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Application Pending Review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your supplier application was submitted successfully. Admin must verify your owner details, store information, business permit photo, and store photo before supplier tools are unlocked.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF52677A),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFFB703).withAlpha(70),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFFF7A1A),
                      size: 20,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'You cannot submit another application while this one is pending.',
                        style: TextStyle(
                          color: Color(0xFF52677A),
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget currentStepBody() {
    if (applicationSubmitted) {
      return submittedStep();
    }

    if (currentStep == 0) {
      return ownerInformationStep();
    }

    if (currentStep == 1) {
      return storeInformationStep();
    }

    if (currentStep == 2) {
      return unitStep();
    }

    if (currentStep == 3) {
      return verificationStep();
    }

    return reviewStep();
  }

  Widget bottomNavigation() {
    if (applicationSubmitted) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 16,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                'Back to Profile',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF146BFF),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF146BFF).withAlpha(60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 16,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSubmitting ? null : goToPreviousStep,
                icon: Icon(
                  currentStep == 0 ? Icons.close : Icons.arrow_back,
                ),
                label: Text(
                  currentStep == 0 ? 'Cancel' : 'Back',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF146BFF),
                  side: const BorderSide(
                    color: Color(0xFF146BFF),
                    width: 1.3,
                  ),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : goToNextStep,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isLastStep ? Icons.send : Icons.arrow_forward,
                      ),
                label: Text(
                  isSubmitting
                      ? 'Submitting...'
                      : isLastStep
                          ? 'Submit Application'
                          : 'Continue',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF146BFF),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF146BFF).withAlpha(60),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Column(
        children: [
          SupplierActivationHeader(
            enabledUnitCount: enabledUnitCount,
            onBack: () => Navigator.pop(context),
          ),
          stepProgressCard(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: ListView(
                key: ValueKey<String>(
                  applicationSubmitted
                      ? 'submitted'
                      : 'step-$currentStep',
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  currentStepBody(),
                ],
              ),
            ),
          ),
          bottomNavigation(),
        ],
      ),
    );
  }
}

class SummaryImageRow extends StatelessWidget {
  const SummaryImageRow({
    super.key,
    required this.label,
    required this.imageUrl,
    required this.icon,
    this.note,
  });

  final String label;
  final String imageUrl;
  final IconData icon;
  final String? note;

  bool get hasImage {
    return imageUrl.trim().startsWith('http://') ||
        imageUrl.trim().startsWith('https://');
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE1EEF6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFDDECF5),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          icon,
                          color: const Color(0xFF146BFF),
                          size: 26,
                        );
                      },
                    )
                  : Icon(
                      icon,
                      color: const Color(0xFF146BFF),
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF102C44),
                    fontSize: 12.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note ?? (hasImage ? 'Uploaded for admin review.' : 'Not uploaded'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 10.4,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: hasImage
                  ? const Color(0xFFEAF8EE)
                  : const Color(0xFFFFEEF0),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              hasImage ? 'Ready' : 'Missing',
              style: TextStyle(
                color: hasImage
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFD32F2F),
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(
    BuildContext context,
  ) {
    final displayValue = value.trim().isEmpty ? 'Not provided' : value.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7B8FA3),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 11.7,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
  
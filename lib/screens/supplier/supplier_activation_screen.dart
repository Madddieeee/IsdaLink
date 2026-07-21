import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

  bool kiloUnit = false;
  bool tabUnit = false;
  bool iceboxUnit = false;
  bool confirmedAccuracy = false;
  bool isSubmitting = false;
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

    if (contactNumber.length < 7) {
      showMessage(
        'Please enter a valid contact number.',
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

    if (businessPermitNumber.isEmpty ||
        businessPermitUrl.isEmpty ||
        storePhotoUrl.isEmpty) {
      showMessage(
        'Please complete all verification requirements.',
        isError: true,
      );
      return false;
    }

    if (!isValidUrl(businessPermitUrl)) {
      showMessage(
        'Please enter a valid business permit link starting with http or https.',
        isError: true,
      );
      return false;
    }

    if (!isValidUrl(storePhotoUrl)) {
      showMessage(
        'Please enter a valid store photo link starting with http or https.',
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
            'Your supplier application has been submitted for admin verification. '
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
      helperMaxLines: 2,
      labelStyle: const TextStyle(
        color: Color(0xFF7B8FA3),
        fontSize: 13,
      ),
      helperStyle: const TextStyle(
        color: Color(0xFF7B8FA3),
        fontSize: 11,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF146BFF),
      ),
      filled: true,
      fillColor: const Color(0xFFF4F8FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF146BFF),
          width: 1.3,
        ),
      ),
    );
  }

  Widget stepProgressCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                applicationSubmitted
                    ? 'Submitted'
                    : 'Step ${currentStep + 1} of ${stepTitles.length}',
                style: const TextStyle(
                  color: Color(0xFF102C44),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                applicationSubmitted ? 'Pending Review' : stepTitles[currentStep],
                style: const TextStyle(
                  color: Color(0xFF146BFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
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
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isActive || isDone
                                ? const Color(0xFF146BFF)
                                : const Color(0xFFEAF0F5),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFF7B8FA3),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          stepTitles[index],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive || isDone
                                ? const Color(0xFF146BFF)
                                : const Color(0xFF7B8FA3),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF146BFF).withAlpha(34),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF146BFF),
            size: 22,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 11.5,
                    height: 1.4,
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
            color: const Color(0xFFEAF7FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF146BFF),
            size: 22,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7B8FA3),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
          sectionTitle(
            icon: icon,
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget verticalGap() {
    return const SizedBox(height: 12);
  }

  Widget ownerInformationStep() {
    return Column(
      children: [
        stepIntroCard(
          icon: Icons.verified_user_outlined,
          title: 'Account verification',
          message:
              'Provide the real owner information that admin will use to verify this supplier application.',
        ),
        sectionCard(
          icon: Icons.badge,
          title: 'Owner Information',
          subtitle: 'Required identity and contact details.',
          children: [
            TextField(
              controller: ownerNameController,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Owner Full Name',
                icon: Icons.person,
              ),
            ),
            verticalGap(),
            TextField(
              controller: ownerAddressController,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Owner Address',
                icon: Icons.home,
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
              decoration: inputDecoration(
                label: 'Contact Number',
                icon: Icons.phone,
              ),
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
              'These details will be shown to vendors after the supplier account is approved.',
        ),
        sectionCard(
          icon: Icons.storefront,
          title: 'Store Information',
          subtitle: 'Business, location, and service area.',
          children: [
            TextField(
              controller: businessNameController,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Business / Store Name',
                icon: Icons.store,
              ),
            ),
            verticalGap(),
            TextField(
              controller: storeLocationController,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Store Location',
                icon: Icons.location_on,
              ),
            ),
            verticalGap(),
            TextField(
              controller: serviceAreaController,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Service Area',
                icon: Icons.map,
                helperText:
                    'Example: Bayugan City, Agusan del Sur, or Caraga Region',
              ),
            ),
            verticalGap(),
            TextField(
              controller: storeDescriptionController,
              minLines: 3,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: inputDecoration(
                label: 'Store Description',
                icon: Icons.description,
                helperText:
                    'Describe the store, fish supply source, and selling setup.',
              ),
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
              'Submit valid proof of business operation. Admin will review these links before granting supplier access.',
        ),
        sectionCard(
          icon: Icons.verified_user,
          title: 'Verification Requirements',
          subtitle: 'Permit and store proof for admin approval.',
          children: [
            TextField(
              controller: businessPermitNumberController,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Business Permit Number',
                icon: Icons.confirmation_number,
              ),
            ),
            verticalGap(),
            TextField(
              controller: businessPermitUrlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: inputDecoration(
                label: 'Business Permit Link',
                icon: Icons.link,
                helperText:
                    'Paste a Google Drive or image link. Set sharing to anyone with the link.',
              ),
            ),
            verticalGap(),
            TextField(
              controller: storePhotoUrlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: inputDecoration(
                label: 'Store Photo Link',
                icon: Icons.photo,
                helperText:
                    'This photo will be used as the supplier profile image after approval.',
              ),
            ),
            const SizedBox(height: 14),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Color(0xFFFF7A1A),
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Use clear and accessible links. Incomplete or inaccessible verification links may be rejected by admin.',
                      style: TextStyle(
                        color: Color(0xFF52677A),
                        fontSize: 11,
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
      ],
    );
  }

  Widget reviewStep() {
    return Column(
      children: [
        stepIntroCard(
          icon: Icons.fact_check,
          title: 'Review before submitting',
          message:
              'Check the application details carefully. After submission, admin approval is required before supplier tools are unlocked.',
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
            SummaryRow(
              label: 'Permit Link',
              value: businessPermitUrlController.text.trim(),
            ),
            SummaryRow(
              label: 'Store Photo',
              value: storePhotoUrlController.text.trim(),
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
                        'I confirm that the information and verification links submitted are accurate and valid.',
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
                'Your supplier application was submitted successfully. Admin must verify your owner, store, permit, and store photo details before supplier tools are unlocked.',
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
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 14,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 52,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, -4),
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
                  ),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF146BFF),
                  disabledBackgroundColor: const Color(0xFF7B8FA3),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
      backgroundColor: const Color(0xFFF4F8FB),
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
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
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
                fontSize: 12,
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

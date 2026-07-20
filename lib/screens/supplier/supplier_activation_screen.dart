import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_feature_card.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_header.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_submit_button.dart';
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
  bool isSubmitting = false;

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

  SupplierApplicationInput? buildApplicationInput() {
    final ownerName = ownerNameController.text.trim();
    final ownerAddress = ownerAddressController.text.trim();
    final email = emailController.text.trim();
    final contactNumber = contactNumberController.text.trim();

    final businessName = businessNameController.text.trim();
    final storeLocation = storeLocationController.text.trim();
    final serviceArea = serviceAreaController.text.trim();
    final storeDescription = storeDescriptionController.text.trim();

    final businessPermitNumber = businessPermitNumberController.text.trim();
    final businessPermitUrl = businessPermitUrlController.text.trim();
    final storePhotoUrl = storePhotoUrlController.text.trim();

    if (ownerName.isEmpty ||
        ownerAddress.isEmpty ||
        email.isEmpty ||
        contactNumber.isEmpty ||
        businessName.isEmpty ||
        storeLocation.isEmpty ||
        serviceArea.isEmpty ||
        storeDescription.isEmpty ||
        businessPermitNumber.isEmpty ||
        businessPermitUrl.isEmpty ||
        storePhotoUrl.isEmpty) {
      showMessage(
        'Please complete all supplier application requirements.',
        isError: true,
      );
      return null;
    }

    if (!email.contains('@') || !email.contains('.')) {
      showMessage(
        'Please enter a valid email address.',
        isError: true,
      );
      return null;
    }

    if (contactNumber.length < 7) {
      showMessage(
        'Please enter a valid contact number.',
        isError: true,
      );
      return null;
    }

    if (supportedUnits.isEmpty) {
      showMessage(
        'Please select at least one supported selling unit.',
        isError: true,
      );
      return null;
    }

    if (!isValidUrl(businessPermitUrl)) {
      showMessage(
        'Please enter a valid business permit link starting with http or https.',
        isError: true,
      );
      return null;
    }

    if (!isValidUrl(storePhotoUrl)) {
      showMessage(
        'Please enter a valid store photo link starting with http or https.',
        isError: true,
      );
      return null;
    }

    return SupplierApplicationInput(
      ownerName: ownerName,
      ownerAddress: ownerAddress,
      email: email,
      contactNumber: contactNumber,
      businessName: businessName,
      storeLocation: storeLocation,
      serviceArea: serviceArea,
      storeDescription: storeDescription,
      supportedUnits: supportedUnits,
      businessPermitNumber: businessPermitNumber,
      businessPermitUrl: businessPermitUrl,
      storePhotoUrl: storePhotoUrl,
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
            'Your verified supplier application has been submitted for admin review. '
            'Supplier features will become available only after your permit and store information are approved.',
            style: TextStyle(
              color: Color(0xFF52677A),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Stay Here'),
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
          Row(
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

  Widget ownerInformationCard() {
    return sectionCard(
      icon: Icons.badge,
      title: 'Owner Information',
      subtitle: 'Required identity and contact details for admin review.',
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
          textInputAction: TextInputAction.next,
          decoration: inputDecoration(
            label: 'Contact Number',
            icon: Icons.phone,
          ),
        ),
      ],
    );
  }

  Widget storeInformationCard() {
    return sectionCard(
      icon: Icons.storefront,
      title: 'Store Information',
      subtitle: 'Store details shown to vendors after approval.',
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
            helperText: 'Example: Bayugan City, Agusan del Sur, or Caraga Region',
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
            helperText: 'Describe the store, fish supply source, and selling setup.',
          ),
        ),
      ],
    );
  }

  Widget verificationRequirementsCard() {
    return sectionCard(
      icon: Icons.verified_user,
      title: 'Verification Requirements',
      subtitle: 'Required proof before admin can approve supplier access.',
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
            helperText: 'Paste a Google Drive or image link. Set sharing to anyone with the link.',
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
            helperText: 'This link is also saved as the supplier profile image.',
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7FB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF146BFF).withAlpha(40),
            ),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Color(0xFF146BFF),
                size: 20,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'No Firebase Storage billing needed: this version saves permit and store photo links in Firestore for admin verification.',
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
              children: [
                ownerInformationCard(),
                storeInformationCard(),
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
                verificationRequirementsCard(),
                const SupplierActivationFeatureCard(),
              ],
            ),
          ),
          SupplierActivationSubmitButton(
            isSubmitting: isSubmitting,
            onPressed: submitSupplierApplication,
          ),
        ],
      ),
    );
  }
}

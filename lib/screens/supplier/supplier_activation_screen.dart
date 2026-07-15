import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_feature_card.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_header.dart';
import 'package:isdalink/screens/supplier/activation/widgets/supplier_activation_info_card.dart';
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
  final businessNameController = TextEditingController();
  final marketLocationController = TextEditingController();
  final contactNumberController = TextEditingController();

  final SupplierActivationService activationService =
      const SupplierActivationService();

  String selectedSupplierType = 'Fish Supplier';
  bool kiloUnit = true;
  bool tabUnit = true;
  bool iceboxUnit = true;
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
    businessNameController.text = 'Juan Fresh Fish Supply';
    marketLocationController.text = 'Caraga Region';
    contactNumberController.text = '09XXXXXXXXX';
  }

  @override
  void dispose() {
    businessNameController.dispose();
    marketLocationController.dispose();
    contactNumberController.dispose();
    super.dispose();
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFD32F2F)
            : const Color(0xFF2E7D32),
      ),
    );
  }

  SupplierApplicationInput? buildApplicationInput() {
    final businessName = businessNameController.text.trim();
    final marketLocation = marketLocationController.text.trim();
    final contactNumber = contactNumberController.text.trim();

    if (businessName.isEmpty ||
        marketLocation.isEmpty ||
        contactNumber.isEmpty) {
      showMessage(
        'Please complete all supplier application fields.',
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

    return SupplierApplicationInput(
      businessName: businessName,
      marketLocation: marketLocation,
      contactNumber: contactNumber,
      supplierType: selectedSupplierType,
      supportedUnits: supportedUnits,
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

      if (!mounted) return;

      showApplicationSubmittedDialog();
    } catch (error) {
      if (!mounted) return;

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
            'Your supplier application has been submitted for admin review. '
            'Supplier features will become available after your application is approved.',
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
                SupplierActivationInfoCard(
                  businessNameController: businessNameController,
                  marketLocationController: marketLocationController,
                  contactNumberController: contactNumberController,
                  selectedSupplierType: selectedSupplierType,
                  onSupplierTypeChanged: (value) {
                    setState(() {
                      selectedSupplierType = value;
                    });
                  },
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

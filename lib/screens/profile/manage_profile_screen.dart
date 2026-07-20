import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManageProfileScreen extends StatefulWidget {
  const ManageProfileScreen({
    super.key,
  });

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

class _ManageProfileScreenState extends State<ManageProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final regionController = TextEditingController();
  final locationController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  String role = 'vendor';
  String supplierStatus = 'not_applicable';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    regionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  String getStringValue(
    Map<String, dynamic>? data,
    String key,
    String fallback,
  ) {
    if (data == null) {
      return fallback;
    }

    final value = data[key];

    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  Future<void> loadProfile() async {
    final user = currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDocument.data();

      role = getStringValue(
        data,
        'role',
        'vendor',
      ).toLowerCase();

      supplierStatus = getStringValue(
        data,
        'supplierStatus',
        'not_applicable',
      ).toLowerCase();

      nameController.text = getStringValue(
        data,
        'name',
        user.displayName ?? 'IsdaLink User',
      );

      phoneController.text = getStringValue(
        data,
        'phone',
        '',
      );

      regionController.text = getStringValue(
        data,
        'region',
        'Caraga Region',
      );

      locationController.text = getStringValue(
        data,
        'location',
        getStringValue(
          data,
          'marketLocation',
          'Caraga Region',
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Failed to load profile: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  bool validateProfile() {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final region = regionController.text.trim();
    final location = locationController.text.trim();

    if (name.isEmpty || phone.isEmpty || region.isEmpty || location.isEmpty) {
      showMessage(
        'Please complete all profile fields.',
        isError: true,
      );
      return false;
    }

    if (phone.length < 7) {
      showMessage(
        'Please enter a valid contact number.',
        isError: true,
      );
      return false;
    }

    return true;
  }

  Future<void> saveProfile() async {
    final user = currentUser;

    if (user == null) {
      showMessage(
        'Please log in first before updating your profile.',
        isError: true,
      );
      return;
    }

    if (!validateProfile()) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final region = regionController.text.trim();
    final location = locationController.text.trim();

    try {
      await user.updateDisplayName(name);

      final userReference = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final batch = FirebaseFirestore.instance.batch();

      batch.set(
        userReference,
        {
          'name': name,
          'phone': phone,
          'region': region,
          'location': location,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (role == 'supplier' ||
          supplierStatus == 'approved' ||
          supplierStatus == 'pending') {
        final supplierReference = FirebaseFirestore.instance
            .collection('supplierProfiles')
            .doc(user.uid);

        batch.set(
          supplierReference,
          {
            'ownerName': name,
            'phone': phone,
            'contactNumber': phone,
            'location': location,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) {
        return;
      }

      showMessage(
        'Profile updated successfully.',
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      showMessage(
        'Failed to update profile: $error',
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

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF7B8FA3),
        fontSize: 13,
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
          width: 1.4,
        ),
      ),
    );
  }

  Widget header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF102C44),
            Color(0xFF146BFF),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Account Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Update your profile, contact number, and market location used by IsdaLink.',
            style: TextStyle(
              color: Color(0xFFDCE9F5),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(34),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withAlpha(34),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    role == 'supplier' || supplierStatus == 'approved'
                        ? 'Supplier-enabled account'
                        : 'Vendor account',
                    style: const TextStyle(
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
    );
  }

  Widget formCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            decoration: inputDecoration(
              label: 'Full Name',
              icon: Icons.person,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: inputDecoration(
              label: 'Contact Number',
              icon: Icons.phone,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: regionController,
            textInputAction: TextInputAction.next,
            decoration: inputDecoration(
              label: 'Region',
              icon: Icons.map,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locationController,
            textInputAction: TextInputAction.done,
            decoration: inputDecoration(
              label: 'Market Location / Service Area',
              icon: Icons.location_on,
            ),
          ),
        ],
      ),
    );
  }

  Widget infoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF146BFF).withAlpha(42),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_done,
            color: Color(0xFF146BFF),
            size: 22,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Firebase mode: Profile changes are saved to your user record. Supplier-enabled accounts also update their supplier profile contact and location.',
              style: TextStyle(
                color: Color(0xFF52677A),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget saveButton() {
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
            onPressed: isSaving ? null : saveProfile,
            icon: isSaving
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              isSaving ? 'Saving Profile...' : 'Save Profile',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF146BFF),
              disabledBackgroundColor: const Color(0xFF7B8FA3),
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

  Widget loadingBody() {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F8FB),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget loggedOutBody() {
    return const Scaffold(
      backgroundColor: Color(0xFFF4F8FB),
      body: Center(
        child: Text(
          'Please log in first to manage your profile.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFD32F2F),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (currentUser == null) {
      return loggedOutBody();
    }

    if (isLoading) {
      return loadingBody();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Column(
        children: [
          header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
              children: [
                formCard(),
                infoCard(),
              ],
            ),
          ),
          saveButton(),
        ],
      ),
    );
  }
}

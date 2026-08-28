import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/utils/app_error_message.dart';

class ManageProfileScreen extends StatefulWidget {
  const ManageProfileScreen({
    super.key,
  });

  @override
  State<ManageProfileScreen> createState() => _ManageProfileScreenState();
}

class _ManageProfileScreenState extends State<ManageProfileScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final nameFocusNode = FocusNode();
  final phoneFocusNode = FocusNode();

  bool isLoading = true;
  bool isSaving = false;
  bool submitted = false;

  String role = 'vendor';
  String supplierStatus = 'not_applicable';
  String initialName = '';
  String initialPhone = '';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get isSupplierEnabled {
    return role == 'supplier' || supplierStatus == 'approved';
  }

  bool get hasChanges {
    return collapseSpaces(nameController.text) != initialName ||
        normalizePhilippinePhone(phoneController.text) != initialPhone;
  }

  String get accountLabel {
    if (isSupplierEnabled) {
      return 'Supplier-enabled account';
    }

    if (supplierStatus == 'pending') {
      return 'Supplier application pending';
    }

    return 'Vendor account';
  }

  String get accountDescription {
    if (isSupplierEnabled) {
      return 'Vendor and approved supplier access are active.';
    }

    if (supplierStatus == 'pending') {
      return 'Vendor access is active while supplier approval is pending.';
    }

    return 'Vendor purchasing features are active.';
  }

  String get supplierStatusLabel {
    if (isSupplierEnabled) {
      return 'Approved supplier';
    }

    if (supplierStatus == 'pending') {
      return 'Application pending';
    }

    return 'Not activated';
  }

  String get profileInitials {
    final name = collapseSpaces(nameController.text);

    if (name.isEmpty) {
      return 'I';
    }

    final parts = name
        .split(' ')
        .where(
          (part) => part.trim().isNotEmpty,
        )
        .toList();

    if (parts.length == 1) {
      final value = parts.first;

      return value.substring(
        0,
        value.length >= 2 ? 2 : 1,
      ).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get syncStatusLabel {
    if (isSaving) {
      return 'SAVING';
    }

    return hasChanges ? 'UNSAVED' : 'SYNCED';
  }

  @override
  void initState() {
    super.initState();

    nameController.addListener(handleFieldChanged);
    phoneController.addListener(handleFieldChanged);

    loadProfile();
  }

  @override
  void dispose() {
    nameController.removeListener(handleFieldChanged);
    phoneController.removeListener(handleFieldChanged);

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    nameFocusNode.dispose();
    phoneFocusNode.dispose();

    super.dispose();
  }

  void handleFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String getStringValue(
    Map<String, dynamic>? data,
    String key,
    String fallback,
  ) {
    final value = data?[key];
    final text = value?.toString().trim() ?? '';

    return text.isEmpty ? fallback : text;
  }

  String collapseSpaces(
    String value,
  ) {
    return value.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }

  String phoneDigits(
    String value,
  ) {
    return value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }

  String normalizePhilippinePhone(
    String value,
  ) {
    final digits = phoneDigits(value);

    if (digits.startsWith('09') && digits.length == 11) {
      return '+63${digits.substring(1)}';
    }

    if (digits.startsWith('9') && digits.length == 10) {
      return '+63$digits';
    }

    if (digits.startsWith('639') && digits.length == 12) {
      return '+$digits';
    }

    return value.trim();
  }

  String? validateName(
    String? value,
  ) {
    final name = collapseSpaces(value ?? '');

    if (name.isEmpty) {
      return 'Enter your full name.';
    }

    if (name.length < 2) {
      return 'Enter at least 2 characters.';
    }

    final namePattern = RegExp(
      r"^[A-Za-zÀ-ÖØ-öø-ÿÑñ.' -]+$",
    );

    if (!namePattern.hasMatch(name)) {
      return 'Use letters, spaces, hyphens, or apostrophes only.';
    }

    return null;
  }

  String? validatePhone(
    String? value,
  ) {
    final input = (value ?? '').trim();

    if (input.isEmpty) {
      return 'Enter your contact number.';
    }

    final digits = phoneDigits(input);

    final isLocal =
        digits.startsWith('09') && digits.length == 11;
    final isShortLocal =
        digits.startsWith('9') && digits.length == 10;
    final isInternational =
        digits.startsWith('639') && digits.length == 12;

    if (!isLocal && !isShortLocal && !isInternational) {
      return 'Use 09XXXXXXXXX or +639XXXXXXXXX.';
    }

    return null;
  }

  Future<void> loadProfile() async {
    final user = currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snapshot.data();

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

      final loadedName = collapseSpaces(
        getStringValue(
          data,
          'name',
          user.displayName ?? 'IsdaLink User',
        ),
      );

      final loadedPhone = normalizePhilippinePhone(
        getStringValue(
          data,
          'phone',
          '',
        ),
      );

      nameController.text = loadedName;
      emailController.text = getStringValue(
        data,
        'email',
        user.email ?? 'No email available',
      );
      phoneController.text = loadedPhone;

      initialName = loadedName;
      initialPhone = loadedPhone;
    } catch (_) {
      showMessage(
        'Unable to load your account information.',
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

  Future<void> saveProfile() async {
    final user = currentUser;

    if (user == null || isSaving || !hasChanges) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      submitted = true;
    });

    final isValid = formKey.currentState?.validate() ?? false;

    if (!isValid) {
      if (validateName(nameController.text) != null) {
        nameFocusNode.requestFocus();
      } else {
        phoneFocusNode.requestFocus();
      }
      return;
    }

    final name = collapseSpaces(nameController.text);
    final phone = normalizePhilippinePhone(phoneController.text);

    setState(() {
      isSaving = true;
    });

    try {
      await user.updateDisplayName(name);

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.set(
        firestore.collection('users').doc(user.uid),
        {
          'name': name,
          'phone': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (isSupplierEnabled) {
        batch.set(
          firestore.collection('supplierProfiles').doc(user.uid),
          {
            // Store contact is a low-risk supplier profile field.
            // Verified owner identity remains unchanged after approval.
            'phone': phone,
            'contactNumber': phone,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) {
        return;
      }

      setState(() {
        initialName = name;
        initialPhone = phone;
        nameController.text = name;
        phoneController.text = phone;
      });

      showMessage(
        'Account information updated successfully.',
      );
    } on FirebaseException catch (error) {
      showMessage(
        AppErrorMessage.from(
          error,
          fallback: 'Unable to save your account information. Please try again.',
        ),
        isError: true,
      );
    } catch (error) {
      showMessage(
        AppErrorMessage.from(
          error,
          fallback: 'Something went wrong while saving your profile. Please try again.',
          allowBusinessMessage: true,
        ),
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
              ? const Color(0xFFB3261E)
              : const Color(0xFF147D64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
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
        ),
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
      helperStyle: const TextStyle(
        color: Color(0xFF8299AA),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF7B8FA3),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF146BFF),
        fontWeight: FontWeight.w900,
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
      errorMaxLines: 2,
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
          color: Color(0xFFD32F2F),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFD32F2F),
          width: 1.5,
        ),
      ),
    );
  }

  Widget header() {
    final statusColor = hasChanges
        ? const Color(0xFFFFB25A)
        : const Color(0xFF42D59B);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF063B66),
            Color(0xFF075FAE),
            Color(0xFF146BFF),
          ],
          stops: [
            0.0,
            0.52,
            1.0,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x24146BFF),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -54,
            right: -50,
            child: Container(
              width: 188,
              height: 188,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
                border: Border.all(
                  color: Colors.white.withAlpha(18),
                ),
              ),
            ),
          ),
          Positioned(
            top: 62,
            right: 22,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(18),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              47,
              18,
              23,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isSaving
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        borderRadius: BorderRadius.circular(99),
                        child: Ink(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(34),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha(28),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY ACCOUNT',
                            style: TextStyle(
                              color: Color(0xFFBCE8FF),
                              fontSize: 9,
                              letterSpacing: 1.35,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Account Information',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.5,
                              letterSpacing: -0.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Manage the personal details used across your IsdaLink account.',
                  style: TextStyle(
                    color: Color(0xFFDDEFFF),
                    fontSize: 11.5,
                    height: 1.42,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    13,
                    13,
                    13,
                    13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(31),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(31),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(90),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          profileInitials,
                          style: const TextStyle(
                            color: Color(0xFF146BFF),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nameController.text.trim().isEmpty
                                  ? 'IsdaLink User'
                                  : collapseSpaces(nameController.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              emailController.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFD7EAF8),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(28),
                                      borderRadius:
                                          BorderRadius.circular(99),
                                      border: Border.all(
                                        color: Colors.white.withAlpha(28),
                                      ),
                                    ),
                                    child: Text(
                                      accountLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.8,
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(42),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: statusColor.withAlpha(110),
                          ),
                        ),
                        child: Text(
                          syncStatusLabel,
                          style: TextStyle(
                            color: hasChanges
                                ? const Color(0xFFFFE0B8)
                                : const Color(0xFFD9FFF0),
                            fontSize: 8.4,
                            letterSpacing: 0.55,
                            fontWeight: FontWeight.w900,
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
      ),
    );
  }

  Widget sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE9F7FF),
                Color(0xFFDDF1FF),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF146BFF),
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
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
                  fontSize: 10.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget personalDetailsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        17,
        16,
        17,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        autovalidateMode: submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          children: [
            sectionHeader(
              title: 'Personal Details',
              subtitle: 'Update the name and contact number on your profile.',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 17),
            TextFormField(
              controller: nameController,
              focusNode: nameFocusNode,
              enabled: !isSaving,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.name,
              ],
              validator: validateName,
              onFieldSubmitted: (_) {
                phoneFocusNode.requestFocus();
              },
              decoration: inputDecoration(
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: phoneController,
              focusNode: phoneFocusNode,
              enabled: !isSaving,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [
                AutofillHints.telephoneNumber,
              ],
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9+\s-]'),
                ),
                LengthLimitingTextInputFormatter(16),
              ],
              validator: validatePhone,
              onFieldSubmitted: (_) {
                saveProfile();
              },
              decoration: inputDecoration(
                label: 'Contact Number',
                icon: Icons.phone_outlined,
                helperText: 'Accepted formats: 0917... or +639...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget accountAccessRow({
    required IconData icon,
    required String label,
    required String value,
    String? note,
    bool locked = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF146BFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF7B8FA3),
                        fontSize: 8.8,
                        letterSpacing: 0.55,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        note,
                        style: const TextStyle(
                          color: Color(0xFF7B8FA3),
                          fontSize: 9.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (locked)
                Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F7FB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF8BA0B1),
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: Color(0xFFE5EDF3),
          ),
      ],
    );
  }

  Widget accountAccessCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        17,
        16,
        8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE1EBF2),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          sectionHeader(
            title: 'Account Access',
            subtitle: 'Review your sign-in email and current access level.',
            icon: Icons.security_rounded,
          ),
          const SizedBox(height: 7),
          accountAccessRow(
            icon: Icons.email_outlined,
            label: 'Sign-in Email',
            value: emailController.text,
            note: 'Email changes require a separate verification process.',
            locked: true,
          ),
          accountAccessRow(
            icon: isSupplierEnabled
                ? Icons.storefront_rounded
                : Icons.shopping_basket_outlined,
            label: 'Account Type',
            value: accountLabel,
            note: accountDescription,
          ),
          accountAccessRow(
            icon: Icons.verified_user_outlined,
            label: 'Supplier Access',
            value: supplierStatusLabel,
            note: isSupplierEnabled
                ? 'Supplier tools and supplier analytics are available.'
                : supplierStatus == 'pending'
                    ? 'Your application is waiting for administrator review.'
                    : 'Supplier access can be requested from Account Center.',
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget syncCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        13,
        14,
        13,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF72C6F8).withAlpha(75),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(170),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sync_rounded,
              color: Color(0xFF146BFF),
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROFILE SYNC',
                  style: TextStyle(
                    color: Color(0xFF146BFF),
                    fontSize: 8.8,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSupplierEnabled
                      ? 'Saving updates Account Center. Your contact number also updates the supplier storefront; verified owner identity stays protected.'
                      : supplierStatus == 'pending'
                          ? 'Saving updates Account Center only. Submitted supplier verification details stay unchanged while under review.'
                          : 'Saving updates the name and contact number shown in Account Center.',
                  style: const TextStyle(
                    color: Color(0xFF52677A),
                    fontSize: 10.5,
                    height: 1.38,
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

  Widget saveButton() {
    final canSave = hasChanges && !isSaving;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        16,
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
          height: 53,
          child: ElevatedButton.icon(
            onPressed: canSave
                ? saveProfile
                : null,
            icon: isSaving
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    hasChanges
                        ? Icons.save_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 20,
                  ),
            label: Text(
              isSaving
                  ? 'Saving Changes...'
                  : hasChanges
                      ? 'Save Changes'
                      : 'Profile Up to Date',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF146BFF),
              disabledBackgroundColor: const Color(0xFFDCE7EF),
              foregroundColor: Colors.white,
              disabledForegroundColor: const Color(0xFF7B8FA3),
              elevation: canSave ? 7 : 0,
              shadowColor: const Color(0x55146BFF),
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
        child: CircularProgressIndicator(
          color: Color(0xFF146BFF),
        ),
      ),
    );
  }

  Widget loggedOutBody() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            'Please log in first to manage your account information.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFD32F2F),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FB),
        body: Column(
          children: [
            header(),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  22,
                ),
                children: [
                  personalDetailsCard(),
                  const SizedBox(height: 14),
                  accountAccessCard(),
                  const SizedBox(height: 14),
                  syncCard(),
                ],
              ),
            ),
            saveButton(),
          ],
        ),
      ),
    );
  }
}

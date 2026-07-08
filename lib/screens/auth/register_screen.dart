import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/home/home_screen.dart';
import 'package:isdalink/screens/supplier/supplier_dashboard_screen.dart';

class RegisterScreen
    extends
        StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<
    RegisterScreen
  >
  createState() => _RegisterScreenState();
}

class _RegisterScreenState
    extends
        State<
          RegisterScreen
        > {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String selectedRole = 'vendor';
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<
    void
  >
  createAccount(
    BuildContext context,
  ) async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage(
        'Please complete all fields.',
        isError: true,
      );
      return;
    }

    if (password.length <
        6) {
      showMessage(
        'Password must be at least 6 characters.',
        isError: true,
      );
      return;
    }

    if (password !=
        confirmPassword) {
      showMessage(
        'Passwords do not match.',
        isError: true,
      );
      return;
    }

    setState(
      () {
        isLoading = true;
      },
    );

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user ==
          null) {
        showMessage(
          'Account creation failed. Please try again.',
          isError: true,
        );
        return;
      }

      await user.updateDisplayName(
        fullName,
      );

      final userData = {
        'uid': user.uid,
        'name': fullName,
        'email': email,
        'phone': phone,
        'role': selectedRole,
        'region': 'Caraga Region',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (selectedRole ==
          'supplier') {
        userData.addAll(
          {
            'supplierStatus': 'approved',
            'supplierName': fullName,
            'paymentMethod': 'COD',
          },
        );
      } else {
        userData.addAll(
          {
            'supplierStatus': 'not_applicable',
          },
        );
      }

      await FirebaseFirestore.instance
          .collection(
            'users',
          )
          .doc(
            user.uid,
          )
          .set(
            userData,
          );

      if (selectedRole ==
          'supplier') {
        await FirebaseFirestore.instance
            .collection(
              'supplierProfiles',
            )
            .doc(
              user.uid,
            )
            .set(
              {
                'uid': user.uid,
                'supplierName': fullName,
                'email': email,
                'phone': phone,
                'location': 'Caraga Region',
                'status': 'approved',
                'paymentMethod': 'COD',
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
            );
      }

      if (!context.mounted) return;

      if (selectedRole ==
          'supplier') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (
                  _,
                ) => const SupplierDashboardScreen(),
          ),
          (
            route,
          ) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (
                  _,
                ) => const HomeScreen(),
          ),
          (
            route,
          ) => false,
        );
      }
    } on FirebaseAuthException catch (
      error
    ) {
      showMessage(
        authErrorMessage(
          error,
        ),
        isError: true,
      );
    } catch (
      error
    ) {
      showMessage(
        'Failed to create account: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            isLoading = false;
          },
        );
      }
    }
  }

  String authErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return error.message ??
            'Registration failed.';
    }
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor: isError
            ? const Color(
                0xFFD32F2F,
              )
            : const Color(
                0xFF2E7D32,
              ),
      ),
    );
  }

  InputDecoration inputStyle({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(
          0xFFCAD6E0,
        ),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(
          0xFFCAD6E0,
        ),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(
        0x332E4050,
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          12,
        ),
        borderSide: const BorderSide(
          color: Color(
            0x334FFFFFF,
          ),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          12,
        ),
        borderSide: const BorderSide(
          color: Color(
            0xFF146BFF,
          ),
          width: 1.5,
        ),
      ),
    );
  }

  Widget roleCard({
    required String role,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected =
        selectedRole ==
        role;

    return Expanded(
      child: GestureDetector(
        onTap: isLoading
            ? null
            : () {
                setState(
                  () {
                    selectedRole = role;
                  },
                );
              },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 106,
          ),
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(
                    0xFF146BFF,
                  ).withAlpha(
                    70,
                  )
                : const Color(
                    0x332E4050,
                  ),
            borderRadius: BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: isSelected
                  ? const Color(
                      0xFF7DB2FF,
                    )
                  : const Color(
                      0x334FFFFFF,
                    ),
              width: 1.4,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : const Color(
                        0xFFCAD6E0,
                      ),
                size: 25,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : const Color(
                          0xFFEAF4FF,
                        ),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(
                    0xFFC9D7E5,
                  ),
                  fontSize: 10,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final roleNote =
        selectedRole ==
            'supplier'
        ? 'Supplier account will open supplier tools for posting stocks and managing COD orders.'
        : 'Vendor account can browse suppliers, order fish stocks, and track COD orders.';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(
                0xCC061827,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(
                      0x33102C44,
                    ),
                    Color(
                      0xDD061827,
                    ),
                    Color(
                      0xFF020712,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    0,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => Navigator.pop(
                                context,
                              ),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(
                              38,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      26,
                      22,
                      26,
                      26,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF146BFF,
                            ),
                            borderRadius: BorderRadius.circular(
                              14,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(
                                  0x73146BFF,
                                ),
                                blurRadius: 18,
                                offset: Offset(
                                  0,
                                  6,
                                ),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.set_meal,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        const Text(
                          'Join IsdaLink',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        const Text(
                          'Create a vendor or supplier account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(
                              0xFFC9D7E5,
                            ),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        Row(
                          children: [
                            roleCard(
                              role: 'vendor',
                              icon: Icons.shopping_basket,
                              title: 'Vendor / Buyer',
                              subtitle: 'Browse and place COD orders',
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            roleCard(
                              role: 'supplier',
                              icon: Icons.storefront,
                              title: 'Supplier',
                              subtitle: 'Post stocks and manage orders',
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          roleNote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(
                              0xFF8FA8BD,
                            ),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextField(
                          controller: fullNameController,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          decoration: inputStyle(
                            hint:
                                selectedRole ==
                                    'supplier'
                                ? 'Supplier / Business Name'
                                : 'Full Name',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        TextField(
                          controller: emailController,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          decoration: inputStyle(
                            hint: 'Email Address',
                            icon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        TextField(
                          controller: phoneController,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          keyboardType: TextInputType.phone,
                          decoration: inputStyle(
                            hint: 'Phone Number',
                            icon: Icons.phone_outlined,
                          ),
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        TextField(
                          controller: passwordController,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          obscureText: obscurePassword,
                          decoration: inputStyle(
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(
                                  () {
                                    obscurePassword = !obscurePassword;
                                  },
                                );
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(
                                  0xFFCAD6E0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        TextField(
                          controller: confirmPasswordController,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          obscureText: obscureConfirmPassword,
                          decoration: inputStyle(
                            hint: 'Confirm Password',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(
                                  () {
                                    obscureConfirmPassword = !obscureConfirmPassword;
                                  },
                                );
                              },
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: const Color(
                                  0xFFCAD6E0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () => createAccount(
                                    context,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF146BFF,
                              ),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(
                                0xFF7B8FA3,
                              ),
                              elevation: 6,
                              shadowColor: const Color(
                                0x73146BFF,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        const Text(
                          'Registration is connected to Firebase Authentication and Firestore users.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(
                              0xFF8FA8BD,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ],
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
}

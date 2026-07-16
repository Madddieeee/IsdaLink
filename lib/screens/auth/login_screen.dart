import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/admin/admin_dashboard_screen.dart';
import 'package:isdalink/screens/auth/register_screen.dart';
import 'package:isdalink/screens/home/home_screen.dart';
import 'package:isdalink/screens/supplier/supplier_dashboard_screen.dart';

class LoginScreen
    extends
        StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<
    LoginScreen
  >
  createState() => _LoginScreenState();
}

class _LoginScreenState
    extends
        State<
          LoginScreen
        > {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void goToRegister(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const RegisterScreen(),
      ),
    );
  }

  Future<
    void
  >
  login(
    BuildContext context,
  ) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty) {
      showMessage(
        'Please enter your email and password.',
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
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user ==
          null) {
        showMessage(
          'Login failed. Please try again.',
          isError: true,
        );
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection(
            'users',
          )
          .doc(
            user.uid,
          )
          .get();

      final userData = userDoc.data();

      final role =
          (userData?['role'] ??
                  'vendor')
              .toString()
              .toLowerCase();

      final supplierStatus =
          (userData?['supplierStatus'] ??
                  'not_applicable')
              .toString()
              .toLowerCase();

      if (!context.mounted) return;

      if (role ==
          'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (
                  _,
                ) => const AdminDashboardScreen(),
          ),
          (
            route,
          ) => false,
        );
      } else if (role ==
              'supplier' ||
          supplierStatus ==
              'approved') {
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
        'Login failed: $error',
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

  Future<
    void
  >
  resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage(
        'Enter your email first, then tap Forgot password.',
        isError: true,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      showMessage(
        'Password reset email sent. Please check your inbox.',
      );
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
        'Failed to send reset email: $error',
        isError: true,
      );
    }
  }

  String authErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return error.message ??
            'Authentication failed.';
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
            0x33FFFFFF,
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

  @override
  Widget build(
    BuildContext context,
  ) {
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                      'IsdaLink',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    const Text(
                      'FRESH CATCH, DIRECT SOURCE',
                      style: TextStyle(
                        color: Color(
                          0xFFC9D7E5,
                        ),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(
                      height: 36,
                    ),
                    TextField(
                      controller: emailController,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      decoration: inputStyle(
                        hint: 'vendor@isdalink.com',
                        icon: Icons.email_outlined,
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
                        hint: '••••••••',
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
                      height: 8,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : resetPassword,
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Color(
                              0xFF7DB2FF,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => login(
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
                                'Log In',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Color(
                              0xFFC9D7E5,
                            ),
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => goToRegister(
                                  context,
                                ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              color: Color(
                                0xFF7DB2FF,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                    const Text(
                      'Login is connected to Firebase Authentication and role routing.',
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
          ),
        ],
      ),
    );
  }
}

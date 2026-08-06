import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/admin/admin_dashboard_screen.dart';
import 'package:isdalink/screens/auth/register_screen.dart';
import 'package:isdalink/screens/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool isLoading = false;
  bool isResettingPassword = false;
  bool obscurePassword = true;
  bool submitted = false;

  String? authenticationError;

  bool get isBusy => isLoading || isResettingPassword;

  @override
  void initState() {
    super.initState();

    emailController.addListener(
      clearAuthenticationError,
    );
    passwordController.addListener(
      clearAuthenticationError,
    );
  }

  @override
  void dispose() {
    emailController.removeListener(
      clearAuthenticationError,
    );
    passwordController.removeListener(
      clearAuthenticationError,
    );

    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }

  void clearAuthenticationError() {
    if (authenticationError != null && mounted) {
      setState(() {
        authenticationError = null;
      });
    }
  }

  String normalizeEmail(
    String value,
  ) {
    return value.trim().toLowerCase();
  }

  String? validateEmail(
    String? value,
  ) {
    final email = normalizeEmail(
      value ?? '',
    );

    if (email.isEmpty) {
      return 'Enter your email address.';
    }

    final emailPattern = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? validatePassword(
    String? value,
  ) {
    if ((value ?? '').isEmpty) {
      return 'Enter your password.';
    }

    return null;
  }

  void focusFirstInvalidField() {
    if (validateEmail(emailController.text) != null) {
      emailFocusNode.requestFocus();
      return;
    }

    if (validatePassword(passwordController.text) != null) {
      passwordFocusNode.requestFocus();
    }
  }

  void openRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  Future<void> login() async {
    if (isBusy) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      submitted = true;
      authenticationError = null;
    });

    final isValid = formKey.currentState?.validate() ?? false;

    if (!isValid) {
      focusFirstInvalidField();
      return;
    }

    final email = normalizeEmail(
      emailController.text,
    );
    final password = passwordController.text;

    setState(() {
      isLoading = true;
    });

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        setAuthenticationError(
          'Unable to sign in. Please try again.',
        );
        return;
      }

      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDocument.data();
      final role = (userData?['role'] ?? 'vendor')
          .toString()
          .trim()
          .toLowerCase();

      if (!mounted) {
        return;
      }

      final destination = role == 'admin'
          ? const AdminDashboardScreen()
          : const HomeScreen();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => destination,
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      final message = authenticationErrorMessage(
        error,
      );

      setAuthenticationError(
        message,
      );

      if (error.code == 'invalid-credential' ||
          error.code == 'wrong-password' ||
          error.code == 'user-not-found') {
        passwordController.clear();
        passwordFocusNode.requestFocus();
      }
    } catch (_) {
      setAuthenticationError(
        'Unable to sign in right now. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    if (isBusy) {
      return;
    }

    FocusScope.of(context).unfocus();

    final emailError = validateEmail(
      emailController.text,
    );

    if (emailError != null) {
      setState(() {
        submitted = true;
      });

      formKey.currentState?.validate();
      emailFocusNode.requestFocus();

      setAuthenticationError(
        emailError,
      );
      return;
    }

    setState(() {
      isResettingPassword = true;
      authenticationError = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: normalizeEmail(
          emailController.text,
        ),
      );

      showMessage(
        'Password reset instructions were sent to your email.',
      );
    } on FirebaseAuthException catch (error) {
      setAuthenticationError(
        authenticationErrorMessage(
          error,
        ),
      );
    } catch (_) {
      setAuthenticationError(
        'Unable to send the reset email right now.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isResettingPassword = false;
        });
      }
    }
  }

  String authenticationErrorMessage(
    FirebaseAuthException error,
  ) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account was found with this email.';
      case 'wrong-password':
        return 'The password is incorrect.';
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void setAuthenticationError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      authenticationError = message;
    });
  }

  void showMessage(
    String message,
  ) {
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
          backgroundColor: const Color(0xFF147D64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
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

  InputDecoration inputStyle({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    const radius = 16.0;

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFC5D6E2),
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF83C8FF),
        fontWeight: FontWeight.w900,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFC5D6E2),
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xE60A2638),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 17,
        horizontal: 16,
      ),
      errorMaxLines: 2,
      errorStyle: const TextStyle(
        color: Color(0xFFFFA199),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: Color(0x557FB3D4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: Color(0xFF32A9FF),
          width: 1.7,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: Color(0xFFFF756B),
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: Color(0xFFFF8B82),
          width: 1.7,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: Color(0x337FB3D4),
        ),
      ),
    );
  }

  Widget buildLogo() {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1596FF),
            Color(0xFF155BFF),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withAlpha(44),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73146BFF),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.set_meal_rounded,
        color: Colors.white,
        size: 34,
      ),
    );
  }

  Widget buildAuthenticationError() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: authenticationError == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(
                authenticationError,
              ),
              width: double.infinity,
              margin: const EdgeInsets.only(
                bottom: 14,
              ),
              padding: const EdgeInsets.fromLTRB(
                12,
                11,
                12,
                11,
              ),
              decoration: BoxDecoration(
                color: const Color(0x36FF6B61),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0x8CFF7A70),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFFA199),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      authenticationError!,
                      style: const TextStyle(
                        color: Color(0xFFFFD4D0),
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildAuthenticationPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 8,
          sigmaY: 8,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            16,
          ),
          decoration: BoxDecoration(
            color: const Color(0xD4081C2A),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withAlpha(30),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x47000000),
                blurRadius: 28,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: AutofillGroup(
            child: Form(
              key: formKey,
              autovalidateMode: submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                children: [
                  buildAuthenticationError(),
                  TextFormField(
                    controller: emailController,
                    focusNode: emailFocusNode,
                    enabled: !isBusy,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.email,
                      AutofillHints.username,
                    ],
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: validateEmail,
                    onFieldSubmitted: (_) {
                      passwordFocusNode.requestFocus();
                    },
                    decoration: inputStyle(
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    enabled: !isBusy,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [
                      AutofillHints.password,
                    ],
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: validatePassword,
                    onFieldSubmitted: (_) {
                      login();
                    },
                    decoration: inputStyle(
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        tooltip: obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: isBusy
                            ? null
                            : () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFFD5E4EF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isBusy
                          ? null
                          : resetPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF91CDFF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        isResettingPassword
                            ? 'Sending reset email...'
                            : 'Forgot password?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    height: 53,
                    child: ElevatedButton(
                      onPressed: isBusy
                          ? null
                          : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF176FFF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF315473),
                        elevation: 8,
                        shadowColor: const Color(0x73146BFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                ),
                                SizedBox(width: 11),
                                Text(
                                  'Signing In...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF020712),
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Color(0xFF020712),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFF020712),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/login_bg.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0xC9061A2A),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x57138CE7),
                        Color(0xE5061725),
                        Color(0xFF020712),
                      ],
                      stops: [
                        0.0,
                        0.58,
                        1.0,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 78,
                right: -60,
                child: Container(
                  width: 182,
                  height: 182,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(16),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (
                    context,
                    constraints,
                  ) {
                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        22,
                        24,
                        24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 46,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildLogo(),
                            const SizedBox(height: 17),
                            const Text(
                              'IsdaLink',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'FRESH CATCH, DIRECT SOURCE',
                              style: TextStyle(
                                color: Color(0xFFD5E4EE),
                                fontSize: 9.8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.42,
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Manage orders, suppliers, and analytics in one place.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFA7BBC9),
                                fontSize: 11.5,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 25),
                            buildAuthenticationPanel(),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'New to IsdaLink? ',
                                  style: TextStyle(
                                    color: Color(0xFFB8C9D6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: isBusy
                                      ? null
                                      : openRegistration,
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF91CDFF),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }
}

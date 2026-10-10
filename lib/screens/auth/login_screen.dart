import 'package:isdalink/screens/auth/auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.showBackButton = true,
    this.authGateManaged = false,
    super.key,
  });

  final bool showBackButton;

  /// True when AuthGate is already listening above this login screen.
  final bool authGateManaged;

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

    emailController.addListener(clearAuthenticationError);
    passwordController.addListener(clearAuthenticationError);
  }

  @override
  void dispose() {
    emailController.removeListener(clearAuthenticationError);
    passwordController.removeListener(clearAuthenticationError);

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

  String normalizeEmail(String value) {
    return value.trim().toLowerCase();
  }

  String? validateEmail(String? value) {
    final email = normalizeEmail(value ?? '');

    if (email.isEmpty) {
      return 'Enter your email address.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  String? validatePassword(String? value) {
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
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => const RegisterScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
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

    final email = normalizeEmail(emailController.text);
    final password = passwordController.text;

    setState(() {
      isLoading = true;
    });

    var signedIn = false;

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        setAuthenticationError('Unable to sign in. Please try again.');
        return;
      }

      signedIn = true;

      if (!mounted) return;

      // Logout and Welcome can open Login as a standalone route. Restore
      // AuthGate there so it can resolve the role and show Home or Admin.
      // When the gate already owns Login, its auth listener handles the handoff.
      if (!widget.authGateManaged) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (error) {
      final message = authenticationErrorMessage(error);

      setAuthenticationError(message);

      if (error.code == 'invalid-credential' ||
          error.code == 'wrong-password' ||
          error.code == 'user-not-found') {
        passwordController.clear();
        passwordFocusNode.requestFocus();
      }
    } catch (_) {
      setAuthenticationError('Unable to sign in right now. Please try again.');
    } finally {
      // A successful sign-in is handed to either the existing AuthGate or the
      // restored gate route. On failure, restore the form for another attempt.
      if (mounted && !signedIn) {
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

    final emailError = validateEmail(emailController.text);

    if (emailError != null) {
      setState(() {
        submitted = true;
      });

      formKey.currentState?.validate();
      emailFocusNode.requestFocus();

      setAuthenticationError(emailError);
      return;
    }

    setState(() {
      isResettingPassword = true;
      authenticationError = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: normalizeEmail(emailController.text),
      );

      showMessage('Password reset instructions were sent to your email.');
    } on FirebaseAuthException catch (error) {
      setAuthenticationError(authenticationErrorMessage(error));
    } catch (_) {
      setAuthenticationError('Unable to send the reset email right now.');
    } finally {
      if (mounted) {
        setState(() {
          isResettingPassword = false;
        });
      }
    }
  }

  String authenticationErrorMessage(FirebaseAuthException error) {
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

  void setAuthenticationError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      authenticationError = message;
    });
  }

  void showMessage(String message) {
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
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    const radius = 18.0;

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF7D91A1),
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(icon, color: const Color(0xFF0875D1), size: 23),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 50),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF4F8FB),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 13.5,
        horizontal: 16,
      ),
      errorMaxLines: 2,
      errorStyle: const TextStyle(
        color: Color(0xFFC84238),
        fontSize: 10.5,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFD5E3EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFF0875D1), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFE46A61), width: 1.15),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFD9544B), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: Color(0xFFE5EDF2)),
      ),
    );
  }

  Widget buildAuthenticationError() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: authenticationError == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(authenticationError),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF0C5C0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFC84238),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authenticationError!,
                      style: const TextStyle(
                        color: Color(0xFF8F332C),
                        fontSize: 11,
                        height: 1.3,
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
    return AutofillGroup(
      child: Form(
        key: formKey,
        autovalidateMode: submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildAuthenticationError(),
            TextFormField(
              controller: emailController,
              focusNode: emailFocusNode,
              enabled: !isBusy,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 14.5,
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
              onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
              decoration: inputStyle(
                hint: 'Email Address',
                icon: Icons.mail_outline_rounded,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              enabled: !isBusy,
              style: const TextStyle(
                color: Color(0xFF102C44),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              autocorrect: false,
              enableSuggestions: false,
              validator: validatePassword,
              onFieldSubmitted: (_) => login(),
              decoration: inputStyle(
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? 'Show password' : 'Hide password',
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
                    color: const Color(0xFF60788A),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isBusy ? null : resetPassword,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0875D1),
                  backgroundColor: Colors.transparent,
                  overlayColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isResettingPassword
                      ? 'Sending reset email...'
                      : 'Forgot password?',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isBusy ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0875D1),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB9CBD7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Signing In...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoginWatermark() {
    return IgnorePointer(
      child: SizedBox(
        height: 118,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Opacity(
                opacity: 0.055,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF16A9D8),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/isdalink_wave.png',
                    width: 310,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0.70, 0.72),
              child: Opacity(
                opacity: 0.055,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF0875D1),
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/isdalink_fish_mark.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAccountDivider() {
    return const Row(
      children: [
        Expanded(
          child: Divider(height: 1, thickness: 1, color: Color(0xFFDCE8EF)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: TextStyle(
              color: Color(0xFF8096A5),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: Divider(height: 1, thickness: 1, color: Color(0xFFDCE8EF)),
        ),
      ],
    );
  }

  Widget buildHeader(BuildContext context, double headerHeight) {
    return SizedBox(
      height: headerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage('assets/images/auth_caraga_header.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x08001427),
                  Color(0x22002642),
                  Color(0x9A063C5F),
                ],
                stops: [0.0, 0.52, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.showBackButton)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isBusy
                                ? null
                                : () => Navigator.maybePop(context),
                            borderRadius: BorderRadius.circular(18),
                            child: Ink(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0x3300182A),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 44, height: 44),
                      const Spacer(),
                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          'assets/images/isdalink_logo.png',
                          width: 124,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      color: Color(0xFFE8F5FB),
                      fontSize: 10.5,
                      letterSpacing: 1.9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Sign in to IsdaLink',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Access your orders, suppliers, and account.',
                    style: TextStyle(
                      color: Color(0xFFF1F7FA),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardOpen = mediaQuery.viewInsets.bottom > 0;

    final headerHeight = keyboardOpen
        ? (mediaQuery.size.height * 0.27).clamp(205.0, 238.0).toDouble()
        : (mediaQuery.size.height * 0.36).clamp(278.0, 338.0).toDouble();

    const overlap = 18.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, viewport) {
              final cardMinHeight =
                  viewport.maxHeight - headerHeight + overlap > 360
                  ? viewport.maxHeight - headerHeight + overlap
                  : 360.0;

              final contentMinHeight = cardMinHeight - 58;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: keyboardOpen ? 12 : 0),
                child: Column(
                  children: [
                    buildHeader(context, headerHeight),
                    Transform.translate(
                      offset: const Offset(0, -overlap),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(minHeight: cardMinHeight),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          keyboardOpen ? 24 : 30,
                          24,
                          keyboardOpen ? 22 : 28,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(36),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF0B4F70,
                              ).withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: contentMinHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                buildAuthenticationPanel(),
                                const SizedBox(height: 22),
                                buildAccountDivider(),
                                const SizedBox(height: 14),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      'New to IsdaLink? ',
                                      style: TextStyle(
                                        color: Color(0xFF647C8F),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: isBusy
                                          ? null
                                          : openRegistration,
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF0875D1,
                                        ),
                                        backgroundColor: Colors.transparent,
                                        overlayColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                          vertical: 3,
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
                                if (!keyboardOpen) ...[
                                  const Spacer(),
                                  buildLoginWatermark(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

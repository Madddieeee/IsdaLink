import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/home/home_screen.dart';

class RegistrationWelcomeScreen extends StatefulWidget {
  const RegistrationWelcomeScreen({
    this.fullName,
    super.key,
  });

  final String? fullName;

  @override
  State<RegistrationWelcomeScreen> createState() =>
      _RegistrationWelcomeScreenState();
}

class _RegistrationWelcomeScreenState extends State<RegistrationWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _displayName {
    final provided = widget.fullName?.trim();
    final authName = FirebaseAuth.instance.currentUser?.displayName?.trim();
    final value = (provided != null && provided.isNotEmpty)
        ? provided
        : (authName != null && authName.isNotEmpty ? authName : 'there');

    return value.split(RegExp(r'\s+')).first;
  }

  void _continueToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.018),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
      (route) => false,
    );
  }

  double _segment(double start, double end) {
    final progress = _controller.value;
    if (progress <= start) return 0;
    if (progress >= end) return 1;
    return (progress - start) / (end - start);
  }

  Widget _reveal({
    required Widget child,
    required double start,
    required double end,
    double y = 12,
  }) {
    final value = Curves.easeOutCubic.transform(_segment(start, end));
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, y * (1 - value)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF03131F),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF03131F),
          body: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  const Image(
                    image: AssetImage('assets/images/auth_caraga_header.jpg'),
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x58052D47),
                          Color(0xAA06283D),
                          Color(0xF503111C),
                        ],
                        stops: [0.0, 0.50, 1.0],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: Column(
                        children: [
                          const Spacer(flex: 3),
                          _reveal(
                            start: 0.02,
                            end: 0.34,
                            y: 8,
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/images/isdalink_logo.png',
                                width: 205,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _reveal(
                            start: 0.16,
                            end: 0.48,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x292ED9A0),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0x7749E4B3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF61E7BA),
                                    size: 18,
                                  ),
                                  SizedBox(width: 7),
                                  Text(
                                    'ACCOUNT READY',
                                    style: TextStyle(
                                      color: Color(0xFFE8FFF7),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _reveal(
                            start: 0.28,
                            end: 0.62,
                            child: Text(
                              'Welcome, $_displayName',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _reveal(
                            start: 0.38,
                            end: 0.72,
                            child: const Text(
                              'Your IsdaLink vendor account is ready. Start by finding suppliers and fresh fish stocks in Caraga.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFD5E4EE),
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(flex: 4),
                          _reveal(
                            start: 0.55,
                            end: 0.90,
                            y: 9,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x1FFFFFFF),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0x35FFFFFF),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _WelcomeFeature(
                                    icon: Icons.storefront_outlined,
                                    label: 'Suppliers',
                                  ),
                                  _WelcomeFeature(
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Fish Stocks',
                                  ),
                                  _WelcomeFeature(
                                    icon: Icons.receipt_long_outlined,
                                    label: 'COD Orders',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _reveal(
                            start: 0.68,
                            end: 1.0,
                            y: 7,
                            child: SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _continueToHome,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0875D1),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(19),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Get Started',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(width: 9),
                                    Icon(Icons.arrow_forward_rounded, size: 21),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeFeature extends StatelessWidget {
  const _WelcomeFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFBCE5FF), size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE5F2F8),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

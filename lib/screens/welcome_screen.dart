import 'package:flutter/material.dart';
import 'package:isdalink/screens/auth/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnimation;
  late Animation<double> _fadeAnimation;

  void goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _moveAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => goToLogin(context),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/login_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF102C44).withValues(alpha: 0.62),
                      const Color(0xFF061827).withValues(alpha: 0.82),
                      const Color(0xFF020712).withValues(alpha: 0.98),
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: const Color(0xFF146BFF),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF146BFF).withValues(alpha: 0.45),
                            blurRadius: 28,
                            spreadRadius: 1,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.set_meal,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Welcome to',
                      style: TextStyle(
                        color: Color(0xFFDCE9F5),
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'IsdaLink',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'FRESH CATCH, DIRECT SOURCE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFBFD1E3),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'A mobile-based fish supply management system for vendor-supplier coordination and sales analytics.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFE4EEF7),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),

                    const Spacer(flex: 4),

                    Container(
                      width: 90,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    const SizedBox(height: 26),

                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, -_moveAnimation.value),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: const [
                          Icon(
                            Icons.touch_app,
                            color: Color(0xFF9EC7FF),
                            size: 22,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap anywhere to continue',
                            style: TextStyle(
                              color: Color(0xFFB8C9DB),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Connecting fish vendors and suppliers in one platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7F96AA), fontSize: 11),
                    ),

                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

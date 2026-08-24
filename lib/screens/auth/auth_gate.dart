import 'dart:math' as math;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isdalink/screens/admin/admin_dashboard_screen.dart';
import 'package:isdalink/screens/home/home_screen.dart';
import 'package:isdalink/screens/welcome_screen.dart';
import 'package:isdalink/services/push_notification_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (
        context,
        snapshot,
      ) {
        final user = snapshot.data;

        if (user == null) {
          return const WelcomeScreen();
        }

        return _SignedInDestination(
          user: user,
        );
      },
    );
  }
}

class _SignedInDestination extends StatefulWidget {
  const _SignedInDestination({
    required this.user,
  });

  final User user;

  @override
  State<_SignedInDestination> createState() =>
      _SignedInDestinationState();
}

class _SignedInDestinationState
    extends State<_SignedInDestination> {
  late Future<String> _roleFuture;

  @override
  void initState() {
    super.initState();
    _roleFuture = _loadRole();
  }

  @override
  void didUpdateWidget(
    covariant _SignedInDestination oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.user.uid != widget.user.uid) {
      _roleFuture = _loadRole();
    }
  }

  Future<String> _loadRole() async {
    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();

    final userData = userDocument.data();

    return (userData?['role'] ?? 'vendor')
        .toString()
        .trim()
        .toLowerCase();
  }

  void retry() {
    setState(() {
      _roleFuture = _loadRole();
    });
  }

  Future<void> logout() async {
    await PushNotificationService.instance.signOut();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return FutureBuilder<String>(
      future: _roleFuture,
      builder: (
        context,
        snapshot,
      ) {
        if (snapshot.connectionState !=
            ConnectionState.done) {
          return const _SessionLoadingScreen();
        }

        if (snapshot.hasError) {
          return _SessionErrorScreen(
            onRetry: retry,
            onLogout: logout,
          );
        }

        final role = snapshot.data ?? 'vendor';

        if (role == 'admin') {
          return const AdminDashboardScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

class _SessionLoadingScreen extends StatefulWidget {
  const _SessionLoadingScreen();

  @override
  State<_SessionLoadingScreen> createState() =>
      _SessionLoadingScreenState();
}

class _SessionLoadingScreenState extends State<_SessionLoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sceneController;
  late final AnimationController _pulseController;
  late final AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _sceneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1550),
    )..repeat();
  }

  @override
  void dispose() {
    _sceneController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061A28),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _sceneController,
          _pulseController,
          _progressController,
        ]),
        builder: (context, child) {
          final scene = _sceneController.value;
          final pulse = _pulseController.value;
          final progress = _progressController.value;

          return Stack(
            fit: StackFit.expand,
            children: [
              _CinematicMarketBackground(
                scene: scene,
                pulse: pulse,
              ),
              IgnorePointer(
                child: CustomPaint(
                  painter: _GlassAtmospherePainter(
                    progress: scene,
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = constraints.maxHeight;

                    return Stack(
                      children: [
                        Positioned(
                          right: 30,
                          top: height * 0.12 +
                              math.sin(scene * math.pi * 2) * 5,
                          child: const _FloatingLens(
                            diameter: 68,
                            opacity: 0.10,
                          ),
                        ),
                        Positioned(
                          left: 28,
                          bottom: height * 0.18 +
                              math.cos(scene * math.pi * 2) * 6,
                          child: const _FloatingLens(
                            diameter: 34,
                            opacity: 0.08,
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0, -0.10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 360,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _HeroMirrorBubble(
                                    pulse: pulse,
                                  ),
                                  const SizedBox(height: 19),
                                  const Text(
                                    'IsdaLink',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 35,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.45,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Fresh fish supply, connected.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.70,
                                      ),
                                      fontSize: 13.3,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.18,
                                    ),
                                  ),
                                  const SizedBox(height: 31),
                                  _CompactMirrorSession(
                                    progress: progress,
                                    pulse: pulse,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 24,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 12.5,
                                color: Colors.white.withValues(
                                  alpha: 0.36,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Secure account session',
                                style: TextStyle(
                                  color: Colors.white.withValues(
                                    alpha: 0.38,
                                  ),
                                  fontSize: 10.6,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CinematicMarketBackground extends StatelessWidget {
  const _CinematicMarketBackground({
    required this.scene,
    required this.pulse,
  });

  final double scene;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: 1.055 + pulse * 0.012,
          child: Transform.translate(
            offset: Offset(
              math.sin(scene * math.pi * 2) * 5,
              math.cos(scene * math.pi * 2) * 3,
            ),
            child: Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 1.6,
            sigmaY: 1.6,
          ),
          child: const SizedBox.expand(),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xD90A1D2C),
                Color(0xB9082B3D),
                Color(0xE3094558),
              ],
              stops: [
                0.0,
                0.46,
                1.0,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.15),
              radius: 0.95,
              colors: [
                Colors.white.withValues(alpha: 0.055),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0x26000000),
                Colors.transparent,
                Color(0x26000000),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMirrorBubble extends StatelessWidget {
  const _HeroMirrorBubble({
    required this.pulse,
  });

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 126,
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF9BE8FF).withValues(
                    alpha: 0.11 + pulse * 0.035,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 20,
                sigmaY: 20,
              ),
              child: Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.19),
                      const Color(0xFFB8EEFF).withValues(
                        alpha: 0.08,
                      ),
                      Colors.white.withValues(alpha: 0.045),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF44C9FF).withValues(
                        alpha: 0.15 + pulse * 0.05,
                      ),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 13,
                      left: 18,
                      child: Container(
                        width: 37,
                        height: 14,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.42),
                              Colors.white.withValues(alpha: 0.04),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 67,
                        height: 67,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF3AAFFF),
                              Color(0xFF1578FF),
                              Color(0xFF0C5FDC),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3ABFFF).withValues(
                                alpha: 0.25 + pulse * 0.08,
                              ),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.set_meal_rounded,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 13,
                      bottom: 20,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.19),
                          ),
                        ),
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

class _CompactMirrorSession extends StatelessWidget {
  const _CompactMirrorSession({
    required this.progress,
    required this.pulse,
  });

  final double progress;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: _OrbitFishReload(
        progress: progress,
        pulse: pulse,
      ),
    );
  }
}

class _OrbitFishReload extends StatelessWidget {
  const _OrbitFishReload({
    required this.progress,
    required this.pulse,
  });

  final double progress;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final fishTurns = (progress * 1.05) % 1.0;

    return SizedBox(
      width: 56,
      height: 56,
      child: Transform.rotate(
        angle: fishTurns * math.pi * 2,
        child: Transform.translate(
          offset: const Offset(0, -16),
          child: Transform.rotate(
            angle: math.pi / 2,
            child: Opacity(
              opacity: 0.94,
              child: CustomPaint(
                size: const Size(18, 12),
                painter: _MiniOrbitFishPainter(
                  shimmer: pulse,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniOrbitFishPainter extends CustomPainter {
  const _MiniOrbitFishPainter({
    required this.shimmer,
  });

  final double shimmer;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..moveTo(size.width * 0.20, size.height * 0.50)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.16,
        size.width * 0.75,
        size.height * 0.18,
        size.width * 0.88,
        size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.82,
        size.width * 0.34,
        size.height * 0.84,
        size.width * 0.20,
        size.height * 0.50,
      )
      ..close();

    final tail = Path()
      ..moveTo(size.width * 0.21, size.height * 0.50)
      ..lineTo(size.width * 0.02, size.height * 0.20)
      ..quadraticBezierTo(
        size.width * 0.08,
        size.height * 0.50,
        size.width * 0.02,
        size.height * 0.80,
      )
      ..close();

    canvas.drawPath(
      tail,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x806ADAF6),
            Color(0xD0D4F8FF),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0x9970DDF6),
            Color(0xD7E3FBFF),
            Color(0xFFFFFFFF),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.white.withValues(alpha: 0.18),
    );

    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.44,
        size.height * 0.26,
        size.width * 0.22,
        size.height * 0.10,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10 + shimmer * 0.10),
    );

    canvas.drawCircle(
      Offset(size.width * 0.77, size.height * 0.42),
      1.2,
      Paint()..color = const Color(0xFF0A3042),
    );
    canvas.drawCircle(
      Offset(size.width * 0.782, size.height * 0.40),
      0.38,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniOrbitFishPainter oldDelegate) {
    return oldDelegate.shimmer != shimmer;
  }
}

class _FloatingLens extends StatelessWidget {
  const _FloatingLens({
    required this.diameter,
    required this.opacity,
  });

  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8,
          sigmaY: 8,
        ),
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: opacity + 0.07),
                Colors.white.withValues(alpha: opacity * 0.28),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.8,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: diameter * 0.15,
                left: diameter * 0.18,
                child: Container(
                  width: diameter * 0.32,
                  height: diameter * 0.13,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassAtmospherePainter extends CustomPainter {
  const _GlassAtmospherePainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final particlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.085);

    for (var i = 0; i < 13; i++) {
      final x =
          ((i * 83.0) + progress * 31) % size.width;
      final y =
          ((i * 127.0) - progress * 43) % size.height;

      canvas.drawCircle(
        Offset(x, y),
        i % 4 == 0 ? 1.15 : 0.65,
        particlePaint,
      );
    }

    final glowRect = Rect.fromCenter(
      center: Offset(
        size.width * 0.78,
        size.height * 0.88,
      ),
      width: size.width * 0.70,
      height: size.width * 0.70,
    );

    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF64D8F1)
                .withValues(alpha: 0.045),
            Colors.transparent,
          ],
        ).createShader(glowRect),
    );
  }

  @override
  bool shouldRepaint(
    covariant _GlassAtmospherePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

class _SessionErrorScreen
    extends StatelessWidget {
  const _SessionErrorScreen({
    required this.onRetry,
    required this.onLogout,
  });

  final VoidCallback onRetry;
  final Future<void> Function()
      onLogout;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F9FD,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              28,
            ),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 420,
              ),
              child: Container(
                padding:
                    const EdgeInsets.all(
                  26,
                ),
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                  border: Border.all(
                    color: const Color(
                      0xFFDCE7F0,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(
                        alpha: 0.06,
                      ),
                      blurRadius: 24,
                      offset:
                          const Offset(
                        0,
                        10,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const _BrandMark(
                      compact: true,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      'Unable to open your saved session',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Color(
                          0xFF102C44,
                        ),
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'Check your internet connection, then try again. Your account remains signed in.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Color(
                          0xFF6F8497,
                        ),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          FilledButton.icon(
                        onPressed:
                            onRetry,
                        icon: const Icon(
                          Icons.refresh_rounded,
                        ),
                        label:
                            const Text(
                          'Try Again',
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          TextButton(
                        onPressed:
                            () async {
                          await onLogout();
                        },
                        child:
                            const Text(
                          'Log Out',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark
    extends StatelessWidget {
  const _BrandMark({
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(
    BuildContext context,
  ) {
    final size =
        compact ? 58.0 : 72.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(
          0xFF146BFF,
        ),
        borderRadius:
            BorderRadius.circular(
          compact ? 17 : 20,
        ),
      ),
      child: Icon(
        Icons.set_meal,
        color: Colors.white,
        size: compact ? 30 : 40,
      ),
    );
  }
}

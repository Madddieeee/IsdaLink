import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isdalink/screens/admin/admin_dashboard_screen.dart';
import 'package:isdalink/screens/auth/login_screen.dart';
import 'package:isdalink/screens/home/home_screen.dart';
import 'package:isdalink/services/push_notification_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          reverseDuration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: user == null
              ? const KeyedSubtree(
                  key: ValueKey('signed-out'),
                  child: LoginScreen(
                    showBackButton: false,
                    authGateManaged: true,
                  ),
                )
              : KeyedSubtree(
                  key: ValueKey('signed-in'),
                  child: _SignedInDestination(user: user),
                ),
        );
      },
    );
  }
}

class _SignedInDestination extends StatefulWidget {
  const _SignedInDestination({required this.user});

  final User user;

  @override
  State<_SignedInDestination> createState() => _SignedInDestinationState();
}

class _SignedInDestinationState extends State<_SignedInDestination>
    with TickerProviderStateMixin {
  late final AnimationController _handoffController;
  late final AnimationController _loaderController;

  String? _role;
  Object? _loadError;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();

    // The destination rises from the bottom instead of simply replacing the
    // loading screen. Around one second is visible and premium without making
    // successful logins feel artificially delayed.
    _handoffController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1080),
    );

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();

    _handoffController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _loaderController.stop();
      }
    });

    _resolveRole();
  }

  @override
  void didUpdateWidget(covariant _SignedInDestination oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.user.uid != widget.user.uid) {
      _handoffController.reset();
      if (!_loaderController.isAnimating) {
        _loaderController.repeat();
      }
      _role = null;
      _loadError = null;
      _resolving = true;
      _resolveRole();
    }
  }

  Future<void> _resolveRole() async {
    final requestedUid = widget.user.uid;

    try {
      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(requestedUid)
          .get();

      if (!mounted || widget.user.uid != requestedUid) {
        return;
      }

      final userData = userDocument.data();
      final role = (userData?['role'] ?? 'vendor')
          .toString()
          .trim()
          .toLowerCase();

      setState(() {
        _role = role;
        _loadError = null;
        _resolving = false;
      });

      // Mount and lay out Home/Admin behind the Welcome Back layer first. This
      // keeps the slide smooth even when the destination has a heavier first
      // frame or starts Firestore streams immediately.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 24));

      if (!mounted || widget.user.uid != requestedUid) {
        return;
      }

      await _handoffController.forward(from: 0);
    } catch (error) {
      if (!mounted || widget.user.uid != requestedUid) {
        return;
      }

      setState(() {
        _loadError = error;
        _resolving = false;
      });
    }
  }

  void retry() {
    _handoffController.reset();

    if (!_loaderController.isAnimating) {
      _loaderController.repeat();
    }

    setState(() {
      _role = null;
      _loadError = null;
      _resolving = true;
    });

    _resolveRole();
  }

  Future<void> logout() async {
    await PushNotificationService.instance.signOut();
  }

  @override
  void dispose() {
    _handoffController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null && _role == null) {
      return _SessionErrorScreen(onRetry: retry, onLogout: logout);
    }

    final destination = _role == null
        ? null
        : (_role == 'admin'
              ? const AdminDashboardScreen()
              : const HomeScreen());

    return AnimatedBuilder(
      animation: Listenable.merge([_handoffController, _loaderController]),
      builder: (context, _) {
        final raw = destination == null ? 0.0 : _handoffController.value;
        final slide = const Cubic(0.16, 0.82, 0.18, 1.00).transform(raw);
        final overlayExit = Curves.easeInOutCubic.transform(
          (raw / 0.82).clamp(0.0, 1.0).toDouble(),
        );
        final size = MediaQuery.sizeOf(context);

        return Stack(
          fit: StackFit.expand,
          children: [
            if (destination != null)
              IgnorePointer(
                ignoring: raw < 0.92,
                child: Opacity(
                  opacity: (0.34 + (0.66 * slide)).clamp(0.0, 1.0).toDouble(),
                  child: Transform.translate(
                    offset: Offset(0, size.height * 0.145 * (1 - slide)),
                    child: destination,
                  ),
                ),
              ),
            if (destination == null || raw < 1.0)
              IgnorePointer(
                ignoring: destination != null && raw > 0.30,
                child: Opacity(
                  opacity: (1 - overlayExit).clamp(0.0, 1.0).toDouble(),
                  child: Transform.translate(
                    offset: Offset(0, -26 * overlayExit),
                    child: _WelcomeBackLoadingScreen(
                      progress: _loaderController.value,
                      waitingForRole: _resolving,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WelcomeBackLoadingScreen extends StatelessWidget {
  const _WelcomeBackLoadingScreen({
    required this.progress,
    required this.waitingForRole,
  });

  final double progress;
  final bool waitingForRole;

  @override
  Widget build(BuildContext context) {
    final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF4FAFD),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF4FAFD),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4FAFD),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF9FCFE), Color(0xFFEEF8FC)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(0, -2.5 * pulse),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFD9EDF6)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF1784C7,
                                ).withValues(alpha: 0.09 + (0.035 * pulse)),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/isdalink_fish_mark.png',
                            width: 62,
                            height: 58,
                            fit: BoxFit.contain,
                            cacheWidth: 180,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF0B2F49),
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.55,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        waitingForRole
                            ? 'Preparing your IsdaLink home…'
                            : 'Opening your dashboard…',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF718899),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 132,
                        height: 24,
                        child: CustomPaint(
                          painter: _WaterlinePainter(progress: progress),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterlinePainter extends CustomPainter {
  const _WaterlinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = const Color(0xFFD4EBF5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = const Color(0xFF1784C7)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Path wave({required double phase, required double amplitude}) {
      final path = Path();
      const steps = 42;

      for (var i = 0; i <= steps; i++) {
        final x = size.width * i / steps;
        final y =
            size.height * 0.52 +
            math.sin((i / steps * math.pi * 2.35) + phase) * amplitude;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      return path;
    }

    canvas.drawPath(
      wave(phase: progress * math.pi * 2, amplitude: 2.7),
      basePaint,
    );

    final revealWidth = size.width * (0.30 + (0.54 * progress));
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, revealWidth, size.height));
    canvas.drawPath(
      wave(phase: progress * math.pi * 2 + 0.55, amplitude: 3.1),
      accentPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterlinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SessionErrorScreen extends StatelessWidget {
  const _SessionErrorScreen({required this.onRetry, required this.onLogout});

  final VoidCallback onRetry;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFDCE7F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BrandMark(compact: true),
                    const SizedBox(height: 20),
                    const Text(
                      'Unable to open your saved session',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF102C44),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Check your internet connection, then try again. Your account remains signed in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6F8497),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          await onLogout();
                        },
                        child: const Text('Log Out'),
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

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 58.0 : 72.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9FD),
        borderRadius: BorderRadius.circular(compact ? 17 : 20),
        border: Border.all(color: const Color(0xFFD7EAF4)),
      ),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/isdalink_fish_mark.png',
        width: compact ? 38 : 48,
        height: compact ? 36 : 44,
        fit: BoxFit.contain,
        cacheWidth: 150,
      ),
    );
  }
}

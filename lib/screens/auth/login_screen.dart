import 'package:flutter/material.dart';
import 'package:isdalink/screens/auth/register_screen.dart';
import 'package:isdalink/screens/home/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void login(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void goToRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/images/login_bg.jpg', fit: BoxFit.cover),
          ),

          // Dark overlay to make image subtle
          Positioned.fill(child: Container(color: const Color(0xCC061827))),

          // Bottom premium shadow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33102C44),
                    Color(0xDD061827),
                    Color(0xFF020712),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFF146BFF),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x73146BFF),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.set_meal,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'IsdaLink',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'FRESH CATCH, DIRECT SOURCE',
                      style: TextStyle(
                        color: Color(0xFFC9D7E5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 36),

                    TextField(
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: inputStyle(
                        hint: 'vendor@isdalink.com',
                        icon: Icons.email_outlined,
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: inputStyle(
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Forgot password coming soon'),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Color(0xFF7DB2FF),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => login(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF146BFF),
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: const Color(0x73146BFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: Color(0xFFC9D7E5),
                            fontSize: 12,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => goToRegister(context),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(
                              color: Color(0xFF7DB2FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  InputDecoration inputStyle({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCAD6E0), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFFCAD6E0)),
      filled: true,
      fillColor: const Color(0x332E4050),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x334ffffff)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF146BFF), width: 1.5),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:swiftcart/main.dart';
import '../services/auth_service.dart';
import 'dart:math' as math;

// ── SHARED LUXURY BACKGROUND PAINTER (matches home screen) ──
class SwiftCartLuxuryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFD4AF37);
    final glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.12), 160, glowPaint..color = gold.withOpacity(0.15));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.55), 200, glowPaint..color = gold.withOpacity(0.12));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.9), 140, glowPaint..color = gold.withOpacity(0.04));

    final streakPaint = Paint()..color = gold.withOpacity(0.15)..strokeWidth = 1.8..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final offset = i * 32.0;
      canvas.drawLine(Offset(size.width * 0.4 + offset, 0), Offset(size.width + 60, size.height * 0.45 + offset * 0.8), streakPaint);
    }

    final arcPaint = Paint()..color = gold.withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 2.5;
    canvas.drawArc(Rect.fromCircle(center: Offset(-30, size.height * 0.88), radius: 200), -math.pi / 2, math.pi, false, arcPaint);

    final dotPaint = Paint()..color = gold.withOpacity(0.20);
    for (double x = 18; x < size.width; x += 35) {
      for (double y = 18; y < size.height; y += 35) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields", Colors.red);
      return;
    }
    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    final user = await _auth.registerWithEmail(email, password, name);
    if (!mounted) return;

    if (user != null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation(isSellerMode: false)),
            (route) => false,
      );
      _showSnackBar("Welcome to Swift Cart, $name!", Colors.green);
    } else {
      _showSnackBar("Signup failed. Email might already be in use.", Colors.red);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnackBar(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
          backgroundColor: color == Colors.green ? const Color(0xFF1E1E1E) : color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);
    const Color charcoal = Color(0xFF0A0A0A);

    return Scaffold(
      backgroundColor: charcoal,
      body: Stack(
        children: [
          // ── LAYER 1: LUXURY PAINTER ──
          Positioned.fill(child: CustomPaint(painter: SwiftCartLuxuryPainter())),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.2))),

          // ── LAYER 2: CONTENT ──
          FadeTransition(
            opacity: _fadeIn,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: gold.withOpacity(0.8), size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  pinned: false,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 3, height: 28,
                            decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Create Account',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                              Text('Join the SwiftCart family',
                                  style: TextStyle(fontSize: 14, color: Colors.white38)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 44),

                      _buildLabel('Full Name', gold),
                      const SizedBox(height: 8),
                      _LuxuryField(controller: _nameController, hint: 'John Doe', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 20),

                      _buildLabel('Email Address', gold),
                      const SizedBox(height: 8),
                      _LuxuryField(
                        controller: _emailController,
                        hint: 'you@example.com',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Password', gold),
                      const SizedBox(height: 8),
                      _LuxuryField(
                        controller: _passwordController,
                        hint: 'Min. 6 characters',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscure: _obscurePassword,
                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 36),

                      // Security hint
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: gold.withOpacity(0.15), width: 1),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, color: gold, size: 18),
                            const SizedBox(width: 10),
                            Text('Your data is encrypted and secure.',
                                style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: charcoal,
                            disabledBackgroundColor: gold.withOpacity(0.4),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Color(0xFF0A0A0A), strokeWidth: 2.5))
                              : const Text('CREATE ACCOUNT',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2.2, color: Color(0xFF0A0A0A))),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(color: Colors.white38, fontSize: 14),
                              children: [TextSpan(text: 'Sign in',
                                  style: TextStyle(color: gold, fontWeight: FontWeight.w700))],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, Color gold) => Text(
    label,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: gold.withOpacity(0.7), letterSpacing: 0.8),
  );
}

class _LuxuryField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggle;
  final TextInputType? keyboardType;

  const _LuxuryField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscure = false,
    this.onToggle,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.15), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
          prefixIcon: Icon(icon, color: gold.withOpacity(0.5), size: 20),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: gold.withOpacity(0.4), size: 20,
            ),
            onPressed: onToggle,
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:swiftcart/main.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/cart_manager.dart';
import 'dart:math' as math;
import '../../widgets/luxury_painter.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _auth.loginWithEmail(email, password);

      if (user != null) {
        final savedCartData = await _auth.getPersistentCart(user.uid);
        List<Product> loadedProducts = savedCartData.map((item) {
          return Product.fromFirestore(item, item['id'] ?? '');
        }).toList();
        CartManager.cartNotifier.value = loadedProducts;
      }

      if (!mounted) return;

      if (user == null) {
        _showSnackBar("Invalid email or password.", Colors.red);
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      bool isSeller = false;
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('role')) {
          isSeller = data['role'] == 'seller';
        }
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainNavigation(isSellerMode: isSeller)),
            (route) => false,
      );
      _showSnackBar("Welcome back!", Colors.green);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'network-request-failed') {
        _showSnackBar("No internet connection.", Colors.orange);
      } else {
        _showSnackBar("Error: ${e.message}", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("An unexpected error occurred.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: color == Colors.green ? const Color(0xFF1E1E1E) : color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

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
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha:0.2))),

          // ── LAYER 2: CONTENT ──
          FadeTransition(
            opacity: _fadeIn,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: gold.withValues(alpha:0.8), size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                  pinned: false,
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 12),
                      // Header accent
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
                              const Text('Welcome Back',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                              Text('Sign in to continue',
                                  style: TextStyle(fontSize: 14, color: Colors.white38, fontWeight: FontWeight.w400)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      _buildFieldLabel('Email Address', gold),
                      const SizedBox(height: 8),
                      _LuxuryTextField(
                        controller: _emailController,
                        hint: 'you@example.com',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      _buildFieldLabel('Password', gold),
                      const SizedBox(height: 8),
                      _LuxuryTextField(
                        controller: _passwordController,
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscure: _obscurePassword,
                        onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () async {
                            final email = _emailController.text.trim();
                            if (email.isEmpty) {
                              _showSnackBar("Enter your email first", Colors.orange);
                              return;
                            }
                            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                            _showSnackBar("Password reset email sent!", Colors.green);
                          },
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
                          child: Text('Forgot Password?', style: TextStyle(color: gold, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor: charcoal,
                            disabledBackgroundColor: gold.withValues(alpha:0.4),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Color(0xFF0A0A0A), strokeWidth: 2.5))
                              : const Text('LOGIN',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2.8, color: Color(0xFF0A0A0A))),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withValues(alpha:0.08))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('NEW TO SWIFTCART?',
                                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(child: Divider(color: Colors.white.withValues(alpha:0.08))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Center(
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: Colors.white38, fontSize: 14),
                              children: [TextSpan(text: 'Sign up',
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

  Widget _buildFieldLabel(String label, Color gold) => Text(
    label,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: gold.withValues(alpha:0.7), letterSpacing: 0.8),
  );
}

class _LuxuryTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;

  const _LuxuryTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.obscure = false,
    this.onToggleObscure,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha:0.15), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscure,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white38, fontSize: 15, fontWeight: FontWeight.w400),
          prefixIcon: Icon(icon, color: gold.withValues(alpha:0.5), size: 20),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: gold.withValues(alpha:0.4),
              size: 20,
            ),
            onPressed: onToggleObscure,
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
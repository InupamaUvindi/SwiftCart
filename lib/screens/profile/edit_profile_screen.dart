import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../widgets/luxury_painter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (user?.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Password reset email sent!',
                style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w600)),
            backgroundColor: Color(0xFF1E1E1E),
          ));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Failed to send reset email. Try again later.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: Colors.red[900],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final ds = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .get();
    if (ds.exists && mounted) {
      setState(() {
        _nameController.text = ds.get('name') ?? '';
        _phoneController.text = ds.get('phone') ?? '';
        _emailController.text = ds.get('email') ?? user?.email ?? '';
      });
    }
  }

  void _updateProfile() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile details updated!',
              style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w600)),
          backgroundColor: Color(0xFF1E1E1E),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to update profile. Please try again.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red[900],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);
    const Color charcoal = Color(0xFF0A0A0A);

    return Scaffold(
      backgroundColor: charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: gold.withValues(alpha:0.8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'EDIT PROFILE',
          style: TextStyle(
              color: gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── LAYER 1: LUXURY PAINTER ──
          Positioned.fill(child: CustomPaint(painter: SwiftCartLuxuryPainter())),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha:0.2))),

          // ── LAYER 2: CONTENT ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Full Name', gold),
                  const SizedBox(height: 10),
                  _buildCustomField(
                    controller: _nameController,
                    hint: 'Your full name',
                    icon: Icons.person_outline_rounded,
                    gold: gold,
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Email Address', gold), // NEW EMAIL SECTION
                  const SizedBox(height: 10),
                  _buildCustomField(
                    controller: _emailController,
                    hint: 'example@mail.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    gold: gold,
                    // Optional: make read-only if you don't want them changing login email here
                    // readOnly: true,
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Phone Number', gold),
                  const SizedBox(height: 10),
                  _buildCustomField(
                    controller: _phoneController,
                    hint: '+94 7X XXX XXXX',
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                    gold: gold,
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: TextButton.icon(
                      onPressed: _changePassword,
                      icon: Icon(Icons.lock_reset_rounded, color: gold.withValues(alpha: 0.7), size: 18),
                      label: Text(
                        'CHANGE PASSWORD',
                        style: TextStyle(
                            color: gold.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        disabledBackgroundColor: gold.withValues(alpha:0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Color(0xFF0A0A0A))
                          : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                              color: Color(0xFF0A0A0A),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
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

  Widget _buildLabel(String label, Color gold) => Text(
    label,
    style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: gold.withValues(alpha:0.7)),
  );

  Widget _buildCustomField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color gold,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha:0.15), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: Icon(icon, color: gold.withValues(alpha:0.5), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
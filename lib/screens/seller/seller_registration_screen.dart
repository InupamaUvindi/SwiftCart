// seller_registration_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:math' as math;
import '../../main.dart';
import '../../widgets/luxury_painter.dart';

class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _businessLogo;
  bool _isLoading = false;

  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _storeNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _businessLogo = File(image.path));
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'role': 'seller',
          'isVerifiedSeller': true,
          'storeName': _storeNameController.text.trim(),
          'businessAddress': _addressController.text.trim(),
          'contactNumber': _phoneController.text.trim(),
          'registeredAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Registration Successful! Welcome, Seller.',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD4AF37))),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => const MainNavigation(initialIndex: 2, isSellerMode: true)),
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registration Failed: $e',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
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
          'SELLER REGISTRATION',
          style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2.5),
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
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: gold.withValues(alpha:0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.storefront_outlined, color: gold, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Register your business and start selling on SwiftCart.',
                              style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha:0.6), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Logo picker
                    GestureDetector(
                      onTap: _pickLogo,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E1E1E),
                              border: Border.all(
                                  color: _businessLogo != null ? gold.withValues(alpha:0.5) : gold.withValues(alpha:0.2),
                                  width: 2),
                              image: _businessLogo != null
                                  ? DecorationImage(image: FileImage(_businessLogo!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _businessLogo == null
                                ? Icon(Icons.storefront_outlined, size: 36, color: gold.withValues(alpha:0.6))
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFF0A0A0A)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Store Logo (optional)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 32),

                    _buildLabel('Store Name', gold),
                    const SizedBox(height: 8),
                    _buildField(_storeNameController, 'e.g. Golden Threads', Icons.storefront_outlined, gold),
                    const SizedBox(height: 20),

                    _buildLabel('Business Address', gold),
                    const SizedBox(height: 8),
                    _buildField(_addressController, 'Full business address', Icons.location_on_outlined, gold),
                    const SizedBox(height: 20),

                    _buildLabel('Contact Number', gold),
                    const SizedBox(height: 8),
                    _buildField(_phoneController, '+94 77 123 4567', Icons.phone_android_outlined, gold, isPhone: true),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submitRegistration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'REGISTER BUSINESS',
                          style: TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2),
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

  Widget _buildLabel(String label, Color gold) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      label,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: gold.withValues(alpha:0.7), letterSpacing: 0.8),
    ),
  );

  Widget _buildField(TextEditingController controller, String hint, IconData icon, Color gold, {bool isPhone = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha:0.15), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
          prefixIcon: Icon(icon, color: gold.withValues(alpha:0.5), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (val) => val!.isEmpty ? 'This field is required' : null,
      ),
    );
  }
}
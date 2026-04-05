import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _addressController.text = data['shippingAddress'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
        _cityController.text = data['city'] ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .update({
        'shippingAddress': _addressController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Shipping details saved!',
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD4AF37))),
          backgroundColor: const Color(0xFF1E1E1E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      // Error handling...
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: gold.withOpacity(0.8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SHIPPING DETAILS',
          style: TextStyle(
            color: gold,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── LAYER 1: LUXURY PAINTER ──
          Positioned.fill(child: CustomPaint(painter: SwiftCartLuxuryPainter())),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.2))),

          // ── LAYER 2: CONTENT ──
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                        border: Border.all(color: gold.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: const Icon(Icons.local_shipping_outlined, size: 36, color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 32),

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

                  _buildLabel('City / Region', gold),
                  const SizedBox(height: 10),
                  _buildCustomField(
                    controller: _cityController,
                    hint: 'e.g. Colombo',
                    icon: Icons.location_city_rounded,
                    gold: gold,
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Full Delivery Address', gold),
                  const SizedBox(height: 10),
                  _buildCustomField(
                    controller: _addressController,
                    hint: 'Street address, Apartment, etc.',
                    icon: Icons.map_rounded,
                    maxLines: 3,
                    gold: gold,
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: const Color(0xFF0A0A0A),
                        disabledBackgroundColor: gold.withOpacity(0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Color(0xFF0A0A0A))
                          : const Text(
                        'SAVE ADDRESS',
                        style: TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 2,
                        ),
                      ),
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
      color: gold.withOpacity(0.7),
      letterSpacing: 0.8,
    ),
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
        border: Border.all(color: gold.withOpacity(0.15), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: Icon(icon, color: gold.withOpacity(0.5), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
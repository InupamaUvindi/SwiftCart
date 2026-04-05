import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swiftcart/screens/auth/start_screen.dart';
import '../../main.dart';
import '../../widgets/cart_manager.dart';
import '../orders/address_screen.dart';
import 'edit_profile_screen.dart';
import '../auth/login_screen.dart';
import '../seller/seller_registration_screen.dart';
import '../chat/chat_list_screen.dart';
import '../../widgets/luxury_painter.dart';

class ProfileScreen extends StatefulWidget {
  final bool isSellerMode;
  const ProfileScreen({super.key, this.isSellerMode = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late bool _localSellerMode;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _localSellerMode = widget.isSellerMode;
  }

  Future<void> _updateProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;
    setState(() => _isUploading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${currentUser!.uid}.jpg');

      await ref.putFile(File(image.path));
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({'profileImageUrl': imageUrl});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile picture updated successfully!'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating image: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 26, height: 1.5, color: gold.withValues(alpha:0.6)),
            const SizedBox(width: 10),
            const Text(
              'MY PROFILE',
              style: TextStyle(
                color: gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 26, height: 1.5, color: gold.withValues(alpha:0.6)),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFF0A0A0A),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: SwiftCartLuxuryPainter()),
            ),

            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha:0.2)),
            ),

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data?.data() == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: gold),
                  );
                }

                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                final name = userData?['name'] ?? 'User';
                final storeName = userData?['storeName'] ?? 'My Premium Store'; //
                final email = userData?['email'] ?? currentUser?.email ?? 'No Email';
                final profileImageUrl = userData?['profileImageUrl'];

                return SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── PROFILE HERO CARD ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: gold.withValues(alpha:0.3), width: 1.0),
                            boxShadow: [
                              BoxShadow(color: gold.withValues(alpha:0.08), blurRadius: 30, spreadRadius: 2),
                              BoxShadow(color: Colors.black.withValues(alpha:0.6), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildProfileImage(profileImageUrl),
                              const SizedBox(height: 18),
                              Text(
                                _localSellerMode ? storeName.toUpperCase() : name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildEmailBadge(email, gold),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        _buildSectionHeader('BUSINESS', gold),
                        const SizedBox(height: 12),

                        // ── SELLER MODE CARD ──
                        _buildSellerToggleCard(gold),

                        const SizedBox(height: 32),
                        _buildSectionHeader('ACCOUNT', gold),
                        const SizedBox(height: 12),

                        // ── MESSAGES MENU ITEM ──
                        _MenuItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Messages',
                          subtitle: 'View your conversations',
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ChatListScreen())
                          ),
                        ),
                        const SizedBox(height: 12),

                        _MenuItem(
                          icon: Icons.edit_outlined,
                          label: 'Edit Profile',
                          subtitle: 'Update your profile',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                        ),
                        const SizedBox(height: 12),

                        // Only show Shipping Address for Buyers
                        if (!_localSellerMode)
                          _MenuItem(
                            icon: Icons.location_on_outlined,
                            label: 'Shipping Address',
                            subtitle: 'Manage delivery locations',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressScreen())),
                          ),

                        const SizedBox(height: 40),
                        _buildSignOutButton(),

                        const SizedBox(height: 24),
                        const Center(child: Text('SwiftCart  •  v1.0', style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 1.5))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProfileImage(String? imageUrl) {
    const gold = Color(0xFFD4AF37);
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gold.withValues(alpha:0.2), width: 6)),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: GestureDetector(
              onTap: _isUploading ? null : _updateProfileImage,
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF2A2A2A), border: Border.all(color: gold, width: 2)),
                child: ClipOval(
                  child: _isUploading
                      ? const Padding(padding: EdgeInsets.all(22), child: CircularProgressIndicator(color: gold, strokeWidth: 2))
                      : imageUrl != null ? Image.network(imageUrl, fit: BoxFit.cover) : const Icon(Icons.person_outline_rounded, size: 38, color: gold),
                ),
              ),
            ),
          ),
        ),
        _buildCameraButton(gold),
      ],
    );
  }

  Widget _buildCameraButton(Color gold) => GestureDetector(
    onTap: _isUploading ? null : _updateProfileImage,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: gold, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0A0A0A), width: 2)),
      child: const Icon(Icons.camera_alt, size: 12, color: Color(0xFF1A1A1A)),
    ),
  );

  Widget _buildEmailBadge(String email, Color gold) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      color: gold.withValues(alpha:0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: gold.withValues(alpha:0.3)),
    ),
    child: Text(email, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
  );

  Widget _buildSectionHeader(String title, Color gold) => Row(
    children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: gold)),
    ],
  );

  Widget _buildSellerToggleCard(Color gold) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white10),
    ),
    child: Row(
      children: [
        _buildIconBox(Icons.storefront_outlined, gold),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_localSellerMode ? 'Seller Mode: ON' : 'Seller Mode: OFF', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
              const Text('Manage your store', style: TextStyle(fontSize: 12, color: Colors.white38)),
            ],
          ),
        ),
        Switch(
          value: _localSellerMode,
          activeColor: gold,
          activeTrackColor: gold.withValues(alpha:0.3),
          onChanged: (val) async {
            if (val) {
              // ── 1. FETCH USER DATA FROM FIRESTORE ──
              DocumentSnapshot userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .get();

              if (userDoc.exists) {
                final data = userDoc.data() as Map<String, dynamic>;

                // ── 2. CHECK IF USER IS A VERIFIED SELLER ──
                bool isSeller = data['role'] == 'seller';
                bool isVerified = data['isVerifiedSeller'] ?? false;

                if (!isSeller && !isVerified) {
                  // ── 3. REDIRECT TO REGISTRATION IF NOT VERIFIED ──
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SellerRegistrationScreen(),
                      ),
                    );
                  }
                  return;
                }
              }
            }

            if (mounted) {
              setState(() => _localSellerMode = val);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => MainNavigation(
                    initialIndex: 0,
                    isSellerMode: val,
                  ),
                ),
                    (route) => false,
              );
            }
          },
        ),
      ],
    ),
  );

  Widget _buildIconBox(IconData icon, Color gold) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: gold.withValues(alpha:0.15), borderRadius: BorderRadius.circular(12)),
    child: Icon(icon, color: gold, size: 20),
  );

  Widget _buildSignOutButton() => Container(
    width: double.infinity, height: 54,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.red.withValues(alpha:0.5)),
      color: Colors.red.withValues(alpha:0.05),
    ),
    child: TextButton.icon(
      onPressed: () async {
        CartManager.clearLocalCartOnly();
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const StartScreen()),
                (
                route) => false,
          );
        }
      },
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
      label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 14)),
    ),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String label; final String subtitle; final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha:0.05)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: gold.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: gold, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)), // Pure white for text visibility
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white38)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: gold.withValues(alpha:0.5)),
          ],
        ),
      ),
    );
  }
}
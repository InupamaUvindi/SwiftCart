import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/luxury_painter.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color charcoal = Color(0xFF0A0A0A);
    const Color gold = Color(0xFFD4AF37);

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
          'ABOUT',
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
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha:0.2))),

          // ── LAYER 2: CONTENT ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Hero card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: gold.withValues(alpha:0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: gold.withValues(alpha:0.12),
                            border: Border.all(color: gold.withValues(alpha:0.3), width: 1.5),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFD4AF37), size: 32),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'SwiftCart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Empowering Small Businesses',
                          style: TextStyle(
                            color: gold.withValues(alpha:0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'SwiftCart bridges the gap between small businesses and modern customers — providing a premium mobile shopping experience that is both convenient and accessible.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha:0.55),
                            fontSize: 13,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Contact section
                  _sectionHeader('CONTACT US', gold),
                  const SizedBox(height: 14),
                  _ContactTile(
                    icon: Icons.alternate_email_rounded,
                    title: 'Email',
                    subtitle: 'support@swiftcart.com',
                    gold: gold,
                    url: 'mailto:support@swiftcart.com',
                    copyable: true,
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.phone_outlined,
                    title: 'Call',
                    subtitle: '+94 77 123 4567',
                    gold: gold,
                    url: 'tel:+94771234567',
                    copyable: true,
                  ),
                  const SizedBox(height: 10),
                  _ContactTile(
                    icon: Icons.location_on_outlined,
                    title: 'Visit',
                    subtitle: '123/B, Homagama',
                    gold: gold,
                    url: 'https://www.google.com/maps/search/?api=1&query=Homagama,Sri+Lanka',
                    copyable: false,
                  ),
                  const SizedBox(height: 32),

                  // Socials
                  _sectionHeader('FOLLOW US', gold),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialBtn(icon: Icons.facebook, gold: gold),
                      const SizedBox(width: 14),
                      _SocialBtn(icon: Icons.camera_alt_outlined, gold: gold),
                      const SizedBox(width: 14),
                      _SocialBtn(icon: Icons.language, gold: gold),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Version
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(color: Colors.white.withValues(alpha:0.3), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2026 SwiftCart. All rights reserved.',
                    style: TextStyle(color: Colors.white.withValues(alpha:0.2), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color gold) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: gold)),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color gold;
  final String url;
  final bool copyable;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gold,
    required this.url,
    required this.copyable,
  });

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open $title'),
          backgroundColor: Colors.red[900],
        ),
      );
    }
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: subtitle));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title copied to clipboard'),
        backgroundColor: const Color(0xFF2A2A2A),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launch(context),
      onLongPress: copyable ? () => _copy(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: gold, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                if (copyable)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.copy_rounded, size: 13, color: gold.withValues(alpha: 0.35)),
                  ),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: gold.withValues(alpha: 0.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final Color gold;
  const _SocialBtn({required this.icon, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        shape: BoxShape.circle,
        border: Border.all(color: gold.withValues(alpha:0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Icon(icon, color: gold, size: 22),
    );
  }
}
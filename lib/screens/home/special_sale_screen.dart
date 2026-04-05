// special_sale_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftcart/models/product.dart';
import 'package:swiftcart/screens/home/product_detail_screen.dart';
import 'dart:math' as math;
import '../../widgets/luxury_painter.dart';

class SpecialSaleScreen extends StatelessWidget {
  final String saleTitle;
  const SpecialSaleScreen({super.key, required this.saleTitle});

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
          saleTitle.toUpperCase(),
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
          SafeArea(
            child: Column(
              children: [
                // Sale banner strip
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: gold.withValues(alpha:0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined, color: gold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Limited time deals — grab them before they\'re gone!',
                          style: TextStyle(color: Colors.white.withValues(alpha:0.7), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .where('isOnSale', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading sale items.', style: TextStyle(color: Colors.white38)));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 88, height: 88,
                                decoration: BoxDecoration(
                                  color: gold.withValues(alpha:0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: gold.withValues(alpha:0.15)),
                                ),
                                child: Icon(Icons.local_offer_outlined, size: 40, color: gold.withValues(alpha:0.5)),
                              ),
                              const SizedBox(height: 18),
                              const Text('No sale items right now',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(height: 6),
                              Text('Check back soon for special deals!',
                                  style: TextStyle(color: Colors.white38, fontSize: 13)),
                            ],
                          ),
                        );
                      }

                      final saleItems = docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Product.fromFirestore(data, doc.id);
                      }).toList();

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: saleItems.length,
                        itemBuilder: (context, i) => _SaleCard(product: saleItems[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final Product product;
  const _SaleCard({required this.product});

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);
    const Color charcoal = Color(0xFF0A0A0A);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: gold.withValues(alpha:0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: product.imageUrl.startsWith('http')
                        ? Image.network(product.imageUrl, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white24))
                        : Image.asset(product.imageUrl, fit: BoxFit.contain),
                  ),
                ),
                // Sale badge
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                    child: const Text('SALE',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
              child: Text(product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (product.isOnSale && product.salePrice != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Rs. ${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.white38,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Rs. ${product.salePrice!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('Rs. ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold.withValues(alpha:0.15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Grab Deal',
                      style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
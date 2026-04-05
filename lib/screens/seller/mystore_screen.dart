// mystore_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swiftcart/models/product.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'dart:math' as math;
import '../../widgets/luxury_painter.dart';

class MyStoreScreen extends StatelessWidget {
  const MyStoreScreen({super.key});

  // ── Fetch sold units, order count, and revenue for this seller ──
  Future<Map<String, dynamic>> _fetchStats(String sellerId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('sellerIds', arrayContains: sellerId)
        .get();

    int totalSold = 0;
    double totalRevenue = 0.0;
    final int totalOrders = snapshot.docs.length;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      for (final item in items) {
        if (item['sellerId'] == sellerId) {
          final qty = (item['quantity'] as int?) ?? 1;
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          totalSold += qty;
          totalRevenue += price * qty;
        }
      }
    }

    return {
      'sold': totalSold,
      'revenue': totalRevenue,
      'orders': totalOrders,
    };
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);
    const Color charcoal = Color(0xFF0A0A0A);
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MY STORE',
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: gold,
        elevation: 4,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const AddProductScreen()),
        ),
        child: const Icon(Icons.add, color: Color(0xFF0A0A0A)),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: SwiftCartLuxuryPainter())),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha:0.2))),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('sellerId', isEqualTo: currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Error loading inventory',
                        style: TextStyle(color: Colors.white38)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
              }

              final docs = snapshot.data?.docs ?? [];

              return SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── STATS CARD (live from Firestore) ──
                      FutureBuilder<Map<String, dynamic>>(
                        future: _fetchStats(currentUser?.uid ?? ''),
                        builder: (context, statsSnap) {
                          final sold = statsSnap.data?['sold'] ?? 0;
                          final revenue = (statsSnap.data?['revenue'] ?? 0.0) as double;
                          final orders = statsSnap.data?['orders'] ?? 0;
                          final loading = statsSnap.connectionState == ConnectionState.waiting;

                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: gold.withValues(alpha:0.15)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha:0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8))
                              ],
                            ),
                            child: loading
                                ? const Center(
                              child: SizedBox(
                                height: 44,
                                child: CircularProgressIndicator(
                                    color: Color(0xFFD4AF37),
                                    strokeWidth: 2),
                              ),
                            )
                                : Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                                  children: [
                                    _StatItem(
                                        value: '${docs.length}',
                                        label: 'Active',
                                        gold: gold),
                                    Container(
                                        width: 1,
                                        height: 36,
                                        color: gold.withValues(alpha:0.15)),
                                    _StatItem(
                                        value: '$orders',
                                        label: 'Orders',
                                        gold: gold),
                                    Container(
                                        width: 1,
                                        height: 36,
                                        color: gold.withValues(alpha:0.15)),
                                    _StatItem(
                                        value: '$sold',
                                        label: 'Sold',
                                        gold: gold),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                    height: 1,
                                    color: gold.withValues(alpha:0.08)),
                                const SizedBox(height: 20),

                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TOTAL REVENUE',
                                          style: TextStyle(
                                              color: Colors.white38,
                                              fontSize: 10,
                                              fontWeight:
                                              FontWeight.w700,
                                              letterSpacing: 1.5),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Rs. ${revenue.toStringAsFixed(2)}',
                                          style: TextStyle(
                                              color: gold,
                                              fontSize: 26,
                                              fontWeight:
                                              FontWeight.w900,
                                              letterSpacing: -0.5),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: gold.withValues(alpha:0.1),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                          Icons.trending_up_rounded,
                                          color: gold,
                                          size: 22),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // ── SECTION HEADER ──
                      Row(
                        children: [
                          Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                  color: gold,
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text('MY LISTINGS',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.5,
                                  color: gold)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── PRODUCT GRID ──
                      if (docs.isEmpty)
                        _buildEmptyState(gold)
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final data =
                            docs[i].data() as Map<String, dynamic>;
                            final p = Product(
                              id: docs[i].id,
                              name: data['name'] ?? 'No Name',
                              price: (data['price'] ?? 0).toDouble(),
                              description: data['description'] ?? '',
                              imageUrl: data['imageUrl'] ?? 'assets/sw.jpg',
                              category: data['category'] ?? 'General',
                              sellerId: data['sellerId'] ?? '',
                              sellerName: data['sellerName'] ?? 'Premium Store',
                              stock: (data['stock'] as int?) ?? 0,
                              isOnSale: data['isOnSale'] ?? false,
                              discountPercent: (data['discountPercent'] ?? 0).toDouble(),
                            );
                            return _StoreItem(
                              product: p,
                              gold: gold,
                              onEdit: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => EditProductScreen(product: p)),
                              ),
                              onDelete: () => _confirmDelete(context, p.id),
                              onMarkSale: () => _showSaleDialog(context, p),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color gold) => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: gold.withValues(alpha:0.08),
              shape: BoxShape.circle,
              border: Border.all(color: gold.withValues(alpha:0.15)),
            ),
            child: Icon(Icons.storefront_outlined, size: 36, color: gold.withValues(alpha:0.5)),
          ),
          const SizedBox(height: 16),
          const Text("No listings yet",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 6),
          Text("Tap + to add your first product",
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    ),
  );

  void _confirmDelete(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product?',
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        content: Text('This action cannot be undone.',
            style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').doc(productId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSaleDialog(BuildContext context, Product product) {
    const Color gold = Color(0xFFD4AF37);
    final discountController = TextEditingController(
      text: product.isOnSale ? product.discountPercent.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final discountVal = double.tryParse(discountController.text) ?? 0;
          final salePrice = product.price - (product.price * discountVal / 100);

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: Row(
              children: [
                Icon(Icons.local_offer_rounded, color: gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  product.isOnSale ? 'EDIT SALE' : 'MARK AS SALE',
                  style: const TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 13,
                      fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Original Price: Rs. ${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 16),
                Text('Discount %',
                    style: TextStyle(color: gold.withValues(alpha:0.7),
                        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: gold.withValues(alpha:0.2)),
                  ),
                  child: TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'e.g. 20',
                      hintStyle: TextStyle(color: Colors.white24),
                      suffixText: '%',
                      suffixStyle: TextStyle(color: gold, fontWeight: FontWeight.w900),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (_) => setDlgState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                if (discountVal > 0 && discountVal < 100)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha:0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha:0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Sale Price', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('Rs. ${salePrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 15)),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              if (product.isOnSale)
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(product.id)
                        .update({'isOnSale': false, 'discountPercent': 0, 'salePrice': null});
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Remove Sale', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700)),
                ),
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: Colors.white38))),
              ElevatedButton(
                onPressed: () async {
                  final d = double.tryParse(discountController.text.trim()) ?? 0;
                  if (d <= 0 || d >= 100) return;
                  final computed = double.parse(
                      (product.price - product.price * d / 100).toStringAsFixed(2));
                  await FirebaseFirestore.instance
                      .collection('products')
                      .doc(product.id)
                      .update({
                    'isOnSale': true,
                    'discountPercent': d,
                    'salePrice': computed,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('Apply Sale',
                    style: TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StoreItem extends StatelessWidget {
  final Product product;
  final Color gold;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMarkSale;

  const _StoreItem({
    required this.product,
    required this.gold,
    required this.onEdit,
    required this.onDelete,
    required this.onMarkSale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: product.isOnSale ? gold.withValues(alpha:0.4) : gold.withValues(alpha:0.1),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF2A2A2A),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: product.imageUrl.startsWith('http')
                          ? Image.network(product.imageUrl, fit: BoxFit.contain)
                          : Image.asset(product.imageUrl, fit: BoxFit.contain),
                    ),
                  ),
                  // Sale badge on image
                  if (product.isOnSale)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${product.discountPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
            child: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          if (product.isOnSale && product.salePrice != null) ...[
            Text(
              'Rs. ${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white38, fontSize: 11,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: Colors.white38),
            ),
            Text(
              'Rs. ${product.salePrice!.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ] else
            Text(
              'Rs. ${product.price.toStringAsFixed(2)}',
              style: TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: product.stock > 0
                  ? Colors.greenAccent.withValues(alpha:0.10)
                  : Colors.redAccent.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: product.stock > 0
                    ? Colors.greenAccent.withValues(alpha:0.35)
                    : Colors.redAccent.withValues(alpha:0.35),
              ),
            ),
            child: Text(
              product.stock > 0 ? 'Stock: ${product.stock}' : 'Out of Stock',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: product.stock > 0 ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              children: [
                Expanded(child: _ActionBtn(icon: Icons.edit_outlined, color: Colors.lightBlueAccent, onTap: onEdit)),
                const SizedBox(width: 8),
                Expanded(child: _ActionBtn(icon: Icons.delete_outline_rounded, color: Colors.redAccent, onTap: onDelete)),
              ],
            ),
          ),
          // Sale button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: GestureDetector(
              onTap: onMarkSale,
              child: Container(
                width: double.infinity,
                height: 30,
                decoration: BoxDecoration(
                  color: product.isOnSale
                      ? Colors.red.withValues(alpha:0.12)
                      : gold.withValues(alpha:0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: product.isOnSale
                        ? Colors.red.withValues(alpha:0.4)
                        : gold.withValues(alpha:0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      product.isOnSale ? Icons.local_offer_rounded : Icons.local_offer_outlined,
                      size: 12,
                      color: product.isOnSale ? Colors.redAccent : gold,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      product.isOnSale ? 'Edit Sale' : 'Mark as Sale',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: product.isOnSale ? Colors.redAccent : gold,
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
}


class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color gold;

  const _StatItem({required this.value, required this.label, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

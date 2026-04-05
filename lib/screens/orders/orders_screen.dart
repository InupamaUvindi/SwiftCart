import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import '../../widgets/luxury_painter.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);
    const Color charcoal = Color(0xFF0A0A0A);
    final user = FirebaseAuth.instance.currentUser;

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
          'MY ORDERS',
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('userId', isEqualTo: user?.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error loading orders.", style: TextStyle(color: Colors.white38)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
              }

              final orders = snapshot.data?.docs ?? [];

              if (orders.isEmpty) {
                return _buildEmptyState(gold);
              }

              return SafeArea(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final data = orders[i].data() as Map<String, dynamic>;
                    return _buildOrderCard(orders[i].id, data, gold);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color gold) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: gold.withValues(alpha:0.08),
              shape: BoxShape.circle,
              border: Border.all(color: gold.withValues(alpha:0.15)),
            ),
            child: Icon(Icons.shopping_bag_outlined, size: 40, color: gold.withValues(alpha:0.5)),
          ),
          const SizedBox(height: 18),
          const Text('No orders yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Your placed orders will appear here.',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> data, Color gold) {
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final total = (data['total'] ?? 0.0).toDouble();
    final status = (data['status'] ?? 'placed').toLowerCase();
    final shortId = orderId.substring(0, 6).toUpperCase();
    final itemCount = items.fold<int>(0, (sum, i) => sum + ((i['quantity'] as int?) ?? 1));

    Color statusColor = Colors.orange;
    if (status == 'delivered') statusColor = Colors.greenAccent;
    else if (status == 'shipped') statusColor = Colors.lightBlueAccent;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha:0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: gold.withValues(alpha:0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.local_shipping_outlined, color: gold, size: 22),
          ),
          title: Text(
            'Order #$shortId',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status[0].toUpperCase() + status.substring(1),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs. ${total.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.w900, color: gold, fontSize: 14)),
              const SizedBox(height: 2),
              Text('$itemCount item${itemCount != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          iconColor: gold,
          collapsedIconColor: gold.withValues(alpha:0.5),
          children: [
            Divider(thickness: 1, color: gold.withValues(alpha:0.08), indent: 18, endIndent: 18),
            ...items.map((item) => _buildOrderItem(item, gold)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, Color gold) {
    final imageUrl = item['imageUrl'] ?? item['image'] ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gold.withValues(alpha:0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.startsWith('http')
                    ? Image.network(imageUrl, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, size: 20, color: Colors.white24))
                    : Image.asset(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Qty: ${item['quantity']}  ·  Rs. ${(item['price'] as num).toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
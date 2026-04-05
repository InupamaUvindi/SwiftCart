// seller_order_detail_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/luxury_painter.dart';

class SellerOrderDetailScreen extends StatelessWidget {
  final String orderId;
  final String buyerEmail;
  final double total;
  final String paymentMethod;
  final String status;
  final List<Map<String, dynamic>> items;

  const SellerOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.buyerEmail,
    required this.total,
    required this.paymentMethod,
    required this.status,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);
    const Color charcoal = Color(0xFF0A0A0A);

    final shortId = orderId.length >= 6 ? orderId.substring(0, 6).toUpperCase() : orderId.toUpperCase();

    Color statusColor = Colors.orange;
    if (status == 'delivered') statusColor = Colors.greenAccent;
    else if (status == 'shipped') statusColor = Colors.lightBlueAccent;

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
          'ORDER #$shortId',
          style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3),
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
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── ORDER SUMMARY CARD ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gold.withValues(alpha:0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // New sale badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: gold.withValues(alpha:0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: gold.withValues(alpha:0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.star_rounded, color: gold, size: 12),
                                  const SizedBox(width: 4),
                                  Text('NEW SALE', style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                ],
                              ),
                            ),
                            // Status badge
                            Container(
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
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Total
                        Text('TOTAL EARNED', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Text('Rs. ${total.toStringAsFixed(2)}',
                            style: TextStyle(color: gold, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 20),

                        Divider(color: gold.withValues(alpha:0.08)),
                        const SizedBox(height: 14),

                        // Buyer info row
                        _infoRow(Icons.person_outline_rounded, 'Buyer', buyerEmail, gold),
                        const SizedBox(height: 12),
                        _infoRow(Icons.payment_rounded, 'Payment', paymentMethod, gold),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Container(width: 3, height: 14, decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 8),
                      Text('ITEMS PURCHASED',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: gold)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  ...items.map((item) => _buildOrderItem(item, gold)),

                  const SizedBox(height: 28),

                  // ── TOTAL BREAKDOWN ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: gold.withValues(alpha:0.1)),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Items', items.fold<int>(0, (s, i) => s + ((i['quantity'] as int?) ?? 1)).toString(), gold),
                        const SizedBox(height: 10),
                        Divider(color: gold.withValues(alpha:0.08)),
                        const SizedBox(height: 10),
                        _summaryRow('Total', 'Rs. ${total.toStringAsFixed(2)}', gold, isTotal: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color gold) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: gold.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: gold, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, Color gold) {
    final imageUrl = item['imageUrl'] ?? item['image'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha:0.08)),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 64,
            height: 64,
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
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Qty: ${item['quantity']}',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          // Price
          Text('Rs. ${(item['price'] as num).toStringAsFixed(2)}',
              style: TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color gold, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
            color: isTotal ? Colors.white : Colors.white38,
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500)),
        Text(value, style: TextStyle(
            color: isTotal ? gold : Colors.white,
            fontSize: isTotal ? 18 : 13,
            fontWeight: FontWeight.w900)),
      ],
    );
  }
}

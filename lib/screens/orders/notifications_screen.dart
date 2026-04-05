// notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart';
import '../../widgets/luxury_painter.dart';
import '../seller/seller_order_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
          'NOTIFICATIONS',
          style: TextStyle(
            color: gold,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _markAllRead(user?.uid),
            child: Text('Mark all read',
                style: TextStyle(color: gold.withValues(alpha:0.7), fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
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
                .collection('notifications')
                .where('userId', isEqualTo: user?.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text("Error loading notifications.",
                        style: TextStyle(color: Colors.white38)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
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
                        child: Icon(Icons.notifications_none_outlined,
                            size: 40, color: gold.withValues(alpha:0.5)),
                      ),
                      const SizedBox(height: 18),
                      const Text('No notifications yet',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('You\'re all caught up!',
                          style: TextStyle(color: Colors.white38, fontSize: 13)),
                    ],
                  ),
                );
              }

              return SafeArea(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _buildTile(context, docs[i].id, data, gold);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildTile(BuildContext context, String docId, Map<String, dynamic> data, Color gold) {
    final isRead = data['isRead'] ?? false;
    final type = data['type'] ?? 'general';
    final senderId = data['senderId'];
    final senderName = data['title']?.replaceAll('New Message from ', '') ?? 'User';

    IconData icon = Icons.notifications_outlined;
    if (type == 'order_update') icon = Icons.shopping_bag_outlined;
    if (type == 'order_sale' || type == 'sale') icon = Icons.local_offer_outlined;
    if (type == 'message') icon = Icons.chat_bubble_outline_rounded;

    return GestureDetector(
      onTap: () {
        _markRead(docId);

        // ── Navigate to ChatScreen if it's a message notification ──
        if (type == 'message' && senderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                receiverId: senderId,
                receiverName: senderName,
              ),
            ),
          );
        }

        // ── Navigate to SellerOrderDetailScreen if it's a sale notification ──
        if (type == 'order_sale') {
          try {
            final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SellerOrderDetailScreen(
                      orderId: data['orderId'] ?? docId,
                      buyerEmail: data['buyerEmail'] ?? 'Unknown',
                      total: (data['total'] ?? 0.0).toDouble(),
                      paymentMethod: data['paymentMethod'] ?? 'Unknown',
                      status: data['status'] ?? 'placed',
                      items: items,
                    ),
              ),
            );
          }
          catch (e) {
            print("Navigation Error: $e");
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? gold.withValues(alpha:0.1) : gold.withValues(alpha:0.4),
            width: 1.5,
          ),
          boxShadow: [
            if (!isRead)
              BoxShadow(color: gold.withValues(alpha:0.05), blurRadius: 15, spreadRadius: 2)
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: gold.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: gold, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w900,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['body'] ?? '',
                    style: TextStyle(color: Colors.white.withValues(alpha:0.4), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: gold,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: gold.withValues(alpha:0.5), blurRadius: 8)]),
              ),
          ],
        ),
      ),
    );
  }

  void _markRead(String docId) {
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  void _markAllRead(String? uid) {
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get()
        .then((snap) {
      for (var doc in snap.docs) {
        doc.reference.update({'isRead': true});
      }
    });
  }
}
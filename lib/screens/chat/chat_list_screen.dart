import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'dart:math' as math;
import 'package:swiftcart/widgets/luxury_painter.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);
    const Color charcoal = Color(0xFF0A0A0A);
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: gold.withValues(alpha:0.8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MESSAGES',
          style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: SwiftCartLuxuryPainter())),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha:0.2))),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chat_rooms')
                .where('participants', arrayContains: currentUserId)
                .orderBy('lastTimestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: gold));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return _buildEmptyState(gold);
              }

              return SafeArea(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildChatTile(context, docs[index], currentUserId, gold);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, DocumentSnapshot doc, String currentUserId, Color gold) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List participants = data['participants'] ?? [];
    String otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
    String otherUserName = data['names'][otherUserId] ?? 'User';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(receiverId: otherUserId, receiverName: otherUserName),
      )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: gold.withValues(alpha:0.15), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: gold.withValues(alpha:0.1),
                shape: BoxShape.circle,
                border: Border.all(color: gold.withValues(alpha:0.3)),
              ),
              child: Icon(Icons.person_outline_rounded, color: gold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['lastMessage'] ?? 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha:0.4), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: gold.withValues(alpha:0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color gold) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline_rounded, size: 60, color: gold.withValues(alpha:0.2)),
        const SizedBox(height: 16),
        const Text("No conversations yet", style: TextStyle(color: Colors.white38, fontSize: 14)),
      ],
    ),
  );
}
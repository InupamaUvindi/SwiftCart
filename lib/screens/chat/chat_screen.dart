import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../widgets/luxury_painter.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      String currentUserId = _auth.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      final data = userDoc.data() as Map<String, dynamic>?;
      final myName = data?['storeName'] ?? data?['name'] ?? 'User';

      List<String> ids = [currentUserId, widget.receiverId];
      ids.sort();
      String chatRoomId = ids.join("_");

      await FirebaseFirestore.instance.collection('chat_rooms').doc(chatRoomId).set({
        'participants': ids,
        'lastMessage': _messageController.text,
        'lastTimestamp': Timestamp.now(),
        'names': {
          currentUserId: myName,
          widget.receiverId: widget.receiverName,
        }
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'receiverId': widget.receiverId,
        'message': _messageController.text,
        'timestamp': Timestamp.now(),
      });

      await _sendNotification(myName, _messageController.text);
      _messageController.clear();
    }
  }

  Future<void> _sendNotification(String senderName, String messageContent) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': widget.receiverId,
      'title': 'New Message from $senderName',
      'body': messageContent,
      'type': 'message',
      'senderId': _auth.currentUser!.uid,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: gold.withValues(alpha:0.8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.receiverName.toUpperCase(),
          style: const TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3),
        ),
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
                Expanded(child: _buildMessageList()),
                _buildMessageInput(gold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    String currentUserId = _auth.currentUser!.uid;
    List<String> ids = [currentUserId, widget.receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));

        return ListView(
          reverse: true,
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc, currentUserId)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc, String currentUserId) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isMe = data['senderId'] == currentUserId;
    const Color gold = Color(0xFFD4AF37);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? gold : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          border: isMe ? null : Border.all(color: gold.withValues(alpha:0.15), width: 1.2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha:0.2), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Text(
          data['message'],
          style: TextStyle(
            color: isMe ? const Color(0xFF0A0A0A) : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(Color gold) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withValues(alpha:0.15), width: 1.5),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded, color: gold.withValues(alpha:0.5), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: gold,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: gold.withValues(alpha:0.2), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.send_rounded, color: Color(0xFF0A0A0A), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
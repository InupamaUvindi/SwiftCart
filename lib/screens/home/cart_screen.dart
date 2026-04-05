import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swiftcart/widgets/cart_manager.dart';
import 'package:swiftcart/services/stripe_service.dart';
import 'package:swiftcart/services/payhere_service.dart';
import '../../models/product.dart';
import '../../widgets/luxury_painter.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const Color gold = Color(0xFFD4AF37);
  static const Color charcoal = Color(0xFF0A0A0A);
  bool _isPlacingOrder = false;

  // --- PAYMENT LOGIC (UNCHANGED) ---
  Future<void> _handleStripeCheckout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isPlacingOrder = true);
    try {
      final stockError = await _validateStock();
      if (stockError != null) { _showError(stockError); return; }
      final totalLKR = CartManager.getTotalPrice();
      final paymentSuccess = await StripeService.makePayment(amountLKR: totalLKR, context: context);
      if (paymentSuccess && mounted) {
        await _deductStock();
        await _saveOrderToFirestore(user, totalLKR, method: 'Card (Stripe)');
        CartManager.clearCartCompletely();
        _showSuccessDialog();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  Future<void> _handlePayhereCheckout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isPlacingOrder = true);
    try {
      final stockError = await _validateStock();
      if (stockError != null) { _showError(stockError); setState(() => _isPlacingOrder = false); return; }
      final totalLKR = CartManager.getTotalPrice();
      final displayName = user.displayName ?? 'Customer';
      final nameParts = displayName.split(' ');
      await PayhereService.makePayment(
        amount: totalLKR,
        orderId: PayhereService.generateOrderId(),
        customerFirstName: nameParts.first,
        customerLastName: nameParts.length > 1 ? nameParts.last : 'N/A',
        customerEmail: user.email ?? '',
        customerPhone: '0771234567',
        onSuccess: () async {
          await _deductStock();
          await _saveOrderToFirestore(user, totalLKR, method: 'Card (PayHere)');
          CartManager.clearCartCompletely();
          if (mounted) { _showSuccessDialog(); setState(() => _isPlacingOrder = false); }
        },
        onError: (err) { _showError(err); setState(() => _isPlacingOrder = false); },
        onDismissed: () => setState(() => _isPlacingOrder = false),
      );
    } catch (e) {
      _showError(e.toString());
      setState(() => _isPlacingOrder = false);
    }
  }

  Future<void> _handleCashOnDelivery() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isPlacingOrder = true);
    try {
      final stockError = await _validateStock();
      if (stockError != null) { _showError(stockError); return; }
      await _deductStock();
      await _saveOrderToFirestore(user, CartManager.getTotalPrice(), method: 'Cash on Delivery');
      CartManager.clearCartCompletely();
      if (mounted) _showSuccessDialog();
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  Future<String?> _validateStock() async {
    final cartItems = CartManager.cartNotifier.value;
    for (final item in cartItems) {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(item.id)
          .get();
      if (!doc.exists) return '"${item.name}" is no longer available.';
      final available = (doc.data()?['stock'] as int?) ?? 0;
      if (item.quantity > available) {
        return '"${item.name}" only has $available item${available == 1 ? '' : 's'} left in stock.';
      }
    }
    return null;
  }


  Future<void> _deductStock() async {
    final cartItems = CartManager.cartNotifier.value;
    final batch = FirebaseFirestore.instance.batch();
    for (final item in cartItems) {
      final ref = FirebaseFirestore.instance.collection('products').doc(item.id);
      batch.update(ref, {'stock': FieldValue.increment(-item.quantity)});
    }
    await batch.commit();
  }


  Future<void> _saveOrderToFirestore(User user, double totalLKR, {String method = 'Card (Stripe)'}) async {
    final cartItems = CartManager.cartNotifier.value;
    final sellerIds = cartItems.map((item) => item.sellerId).toSet().toList();
    final orderRef = await FirebaseFirestore.instance.collection('orders').add({
      'userId': user.uid,
      'userEmail': user.email,
      'sellerIds': sellerIds,
      'total': totalLKR,
      'status': 'placed',
      'paymentMethod': method,
      'createdAt': FieldValue.serverTimestamp(),
      'items': cartItems.map((item) => item.toMap()).toList(),
    });

    for (final sellerId in sellerIds) {
      final sellerItems = cartItems
          .where((item) => item.sellerId == sellerId)
          .map((item) => item.toMap())
          .toList();

      final sellerTotal = cartItems
          .where((item) => item.sellerId == sellerId)
          .fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': sellerId,
        'title': 'New Sale!',
        'body': '${sellerItems.length} item${sellerItems.length != 1 ? 's' : ''} sold · Rs. ${sellerTotal.toStringAsFixed(2)}',
        'type': 'order_sale',
        'orderId': orderRef.id,
        'buyerEmail': user.email,
        'total': sellerTotal,
        'paymentMethod': method,
        'status': 'placed',
        'items': sellerItems,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[900]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('MY CART',
            style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3)),
        actions: [
          ValueListenableBuilder<List<Product>>(
            valueListenable: CartManager.cartNotifier,
            builder: (_, cart, __) => cart.isEmpty
                ? const SizedBox()
                : TextButton(
              onPressed: () => CartManager.clearLocalCartOnly(),
              child: Text('Clear', style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
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
          _isPlacingOrder
              ? const Center(child: CircularProgressIndicator(color: gold))
              : ValueListenableBuilder<List<Product>>(
            valueListenable: CartManager.cartNotifier,
            builder: (context, currentCartItems, child) {
              if (currentCartItems.isEmpty) return _buildEmptyState();

              return SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: currentCartItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => _buildCartItem(currentCartItems[i], i),
                      ),
                    ),
                    _buildCheckoutSection(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
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
          child: Icon(Icons.shopping_bag_outlined, size: 40, color: gold.withValues(alpha:0.5)),
        ),
        const SizedBox(height: 18),
        const Text('Your cart is empty',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 6),
        Text('Add products to get started', style: TextStyle(fontSize: 13, color: Colors.white38)),
      ],
    ),
  );

  Widget _buildCartItem(Product item, int index) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: gold.withValues(alpha:0.08)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.2), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Row(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gold.withValues(alpha:0.1))),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: item.imageUrl.startsWith('http')
                  ? Image.network(item.imageUrl, fit: BoxFit.contain)
                  : Image.asset(item.imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              // Show strikethrough + sale price if on sale, else normal price
              if (item.isOnSale && item.salePrice != null) ...[
                Text(
                  "Rs. ${item.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.white38,
                  ),
                ),
                Text(
                  "Rs. ${item.salePrice!.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ] else
                Text("Rs. ${item.price.toStringAsFixed(2)}",
                    style: const TextStyle(color: gold, fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _qtyBtn(Icons.remove, () => CartManager.decrementQuantity(index)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text("${item.quantity}",
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  _qtyBtn(Icons.add, () => CartManager.incrementQuantity(index, maxStock: item.stock)),
                ],
              )
            ],
          ),
        ),
        IconButton(
          onPressed: () => CartManager.removeFromCart(index),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha:0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
          ),
        ),
      ],
    ),
  );

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: gold.withValues(alpha:0.2), width: 1.5),
          color: const Color(0xFF2A2A2A)),
      child: Icon(icon, size: 12, color: gold),
    ),
  );

  Widget _buildCheckoutSection() => Container(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
    decoration: BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      border: Border(top: BorderSide(color: gold.withValues(alpha:0.15))),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.4), blurRadius: 25, offset: const Offset(0, -8))],
    ),
    child: Column(
      children: [
        _summaryRow("Subtotal", "Rs. ${CartManager.getTotalPrice().toStringAsFixed(2)}", false),
        const SizedBox(height: 10),
        _summaryRow("Delivery", "Free", false, valueColor: Colors.greenAccent),
        const SizedBox(height: 16),
        Divider(thickness: 1, color: gold.withValues(alpha:0.1)),
        const SizedBox(height: 16),
        _summaryRow("Total Payment", "Rs. ${CartManager.getTotalPrice().toStringAsFixed(2)}", true),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _showPaymentOptions(),
            style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text("PROCEED TO CHECKOUT",
                style: TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
          ),
        ),
      ],
    ),
  );

  Widget _summaryRow(String label, String value, bool isTotal, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
          color: isTotal ? Colors.white : Colors.white38)),
      Text(value, style: TextStyle(
          fontSize: isTotal ? 20 : 14,
          fontWeight: FontWeight.w900,
          color: valueColor ?? (isTotal ? gold : Colors.white))),
    ],
  );

  void _showPaymentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: gold.withValues(alpha:0.3), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            Text("SELECT PAYMENT METHOD",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: gold)),
            const SizedBox(height: 24),
            _methodTile("Credit / Debit Card (Stripe)", "International payment", Icons.credit_card,
                    () { Navigator.pop(context); _handleStripeCheckout(); }),
            _methodTile("PayHere (Sri Lanka)", "Local cards & LKR", Icons.account_balance_wallet,
                    () { Navigator.pop(context); _handlePayhereCheckout(); }),
            _methodTile("Cash on Delivery", "Pay at your doorstep", Icons.delivery_dining,
                    () { Navigator.pop(context); _handleCashOnDelivery(); }),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(String title, String sub, IconData icon, VoidCallback onTap) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: gold.withValues(alpha:0.12), shape: BoxShape.circle),
      child: Icon(icon, color: gold, size: 22),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
    subtitle: Text(sub, style: TextStyle(fontSize: 12, color: Colors.white38)),
    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: gold.withValues(alpha:0.5)),
    onTap: onTap,
  );

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha:0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 60),
            ),
            const SizedBox(height: 20),
            const Text("Order Confirmed",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white)),
            const SizedBox(height: 10),
            Text("Your jewelry is on its way!",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("CONTINUE SHOPPING",
                    style: TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
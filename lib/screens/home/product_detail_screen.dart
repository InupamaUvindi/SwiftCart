import 'package:flutter/material.dart';
import 'package:swiftcart/models/product.dart';
import 'package:swiftcart/screens/seller/mystore_screen.dart';
import '../../widgets/cart_manager.dart';
import '../chat/chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  String? _selectedSize;
  String? _selectedColor;

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);
    const Color charcoal = Color(0xFF0A0A0A);

    return Scaffold(
      backgroundColor: charcoal,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageHeader(context, gold, charcoal),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha:0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: gold.withValues(alpha:0.2)),
                        ),
                        child: Text(
                          widget.product.category.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Name
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Price — show sale price if on sale
                      if (widget.product.isOnSale && widget.product.salePrice != null) ...[
                        Text(
                          'Rs. ${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white38,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Rs. ${widget.product.salePrice!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.greenAccent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${widget.product.discountPercent.toStringAsFixed(0)}% OFF',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Text(
                          'Rs. ${widget.product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // ── NEW: SELLER STORE CARD ──
                      _buildStoreCard(gold),
                      const SizedBox(height: 24),

                      Divider(color: Colors.white.withValues(alpha:0.08), thickness: 1.5),
                      const SizedBox(height: 20),

                      // Description
                      _buildSectionHeader('DESCRIPTION', gold),
                      const SizedBox(height: 10),
                      Text(
                        widget.product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha:0.55),
                          height: 1.65,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 28),

                      Divider(color: Colors.white.withValues(alpha:0.08), thickness: 1.5),
                      const SizedBox(height: 20),

                      // ── SIZE PICKER (Clothes & Shoes) ──
                      if ((widget.product.category == 'Clothes' || widget.product.category == 'Shoes') &&
                          widget.product.sizes.isNotEmpty) ...[
                        _buildSectionHeader('SELECT SIZE', gold),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.product.sizes.map((size) {
                            final isSelected = _selectedSize == size;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedSize = size),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? gold.withValues(alpha:0.15) : const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? gold : Colors.white.withValues(alpha:0.1),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(size,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? gold : Colors.white54,
                                    )),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── COLOR PICKER (Clothes, Shoes & Bags) ──
                      if ((widget.product.category == 'Clothes' ||
                          widget.product.category == 'Shoes' ||
                          widget.product.category == 'Bags') &&
                          widget.product.colors.isNotEmpty) ...[
                        _buildSectionHeader('SELECT COLOR', gold),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.product.colors.map((color) {
                            final isSelected = _selectedColor == color;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = color),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? gold.withValues(alpha:0.15) : const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? gold : Colors.white.withValues(alpha:0.1),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      Icon(Icons.check_rounded, size: 14, color: gold),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(color,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? gold : Colors.white54,
                                        )),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      Divider(color: Colors.white.withValues(alpha:0.08), thickness: 1.5),
                      const SizedBox(height: 20),

                      // Quantity selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quantity',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: gold.withValues(alpha:0.2)),
                            ),
                            child: Row(
                              children: [
                                _QtyButton(icon: Icons.remove, onTap: () => setState(() { if (quantity > 1) quantity--; }), gold: gold),
                                SizedBox(
                                  width: 36,
                                  child: Text('$quantity',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                                _QtyButton(
                                  icon: Icons.add,
                                  onTap: () => setState(() {
                                    if (widget.product.stock == 0 || quantity < widget.product.stock) quantity++;
                                  }),
                                  gold: gold,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Total
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: gold.withValues(alpha:0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: TextStyle(fontSize: 14, color: Colors.white38, fontWeight: FontWeight.w600)),
                            Text(
                              'Rs. ${(widget.product.effectivePrice * quantity).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFD4AF37)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Bar
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border(top: BorderSide(color: gold.withValues(alpha:0.12))),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 20, offset: const Offset(0, -6))],
              ),
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Validate size selection
                    final needsSize = (widget.product.category == 'Clothes' || widget.product.category == 'Shoes') &&
                        widget.product.sizes.isNotEmpty;
                    final needsColor = (widget.product.category == 'Clothes' ||
                        widget.product.category == 'Shoes' ||
                        widget.product.category == 'Bags') &&
                        widget.product.colors.isNotEmpty;

                    if (needsSize && _selectedSize == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: Colors.red[900],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        content: const Text('Please select a size',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ));
                      return;
                    }
                    if (needsColor && _selectedColor == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: Colors.red[900],
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        content: const Text('Please select a color',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ));
                      return;
                    }

                    // Set buyer choices on product before adding to cart
                    widget.product.selectedSize = _selectedSize;
                    widget.product.selectedColor = _selectedColor;

                    CartManager.addToCart(widget.product, quantity);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1E1E1E),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(16),
                        content: Text(
                          '${widget.product.name} added to cart',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0A0A0A), size: 20),
                  label: const Text(
                    'ADD TO CART',
                    style: TextStyle(fontSize: 13, color: Color(0xFF0A0A0A), fontWeight: FontWeight.w900, letterSpacing: 2.0),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── NEW: STORE CARD WIDGET ──
  Widget _buildStoreCard(Color gold) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: gold.withValues(alpha:0.15)),
      ),
      child: Row(
        children: [
          // Store Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: gold.withValues(alpha:0.1),
              shape: BoxShape.circle,
              border: Border.all(color: gold.withValues(alpha:0.3)),
            ),
            child: Icon(Icons.storefront_rounded, color: gold, size: 24),
          ),
          const SizedBox(width: 14),
          // Store Name and Link
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyStoreScreen()));
                  },
                  child: Text(
                    widget.product.sellerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Text(
                  "Official Seller",
                  style: TextStyle(color: Colors.white.withValues(alpha:0.4), fontSize: 12),
                ),
              ],
            ),
          ),
          // Message Button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    receiverId: widget.product.sellerId,
                    receiverName: widget.product.sellerName,
                  ),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gold.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chat_bubble_outline_rounded, color: gold, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color gold) {
    return Row(
      children: [
        Container(width: 3, height: 12, decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.2, color: gold)),
      ],
    );
  }

  Widget _buildImageHeader(BuildContext context, Color gold, Color charcoal) {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.42,
          width: double.infinity,
          color: const Color(0xFF1E1E1E),
          child: Padding(
            padding: const EdgeInsets.all(36.0),
            child: widget.product.imageUrl.startsWith('http')
                ? Image.network(widget.product.imageUrl, fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 60, color: Colors.white24))
                : Image.asset(widget.product.imageUrl, fit: BoxFit.contain),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, charcoal],
              ),
            ),
          ),
        ),
        Positioned(
          top: 48, left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gold.withValues(alpha:0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 10)],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 18, color: gold.withValues(alpha:0.8)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color gold;
  const _QtyButton({required this.icon, required this.onTap, required this.gold});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18, color: gold),
      ),
    );
  }
}
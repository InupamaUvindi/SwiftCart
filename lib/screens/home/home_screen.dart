import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:swiftcart/screens/home/product_detail_screen.dart';
import 'package:swiftcart/models/product.dart';
import 'package:swiftcart/screens/orders/notifications_screen.dart';
import '../../widgets/sale_banner.dart';
import '../../widgets/luxury_painter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _bannerTimer;
  int _currentBannerIndex = 0;
  String selectedCategory = "All";
  String searchQuery = "";
  final List<String> _banners = ["Big Sale", "New Arrivals", "Special Offers"];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (t) {
      if (_bannerController.hasClients) {
        _currentBannerIndex = (_currentBannerIndex + 1) % _banners.length;
        _bannerController.animateToPage(_currentBannerIndex, duration: const Duration(milliseconds: 350), curve: Curves.easeIn);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD4AF37);
    const Color charcoal = Color(0xFF0A0A0A);

    return Scaffold(
      backgroundColor: charcoal,
      body: Stack(
        children: [
          // ── LAYER 1: LUXURY PAINTER ──
          Positioned.fill(child: CustomPaint(painter: SwiftCartLuxuryPainter())),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha:0.2))),

          // ── LAYER 2: CONTENT ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(gold),
                  _buildSearchBar(gold),
                  const SizedBox(height: 24),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: SaleBanner()),
                  const SizedBox(height: 32),
                  _buildSectionHeader('CATEGORIES', gold),
                  const SizedBox(height: 16),
                  _buildCategorySection(gold),
                  const SizedBox(height: 32),
                  _buildSectionHeader('POPULAR PRODUCTS', gold),
                  const SizedBox(height: 16),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildProductGrid(gold)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Color gold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SWIFT CART', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4, color: gold.withValues(alpha:0.7))),
              const SizedBox(height: 4),
              const Text('Good day 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            ],
          ),
          _buildNotificationIcon(context, FirebaseAuth.instance.currentUser?.uid, gold),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color gold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gold.withValues(alpha:0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => searchQuery = value),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search_rounded, color: gold.withValues(alpha:0.6), size: 22),
            hintText: 'Search products...',
            hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color gold) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: gold)),
        ],
      ),
    );
  }

  Widget _buildCategorySection(Color gold) {
    final cats = [
      {"n": "All", "i": "assets/all.jpg"}, {"n": "Clothes", "i": "assets/cl.jpg"},
      {"n": "Electronics", "i": "assets/ele.jpg"}, {"n": "Makeup", "i": "assets/beau.jpg"},
      {"n": "Shoes", "i": "assets/shoes.jpg"}, {"n": "Bags", "i": "assets/lebag.jpg"},
      {"n": "Jewelry", "i": "assets/goldb.jpg"}, {"n": "Watches", "i": "assets/clwatch.jpg"},
    ];
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cats.length,
        itemBuilder: (context, i) {
          final isSelected = selectedCategory == cats[i]["n"];
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cats[i]["n"]!),
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 64, width: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? gold : gold.withValues(alpha:0.1), width: 2),
                      boxShadow: isSelected ? [BoxShadow(color: gold.withValues(alpha:0.3), blurRadius: 10)] : [],
                    ),
                    child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.asset(cats[i]["i"]!, fit: BoxFit.cover)),
                  ),
                  const SizedBox(height: 8),
                  Text(cats[i]["n"]!, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500, color: isSelected ? gold : Colors.white38)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(Color gold) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }

        // ── FILTERING LOGIC ──
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // 1. Convert everything to lowercase for a fair comparison
          final productName = (data['name'] ?? '').toString().toLowerCase();
          final category = data['category'] ?? 'All';
          final lowerSearchQuery = searchQuery.toLowerCase();

          // 2. Category Check
          final matchesCategory = (selectedCategory == "All" || category == selectedCategory);

          // 3. Search Check (Shows products if the name CONTAINS or STARTS WITH the letter)
          final matchesSearch = productName.contains(lowerSearchQuery);

          return matchesCategory && matchesSearch;
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.search_off_rounded, color: gold.withValues(alpha:0.3), size: 40),
                const SizedBox(height: 12),
                Text("No products found", style: TextStyle(color: gold.withValues(alpha:0.5), fontSize: 13)),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final product = Product.fromFirestore(docs[i].data() as Map<String, dynamic>, docs[i].id);
            return _buildProductCard(product, gold);
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product, Color gold) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: gold.withValues(alpha:0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, color: Colors.white24),
                    ),
                  ),
                  if (product.isOnSale)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.red, borderRadius: BorderRadius.circular(7)),
                        child: Text(
                          '-${product.discountPercent.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Product Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
              child: Text(
                product.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (product.isOnSale && product.salePrice != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Rs. ${product.salePrice!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Rs. ${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: gold, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),

            // 3. SHOP NOW BUTTON
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: product),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold.withValues(alpha:0.15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'SHOP NOW',
                    style: TextStyle(
                      color: gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context, String? uid, Color gold) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notifications').where('userId', isEqualTo: uid).where('isRead', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        int unread = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Container(
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(14), border: Border.all(color: gold.withValues(alpha:0.15))),
          child: Stack(children: [
            IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())), icon: Icon(Icons.notifications_outlined, size: 22, color: gold.withValues(alpha:0.8))),
            if (unread > 0) Positioned(right: 10, top: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
          ]),
        );
      },
    );
  }
}
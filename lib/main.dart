import 'package:flutter/material.dart';
import 'package:swiftcart/screens/chat/chat_list_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/cart_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/about_screen.dart';
import 'screens/seller/add_product_screen.dart';
import 'screens/seller/mystore_screen.dart';
import 'screens/auth/start_screen.dart';
import 'screens/orders/orders_screen.dart'; // NEW
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SwiftCartApp());

  Stripe.publishableKey = "pk_test_51TFdhr00Ie3p5N9yHlVgFFYoGr1IrulgNqQopohs3bxHfNIzBGc9VX5jMvVpnEhQkvcKVdzyZdbmOxrff7yRRhcz00YOyG71Dl";
  await Stripe.instance.applySettings();
}

class SwiftCartApp extends StatelessWidget {
  const SwiftCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swift Cart',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF9F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFAF9F7),
          elevation: 0,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A1A),
          primary: const Color(0xFF1A1A1A),
          secondary: const Color(0xFFD4AF37),
        ),
      ),
      home: const StartScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final bool isSellerMode;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
    this.isSellerMode = false,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  late bool _isSeller;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _isSeller = widget.isSellerMode;
  }

  List<Widget> get _pages =>
      _isSeller
          ? [
        const HomeScreen(),
        const AddProductScreen(),
        const MyStoreScreen(),
        ProfileScreen(isSellerMode: _isSeller),
        const AboutScreen(),
      ]
          : [
        const HomeScreen(),
        const CartScreen(),
        const OrdersScreen(),
        ProfileScreen(isSellerMode: _isSeller),
        const AboutScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    const Color charcoal = Color(0xFF0A0A0A);
    return Scaffold(
      backgroundColor: charcoal,
      body: IndexedStack(
        key: ValueKey(_isSeller),
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    const Color gold = Color(0xFFD4AF37);
    const Color charcoal = Color(
        0xFF1E1E1E);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: charcoal,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: gold.withValues(alpha: 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            elevation: 0,
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: gold,
            unselectedItemColor: Colors.white24,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            enableFeedback: false,
            items: _isSeller ? _sellerItems(gold) : _buyerItems(gold),
          ),
        ),
      ),
    );
  }
  // ── BUYER ITEMS WITH PREMIUM ICONS ──
  List<BottomNavigationBarItem> _buyerItems(Color gold) =>
      [
        _buildNavItem(Icons.grid_view_rounded, 'MARKET', gold),
        _buildNavItem(Icons.shopping_bag_outlined, 'CART', gold),
        _buildNavItem(Icons.confirmation_number_outlined, 'ORDERS', gold),
        _buildNavItem(Icons.person_2_outlined, 'PROFILE', gold),
        _buildNavItem(Icons.auto_awesome_mosaic_outlined, 'ABOUT', gold),
      ];

  // ── SELLER ITEMS WITH PREMIUM ICONS ──
  List<BottomNavigationBarItem> _sellerItems(Color gold) =>
      [
        _buildNavItem(Icons.dashboard_customize_outlined, 'DASHBOARD', gold),
        _buildNavItem(Icons.add_box_outlined, 'ADD ITEM', gold),
        _buildNavItem(Icons.inventory_2_outlined, 'STOCKS', gold),
        _buildNavItem(Icons.person_2_outlined, 'PROFILE', gold),
        _buildNavItem(Icons.auto_awesome_mosaic_outlined, 'ABOUT', gold),
      ];

  // ── HELPER TO CREATE CONSISTENT ITEMS ──
  BottomNavigationBarItem _buildNavItem(IconData icon, String label, Color gold) {
    return BottomNavigationBarItem(
      icon: Icon(icon, size: 22),
      activeIcon: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: gold.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: gold, size: 22),
      ),
      label: label,
    );
  }
}

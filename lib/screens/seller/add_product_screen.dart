// add_product_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../main.dart';
import '../../widgets/luxury_painter.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _productImage;
  bool _isLoading = false;
  String _selectedCategory = 'Electronics';

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController();

  final List<String> _categories = ['Electronics', 'Clothes', 'Makeup', 'Shoes', 'Bags','Jewelry','Watches'];

  // ── Size & Color state ──
  final List<String> _clothSizes = ['XS', 'S', 'M', 'L', 'XL'];
  final List<String> _shoeSizes = ['UK 6', 'UK 7', 'UK 8', 'UK 9', 'UK 10', 'UK 11', 'UK 12'];
  final Set<String> _selectedSizes = {};
  final List<String> _addedColors = [];
  final TextEditingController _colorInputController = TextEditingController();

  bool get _hassizes => _selectedCategory == 'Clothes' || _selectedCategory == 'Shoes';
  bool get _hasColors => _selectedCategory == 'Clothes' || _selectedCategory == 'Shoes' || _selectedCategory == 'Bags';
  List<String> get _availableSizes => _selectedCategory == 'Shoes' ? _shoeSizes : _clothSizes;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _stockController.dispose();
    _colorInputController.dispose();
    super.dispose();
  }

  Future<void> _pickProductImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _productImage = File(image.path));
    }
  }

  Future<String?> _uploadImage(String productId) async {
    if (_productImage == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child('product_images').child('$productId.jpg');
      await ref.putFile(_productImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void _handleSaveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final docRef = FirebaseFirestore.instance.collection('products').doc();
      final imageUrl = await _uploadImage(docRef.id);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      final storeName = userDoc.data()?['storeName'] ?? 'Premium Seller';

      await docRef.set({
        'sellerId': FirebaseAuth.instance.currentUser!.uid,
        'sellerName': storeName,
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'isOnSale': false,
        'imageUrl': imageUrl ?? 'assets/jpg',
        'sizes': _selectedSizes.toList(),
        'colors': _addedColors,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Product listed successfully!',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD4AF37))),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => const MainNavigation(initialIndex: 2, isSellerMode: true)),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error listing product: $e',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: gold.withValues(alpha:0.8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ADD PRODUCT',
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
          _isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                const SizedBox(height: 16),
                Text('Uploading product...', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w500)),
              ],
            ),
          )
              : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker
                    GestureDetector(
                      onTap: _pickProductImage,
                      child: Container(
                        height: 190,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: _productImage != null ? gold.withValues(alpha:0.4) : gold.withValues(alpha:0.15),
                              width: 1.5),
                        ),
                        child: _productImage != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(_productImage!, fit: BoxFit.cover),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: gold.withValues(alpha:0.10),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.add_a_photo_outlined, size: 28, color: gold),
                            ),
                            const SizedBox(height: 12),
                            Text('Upload Product Image',
                                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha:0.7), fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Tap to browse gallery', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildLabel('Product Name', gold),
                    const SizedBox(height: 8),
                    _buildFormField(controller: _nameController, hint: 'e.g. Luxury Gold Necklace', gold: gold,
                        validator: (v) => v!.isEmpty ? 'Enter product name' : null),
                    const SizedBox(height: 20),

                    _buildLabel('Price (Rs.)', gold),
                    const SizedBox(height: 8),
                    _buildFormField(controller: _priceController, hint: 'e.g. 15000', gold: gold,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v!.isEmpty) return 'Enter price';
                          if (double.tryParse(v) == null) return 'Enter a valid number';
                          return null;
                        }),
                    const SizedBox(height: 20),

                    _buildLabel('Stock Quantity', gold),
                    const SizedBox(height: 8),
                    _buildFormField(controller: _stockController, hint: 'e.g. 10', gold: gold,
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Enter stock quantity' : null),
                    const SizedBox(height: 20),

                    _buildLabel('Category', gold),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: gold.withValues(alpha:0.15), width: 1.5),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: const Color(0xFF1E1E1E),
                        decoration: const InputDecoration(border: InputBorder.none),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: gold.withValues(alpha:0.6)),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() {
                          _selectedCategory = v!;
                          _selectedSizes.clear();
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── SIZES (Clothes & Shoes only) ──
                    if (_hassizes) ...[
                      _buildLabel('Available Sizes', gold),
                      const SizedBox(height: 4),
                      Text('Tap to toggle which sizes you have in stock',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSizes.map((size) {
                          final selected = _selectedSizes.contains(size);
                          return GestureDetector(
                            onTap: () => setState(() =>
                            selected ? _selectedSizes.remove(size) : _selectedSizes.add(size)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color: selected ? gold.withValues(alpha:0.15) : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? gold : gold.withValues(alpha:0.2),
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(size,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? gold : Colors.white54,
                                  )),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── COLORS (Clothes, Shoes & Bags) ──
                    if (_hasColors) ...[
                      _buildLabel('Available Colors', gold),
                      const SizedBox(height: 4),
                      Text('Type a color name and press +',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: gold.withValues(alpha:0.15), width: 1.5),
                              ),
                              child: TextField(
                                controller: _colorInputController,
                                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Midnight Black',
                                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                onSubmitted: (_) => _addColor(gold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _addColor(gold),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: gold.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: gold.withValues(alpha:0.4)),
                              ),
                              child: Icon(Icons.add_rounded, color: gold, size: 22),
                            ),
                          ),
                        ],
                      ),
                      if (_addedColors.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _addedColors.map((color) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha:0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: gold.withValues(alpha:0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(color,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: gold.withValues(alpha:0.9))),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => setState(() => _addedColors.remove(color)),
                                  child: Icon(Icons.close_rounded, size: 14, color: gold.withValues(alpha:0.6)),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],

                    _buildLabel('Description', gold),
                    const SizedBox(height: 8),
                    _buildFormField(controller: _descController, hint: 'Describe your product...', gold: gold,
                        maxLines: 3, validator: (v) => v!.isEmpty ? 'Enter description' : null),
                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _handleSaveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('LIST PRODUCT',
                            style: TextStyle(color: Color(0xFF0A0A0A), fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addColor(Color gold) {
    final val = _colorInputController.text.trim();
    if (val.isEmpty || _addedColors.contains(val)) return;
    setState(() {
      _addedColors.add(val);
      _colorInputController.clear();
    });
  }

  Widget _buildLabel(String label, Color gold) => Text(
    label,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: gold.withValues(alpha:0.7), letterSpacing: 0.8),
  );

  Widget _buildFormField({
    required TextEditingController controller,
    required String hint,
    required Color gold,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha:0.15), width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
// edit_product_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math' as math;
import '../../widgets/luxury_painter.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _stockController;

  File? _newImageFile;
  bool _isLoading = false;

  // ── Size & Color state ──
  final List<String> _clothSizes = ['XS', 'S', 'M', 'L', 'XL'];
  final List<String> _shoeSizes = ['UK 6', 'UK 7', 'UK 8', 'UK 9', 'UK 10', 'UK 11', 'UK 12'];
  late Set<String> _selectedSizes;
  late List<String> _addedColors;
  final TextEditingController _colorInputController = TextEditingController();

  bool get _hasSizes => widget.product.category == 'Clothes' || widget.product.category == 'Shoes';
  bool get _hasColors => widget.product.category == 'Clothes' || widget.product.category == 'Shoes' || widget.product.category == 'Bags';
  List<String> get _availableSizes => widget.product.category == 'Shoes' ? _shoeSizes : _clothSizes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _descController = TextEditingController(text: widget.product.description);
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _selectedSizes = Set<String>.from(widget.product.sizes);
    _addedColors = List<String>.from(widget.product.colors);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _newImageFile = File(pickedFile.path));
    }
  }

  void _updateProduct() async {
    setState(() => _isLoading = true);
    try {
      String finalImageUrl = widget.product.imageUrl;

      if (_newImageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('product_images')
            .child('${widget.product.id}.jpg');
        await ref.putFile(_newImageFile!);
        finalImageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'description': _descController.text.trim(),
        'stock': int.tryParse(_stockController.text.trim()) ?? 0,
        'imageUrl': finalImageUrl,
        'sizes': _selectedSizes.toList(),
        'colors': _addedColors,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Product updated!',
              style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w600)),
          backgroundColor: Color(0xFF1E1E1E),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to update product. Please try again.',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red[900],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
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
          'EDIT LISTING',
          style: TextStyle(
              color: gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3),
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
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: gold.withValues(alpha:0.25)),
                              boxShadow: [
                                BoxShadow(
                                  color: gold.withValues(alpha:0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: _newImageFile != null
                                  ? Image.file(_newImageFile!, fit: BoxFit.cover)
                                  : Image.network(widget.product.imageUrl, fit: BoxFit.cover),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: gold,
                              shape: BoxShape.circle,
                              border: Border.all(color: charcoal, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF0A0A0A)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        "Tap image to change",
                        style: TextStyle(fontSize: 11, color: gold.withValues(alpha:0.5), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildLabel('Product Name', gold),
                  const SizedBox(height: 8),
                  _buildField(controller: _nameController, hint: 'Product name', gold: gold),
                  const SizedBox(height: 20),

                  _buildLabel('Price (Rs.)', gold),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _priceController,
                    hint: '0.00',
                    keyboardType: TextInputType.number,
                    gold: gold,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Stock Quantity', gold),
                  const SizedBox(height: 8),
                  _buildField(
                    controller: _stockController,
                    hint: 'e.g. 10',
                    keyboardType: TextInputType.number,
                    gold: gold,
                  ),
                  const SizedBox(height: 20),

                  // ── SIZES (Clothes & Shoes only) ──
                  if (_hasSizes) ...[
                    _buildLabel('Available Sizes', gold),
                    const SizedBox(height: 4),
                    Text('Tap to toggle which sizes you stock',
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
                              onSubmitted: (_) => _addColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _addColor,
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
                  _buildField(
                    controller: _descController,
                    hint: 'Describe your product...',
                    maxLines: 4,
                    gold: gold,
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _updateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _stockController.dispose();
    _colorInputController.dispose();
    super.dispose();
  }

  void _addColor() {
    final val = _colorInputController.text.trim();
    if (val.isEmpty || _addedColors.contains(val)) return;
    setState(() {
      _addedColors.add(val);
      _colorInputController.clear();
    });
  }

  Widget _buildLabel(String label, Color gold) => Text(
    label,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: gold.withValues(alpha:0.7),
      letterSpacing: 0.8,
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required Color gold,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha:0.15), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
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
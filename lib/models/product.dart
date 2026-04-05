import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final String sellerName;
  final double price;
  final int stock;
  int quantity;
  final DateTime? createdAt;
  final List<String> sizes;
  final List<String> colors;
  String? selectedSize;
  String? selectedColor;
  final bool isOnSale;
  final double discountPercent;
  final double? salePrice;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.sellerName,
    this.stock = 0,
    this.quantity = 1,
    this.createdAt,
    this.sizes = const [],
    this.colors = const [],
    this.selectedSize,
    this.selectedColor,
    this.isOnSale = false,
    this.discountPercent = 0,
    this.salePrice,
  });

  /// The price buyers actually pay
  double get effectivePrice => isOnSale && salePrice != null ? salePrice! : price;

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    final bool onSale = data['isOnSale'] ?? false;
    final double discount = (data['discountPercent'] ?? 0).toDouble();
    final double basePrice = (data['price'] ?? 0).toDouble();
    final double? computed = onSale && discount > 0
        ? double.parse((basePrice - basePrice * discount / 100).toStringAsFixed(2))
        : null;

    return Product(
      id: id,
      sellerId: data['sellerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: basePrice,
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'General',
      quantity: data['quantity'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      sellerName: data['sellerName'] ?? 'Premium Seller',
      stock: (data['stock'] as int?) ?? 0,
      sizes: List<String>.from(data['sizes'] ?? []),
      colors: List<String>.from(data['colors'] ?? []),
      isOnSale: onSale,
      discountPercent: discount,
      salePrice: computed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
      'quantity': quantity,
      'createdAt': createdAt ?? DateTime.now(),
      'sizes': sizes,
      'colors': colors,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'isOnSale': isOnSale,
      'discountPercent': discountPercent,
      'salePrice': salePrice,
    };
  }

  Product copyWith({
    int? quantity,
    int? stock,
    String? selectedSize,
    String? selectedColor,
    bool? isOnSale,
    double? discountPercent,
    double? salePrice,
  }) {
    return Product(
      id: id,
      sellerId: sellerId,
      name: name,
      description: description,
      price: price,
      imageUrl: imageUrl,
      category: category,
      sellerName: sellerName,
      stock: stock ?? this.stock,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt,
      sizes: sizes,
      colors: colors,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      isOnSale: isOnSale ?? this.isOnSale,
      discountPercent: discountPercent ?? this.discountPercent,
      salePrice: salePrice ?? this.salePrice,
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String buyerId;
  final List<Map<String, dynamic>> items;
  final double total;
  final String status;
  final String shippingAddress;
  final DateTime createdAt;

  OrderModel({
    required this.buyerId,
    required this.items,
    required this.total,
    this.status = "placed",
    required this.shippingAddress,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'items': items,
      'total': total,
      'status': status,
      'shippingAddress': shippingAddress,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
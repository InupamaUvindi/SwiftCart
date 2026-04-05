import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';
import 'package:flutter/material.dart';

class CartManager {
  static final ValueNotifier<List<Product>> cartNotifier =
  ValueNotifier<List<Product>>([]);

  static List<Product> get cartItems => cartNotifier.value;


  static void addToCart(Product product, int quantity) {
    List<Product> newList = List.from(cartNotifier.value);
    // Match by id + selectedSize + selectedColor so same product in diff size/color = separate entry
    int index = newList.indexWhere((item) =>
    item.id == product.id &&
        item.selectedSize == product.selectedSize &&
        item.selectedColor == product.selectedColor);
    if (index != -1) {
      final newQty = newList[index].quantity + quantity;
      // Cap at stock if stock is set
      newList[index].quantity = product.stock > 0
          ? newQty.clamp(1, product.stock)
          : newQty;
    } else {
      product.quantity = quantity;
      newList.add(product);
    }
    cartNotifier.value = newList;
    syncCartToFirestore();
  }

  static Future<void> syncCartToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Ensure this converts the list of Products into a list of Maps
    final List<Map<String, dynamic>> cartData = cartNotifier.value.map((p) => p.toMap()).toList();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'cart': cartData, // This will now correctly save as an Array in Firestore
    }, SetOptions(merge: true)); // Merge ensures we don't overwrite other user fields
  }

  static double getTotalPrice() {
    return cartNotifier.value.fold(
        0, (total, item) => total + (item.effectivePrice * item.quantity));
  }

  static void removeFromCart(int index) {
    List<Product> newList = List.from(cartNotifier.value);
    newList.removeAt(index);
    cartNotifier.value = newList;

    syncCartToFirestore();
  }

  static void incrementQuantity(int index, {int? maxStock}) {
    List<Product> newList = List.from(cartNotifier.value);
    if (maxStock != null && newList[index].quantity >= maxStock) return;
    newList[index].quantity++;
    newList = List.from(newList);
    cartNotifier.value = newList;
    syncCartToFirestore();
  }

  static void decrementQuantity(int index) {
    List<Product> newList = List.from(cartNotifier.value);
    if (newList[index].quantity > 1) {
      newList[index].quantity--;
      cartNotifier.value = newList;
    } else {
      newList.removeAt(index);
      cartNotifier.value = newList;
    }
    syncCartToFirestore();
  }

  // Use this ONLY when the user clicks 'Logout'
  static void clearLocalCartOnly() {
    cartNotifier.value = [];
    // Notice: We do NOT call syncCartToFirestore() here.
    // This keeps the data safe in the cloud while clearing the screen.
  }

// Use this ONLY after a successful checkout/payment
  static void clearCartCompletely() {
    cartNotifier.value = [];
    syncCartToFirestore();
  }
}
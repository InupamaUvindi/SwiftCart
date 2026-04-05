import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PayhereService {
  // Replace these with your sandbox credentials from sandbox.payhere.lk
  static const String _merchantId = '1234806';
  static const String _merchantSecret = 'MTk4OTU2ODA4NzMyMzg5MDg2NjA3MzkzNTM2NjI2NTc5ODU0MTA=';

  // Generate MD5 hash required by PayHere
  static String _generateHash(String orderId, double amount) {
    final amountFormatted = amount.toStringAsFixed(2);

    // Step 1: MD5 of merchant secret (must be uppercase)
    final secretMd5 = md5
        .convert(utf8.encode(_merchantSecret))
        .toString()
        .toUpperCase();

    // Step 2: Final hash = MD5 of (merchantId + orderId + amount + currency + secretMd5)
    final hashInput = '$_merchantId$orderId${amountFormatted}LKR$secretMd5';

    // Debug prints - remove when working
    print('=== PayHere Hash Debug ===');
    print('Merchant ID: $_merchantId');
    print('Order ID: $orderId');
    print('Amount: $amountFormatted');
    print('Secret MD5: $secretMd5');
    print('Hash Input: $hashInput');

    final finalHash = md5
        .convert(utf8.encode(hashInput))
        .toString()
        .toUpperCase();

    print('Final Hash: $finalHash');
    print('==========================');

    return finalHash;
  }

  static Future<void> makePayment({
    required double amount,
    required String orderId,
    required String customerFirstName,
    required String customerLastName,
    required String customerEmail,
    required String customerPhone,
    required Function() onSuccess,
    required Function(String error) onError,
    required Function() onDismissed,
  }) async {
    final hash = _generateHash(orderId, amount);

    Map paymentObject = {
      "sandbox": true,
      "merchant_id": _merchantId,
      "notify_url": "http://sample.com/notify",
      "order_id": orderId,
      "items": "Order Payment",
      "amount": amount.toStringAsFixed(2),
      "currency": "LKR",
      "hash": hash,
      "first_name": customerFirstName,
      "last_name": customerLastName,
      "email": customerEmail,
      "phone": customerPhone,
      "address": "No Address",
      "city": "Colombo",
      "country": "Sri Lanka",
    };

    // Debug print
    print('=== PayHere Payment Object ===');
    paymentObject.forEach((key, value) => print('$key: $value'));
    print('==============================');

    PayHere.startPayment(
      paymentObject,
          (paymentId) {
        print("✅ PayHere Success - Payment ID: $paymentId");
        onSuccess();
      },
          (error) {
        print("❌ PayHere Error: $error");
        onError(error);
      },
          () {
        print("⚠️ PayHere Dismissed by user");
        onDismissed();
      },
    );
  }

  // Generate a unique order ID
  static String generateOrderId() {
    return 'ORDER_${DateTime.now().millisecondsSinceEpoch}';
  }
}
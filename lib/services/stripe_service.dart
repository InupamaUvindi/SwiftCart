import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';

class StripeService {
  // LKR to USD conversion (approximate).
  // For production, fetch a live rate from an exchange rate API.
  static const double _lkrToUsdRate = 320.0;

  /// Converts LKR to USD cents for Stripe.
  /// Example: Rs. 3200 → $10.00 → 1000 cents
  static int _convertLkrToUsdCents(double amountLkr) {
    final usd = amountLkr / _lkrToUsdRate;
    return (usd * 100).round();
  }

  /// Main method — call this from cart_screen.dart.
  /// Returns true if payment succeeded, false if cancelled or failed.
  static Future<bool> makePayment({
    required double amountLKR,
    required BuildContext context,
  }) async {
    try {
      // Step 1: Convert LKR → USD cents
      final amountInCents = _convertLkrToUsdCents(amountLKR);

      // Stripe minimum charge is $0.50 (50 cents)
      if (amountInCents < 50) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order total too low for online payment (min ~Rs. 160)."),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }

      // Step 2: Call Firebase Cloud Function to create PaymentIntent
      final clientSecret = await _createPaymentIntent(amountInCents);
      if (clientSecret == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment setup failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      // Step 3: Initialize the Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: "SwiftCart",
          style: ThemeMode.light,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF212121),
            ),
          ),
        ),
      );

      // Step 4: Show the payment sheet to the user
      await Stripe.instance.presentPaymentSheet();

      // Reaching here means payment was successful
      return true;

    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        // User dismissed — not an error
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment failed: ${e.error.localizedMessage}"),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unexpected error: $e"),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  /// Calls your Firebase Cloud Function (index.js → createPaymentIntent)
  /// and returns the Stripe client_secret string.
  static Future<String?> _createPaymentIntent(int amountInCents) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('createPaymentIntent');

      final result = await callable.call({'amount': amountInCents});

      return result.data['clientSecret'] as String?;
    } catch (e) {
      debugPrint('Cloud Function error: $e');
      return null;
    }
  }
}
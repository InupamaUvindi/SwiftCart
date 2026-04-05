const { onCall,HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { defineSecret } = require("firebase-functions/params");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

// Store your Stripe secret key securely using Firebase Secret Manager.
// Run this command ONCE in your terminal before deploying:
//   firebase functions:secrets:set STRIPE_SECRET_KEY
// Then paste your sk_test_... key when prompted.
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);


exports.createPaymentIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {

    // 1. Require the user to be logged in
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to make a payment."
      );
    }

    const amount = request.data.amount;

    // 2. Validate the amount
    if (!amount || typeof amount !== "number" || amount < 50) {
      throw new HttpsError(
        "invalid-argument",
        "Amount must be at least 50 USD cents."
      );
    }

    // 3. Create the PaymentIntent with Stripe
    try {
      const stripe = require("stripe")(stripeSecretKey.value());

      const paymentIntent = await stripe.paymentIntents.create({
        amount: amount,
        currency: "usd",
        payment_method_types: ["card"],
        description: "SwiftCart Purchase",
        metadata: {
          userId: request.auth.uid,
        },
      });

      return { clientSecret: paymentIntent.client_secret };

    } catch (error) {
      throw new HttpsError("internal", error.message);
    }
  }
);

// --- 2. NEW NOTIFICATION TRIGGER ---
// This runs automatically whenever a document is created in the 'orders' collection
exports.onOrderCreated = onDocumentCreated("orders/{orderId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return null;

  const orderData = snapshot.data();
  const db = getFirestore();

  try {
    // Notify the Buyer
    await db.collection("notifications").add({
      userId: orderData.userId, // Matches the buyer's UID
      title: "Order Confirmed! 🛍️",
      body: `Your order #${event.params.orderId.substring(0, 6)} has been placed successfully.`,
      type: "order_update",
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    // Optional: Notify the Sellers
    // If you implemented the 'sellerIds' array as discussed previously:
    if (orderData.sellerIds && Array.isArray(orderData.sellerIds)) {
      const sellerPromises = orderData.sellerIds.map((sellerId) => {
        return db.collection("notifications").add({
          userId: sellerId,
          title: "New Sale! 💰",
          body: "A customer has purchased an item from your store.",
          type: "order_update",
          isRead: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      });
      await Promise.all(sellerPromises);
    }

    console.log(`Notifications sent for order: ${event.params.orderId}`);
  } catch (error) {
    console.error("Notification Error:", error);
  }
});
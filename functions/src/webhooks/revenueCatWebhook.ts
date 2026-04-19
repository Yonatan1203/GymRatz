/**
 * RevenueCat Webhook Handler — STUB (post-beta)
 *
 * TODO: Implement after beta launch. This function will:
 *
 * 1. Receive POST requests from RevenueCat webhooks
 * 2. Validate the Authorization header against a stored secret
 * 3. Parse the event body (RevenueCat webhook v2 format)
 * 4. Extract app_user_id (= Firebase UID)
 * 5. Map event types to subscription status updates:
 *    - INITIAL_PURCHASE → subscriptionStatus: 'active'
 *    - RENEWAL → update subscriptionExpiry
 *    - CANCELLATION → subscriptionStatus: 'cancelled'
 *    - BILLING_ISSUE → subscriptionStatus: 'billing_issue'
 *    - EXPIRATION → subscriptionStatus: 'expired'
 *    - PRODUCT_CHANGE → update subscriptionProductId
 * 6. Update users/{uid} doc with subscriptionStatus, subscriptionExpiry, subscriptionProductId
 * 7. Optionally trigger FCM notifications for trial-end, cancellation, etc.
 *
 * For beta, all premium gating is client-side via RevenueCat SDK.
 */

// Uncomment and implement post-beta:
// import * as functions from "firebase-functions";
// import * as admin from "firebase-admin";
//
// export const revenueCatWebhook = functions.https.onRequest(async (req, res) => {
//   if (req.method !== "POST") {
//     res.status(405).send("Method Not Allowed");
//     return;
//   }
//
//   // Validate webhook secret
//   // const secret = functions.config().revenuecat?.webhook_secret;
//   // if (req.headers.authorization !== `Bearer ${secret}`) {
//   //   res.status(401).send("Unauthorized");
//   //   return;
//   // }
//
//   // Parse and handle event
//   // const event = req.body;
//   // ...
//
//   res.status(200).send("OK");
// });

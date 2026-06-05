import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * RevenueCat Webhook Handler
 *
 * Receives POST requests from RevenueCat and syncs subscription status to Firestore.
 *
 * Setup:
 *   firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
 *   Configure the same value in RevenueCat Dashboard → Webhooks → Authorization header.
 *
 * RevenueCat sends: Authorization: Bearer <secret>
 */

const ACTIVE_EVENTS = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "NON_RENEWING_PURCHASE",
  "UNCANCELLATION",
]);

const INACTIVE_EVENTS = new Set([
  "CANCELLATION",
  "EXPIRATION",
  "BILLING_ISSUE",
]);

export const revenueCatWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  // Validate webhook secret (Authorization: Bearer <secret>)
  const webhookSecret = process.env.REVENUECAT_WEBHOOK_SECRET;
  if (webhookSecret) {
    const authHeader = req.headers.authorization ?? "";
    const expectedHeader = `Bearer ${webhookSecret}`;
    if (authHeader !== expectedHeader) {
      functions.logger.warn("RevenueCat webhook: unauthorized request");
      res.status(401).send("Unauthorized");
      return;
    }
  }

  const event = req.body?.event;
  if (!event) {
    functions.logger.warn("RevenueCat webhook: missing event body");
    res.status(400).send("Bad Request");
    return;
  }

  const uid: string | undefined = event.app_user_id;
  const type: string | undefined = event.type;

  if (!uid) {
    // No UID — nothing to update, but acknowledge receipt
    res.status(200).send("OK");
    return;
  }

  functions.logger.info("RevenueCat webhook received", {uid, type});

  const isActive = ACTIVE_EVENTS.has(type ?? "");
  const isInactive = INACTIVE_EVENTS.has(type ?? "");

  if (isActive || isInactive) {
    await admin.firestore().collection("users").doc(uid).update({
      isPro: isActive,
      subscriptionStatus: isActive ? "active" : "expired",
      subscriptionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    functions.logger.info("Updated subscription status", {
      uid,
      isPro: isActive,
      subscriptionStatus: isActive ? "active" : "expired",
    });
  } else {
    functions.logger.info("RevenueCat webhook: unhandled event type, no Firestore update", {type});
  }

  res.status(200).send("OK");
});

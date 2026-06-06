import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * RevenueCat Webhook Handler (GYM-80)
 *
 * Receives POST requests from RevenueCat and syncs subscription status
 * to users/{uid}.subscriptionStatus in Firestore.
 *
 * Secret setup:
 *   firebase functions:secrets:set REVENUECAT_WEBHOOK_SECRET
 *   Set the same value in RevenueCat Dashboard → Webhooks → Authorization header.
 *   RevenueCat sends: Authorization: Bearer <secret>
 *
 * Also supported via Functions config (legacy):
 *   firebase functions:config:set revenuecat.webhook_secret=<secret>
 */

type SubscriptionStatus =
  | "active"
  | "cancelled"
  | "billing_issue"
  | "expired";

/** Maps RevenueCat event types to the subscriptionStatus stored in Firestore. */
const EVENT_STATUS_MAP: Record<string, SubscriptionStatus> = {
  INITIAL_PURCHASE: "active",
  RENEWAL: "active",
  NON_RENEWING_PURCHASE: "active",
  UNCANCELLATION: "active",
  CANCELLATION: "cancelled",
  BILLING_ISSUE: "billing_issue",
  EXPIRATION: "expired",
};

export const revenueCatWebhook = functions
  .runWith({secrets: ["REVENUECAT_WEBHOOK_SECRET"]})
  .https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  // Validate webhook secret.
  // Prefer Firebase Secrets (process.env), fall back to Functions config.
  const webhookSecret =
    process.env.REVENUECAT_WEBHOOK_SECRET ||
    functions.config().revenuecat?.webhook_secret;

  if (webhookSecret) {
    const authHeader = req.headers.authorization ?? "";
    const expectedHeader = `Bearer ${webhookSecret}`;
    if (authHeader !== expectedHeader) {
      functions.logger.warn("RevenueCat webhook: unauthorized request");
      res.status(401).send("Unauthorized");
      return;
    }
  } else {
    functions.logger.warn(
      "REVENUECAT_WEBHOOK_SECRET not configured — skipping signature check"
    );
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
    // No UID in event — acknowledge but take no action.
    functions.logger.warn("RevenueCat webhook: event missing app_user_id", {type});
    res.status(200).send("OK");
    return;
  }

  functions.logger.info("RevenueCat webhook received", {uid, type});

  const newStatus = EVENT_STATUS_MAP[type ?? ""];

  if (newStatus !== undefined) {
    const isActive = newStatus === "active";
    await admin.firestore().collection("users").doc(uid).update({
      subscriptionStatus: newStatus,
      // Keep isPro in sync so the client RevenueCat SDK and server agree.
      isPro: isActive,
      subscriptionUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    functions.logger.info("Updated subscription status", {uid, subscriptionStatus: newStatus});
  } else {
    // Unknown event type: log but do not error — fail-safe.
    functions.logger.info(
      "RevenueCat webhook: unrecognised event type — no Firestore update",
      {type}
    );
  }

  res.status(200).send("OK");
});

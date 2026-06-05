import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * onCoachApplicationUpdate (GYM-40)
 *
 * Firestore trigger: when a coach application transitions to "approved" or
 * "rejected", send a push notification to the applicant via FCM.
 *
 * Prerequisites:
 *   - The applicant's FCM token must be stored at users/{uid}.fcmToken.
 *   - The client app must request notification permission and save the token
 *     (firebase_messaging + save token to Firestore on sign-in).
 *
 * If no FCM token is available the notification is skipped silently — this
 * keeps the approval flow working even for users who haven't enabled push.
 */
export const onCoachApplicationUpdate = functions.firestore
  .document("coach_applications/{uid}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only react when status changes to a terminal state.
    const newStatus: string | undefined = after.status;
    const oldStatus: string | undefined = before.status;

    if (newStatus === oldStatus) return;
    if (newStatus !== "approved" && newStatus !== "rejected") return;

    const uid: string = context.params.uid;

    functions.logger.info(`Coach application ${newStatus} for user ${uid}`);

    // Look up the user's FCM token.
    const userSnap = await admin.firestore().collection("users").doc(uid).get();
    const fcmToken: string | undefined = userSnap.data()?.fcmToken;

    if (!fcmToken) {
      functions.logger.info(
        `No FCM token for user ${uid} — skipping push notification`
      );
      return;
    }

    const title = "Coach Application Update";
    const body =
      newStatus === "approved"
        ? "Your coach application was approved! 🎉"
        : "Your coach application was not approved this time.";

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {title, body},
        apns: {
          payload: {
            aps: {
              alert: {title, body},
              sound: "default",
            },
          },
        },
        android: {
          notification: {
            title,
            body,
            sound: "default",
          },
        },
      });
      functions.logger.info(`Push notification sent to user ${uid}`, {newStatus});
    } catch (err) {
      // Invalid/expired token — log and move on; don't fail the trigger.
      functions.logger.warn(`Failed to send push notification to user ${uid}`, {err});
    }
  });

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {COLLECTIONS} from "../shared/constants";

/**
 * exportUserData (GYM-81 — GDPR data export)
 *
 * Callable HTTPS function that collects all data for the authenticated user
 * (profile document + every standard subcollection) and returns it as a
 * single JSON-serialisable object.
 *
 * Client usage:
 *   final result = await FirebaseFunctions.instance
 *       .httpsCallable('exportUserData')
 *       .call();
 *   final json = result.data as Map<String, dynamic>;
 */

const EXPORT_SUBCOLLECTIONS = [
  COLLECTIONS.WORKOUTS,
  COLLECTIONS.PROGRAMS,
  COLLECTIONS.PROGRESSION,
  COLLECTIONS.WEIGHT_ENTRIES,
  COLLECTIONS.PRS,
  COLLECTIONS.ACHIEVEMENTS,
  COLLECTIONS.EXERCISES,
] as const;

export const exportUserData = functions.https.onCall(async (_data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to export your data."
    );
  }

  const uid = context.auth.uid;
  const firestore = admin.firestore();

  functions.logger.info(`Data export requested by user ${uid}`);

  // Fetch root user document.
  const userSnap = await firestore.collection(COLLECTIONS.USERS).doc(uid).get();
  const userDoc = userSnap.exists ? userSnap.data() : null;

  // Fetch each subcollection.
  const subcollections: Record<string, unknown[]> = {};
  for (const sub of EXPORT_SUBCOLLECTIONS) {
    const snap = await firestore
      .collection(COLLECTIONS.USERS)
      .doc(uid)
      .collection(sub)
      .get();
    subcollections[sub] = snap.docs.map((d) => ({id: d.id, ...d.data()}));
  }

  const exportPayload = {
    exportedAt: new Date().toISOString(),
    uid,
    profile: userDoc,
    ...subcollections,
  };

  functions.logger.info(
    `Data export complete for user ${uid}`,
    {docCounts: Object.fromEntries(
      Object.entries(subcollections).map(([k, v]) => [k, (v as unknown[]).length])
    )}
  );

  return exportPayload;
});

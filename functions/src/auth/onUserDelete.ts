import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {USER_SUBCOLLECTIONS, COLLECTIONS} from "../shared/constants";
import {deleteSubcollection} from "../shared/firestoreHelpers";

/**
 * Auth trigger: cascade-delete all user data when a Firebase Auth user is deleted.
 *
 * Firestore does NOT cascade-delete subcollections, so this function
 * ensures workouts, programs, prs, achievements, and weightEntries
 * are cleaned up when a user account is removed.
 */
export const onUserDelete = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const firestore = admin.firestore();

  functions.logger.info(`Cascade-deleting data for user ${uid}`);

  let totalDeleted = 0;

  for (const subcollection of USER_SUBCOLLECTIONS) {
    try {
      const count = await deleteSubcollection(firestore, uid, subcollection);
      totalDeleted += count;
      functions.logger.info(
        `Deleted ${count} docs from ${subcollection} for user ${uid}`
      );
    } catch (error) {
      functions.logger.error(
        `Failed to delete ${subcollection} for user ${uid}:`,
        error
      );
    }
  }

  // Delete the user document itself (may already be deleted by client)
  try {
    await firestore.collection(COLLECTIONS.USERS).doc(uid).delete();
    functions.logger.info(`Deleted user document for ${uid}`);
  } catch (error) {
    functions.logger.warn(
      `User document for ${uid} may already be deleted:`,
      error
    );
  }

  functions.logger.info(
    `Cascade delete complete for user ${uid}: ${totalDeleted} subcollection docs removed`
  );
});

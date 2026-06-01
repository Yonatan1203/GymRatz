import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const ADMIN_ROLES = ["admin_user", "admin_coach"];

/**
 * GYM-74: Set custom claims when a user's role field changes so Firestore
 * rules can use request.auth.token.isAdmin instead of a get() call.
 *
 * Custom claims propagate on the next token refresh (up to 1 hour).
 * Firestore rules retain the get()-based isAdmin() fallback during the gap.
 */
export const onUserRoleUpdate = functions.firestore
  .document("users/{uid}")
  .onWrite(async (change, context) => {
    const uid = context.params.uid;

    // Document deleted — clear claims.
    if (!change.after.exists) {
      await admin.auth().setCustomUserClaims(uid, {isAdmin: false});
      return;
    }

    const before = change.before.exists ? change.before.data() : null;
    const after = change.after.data()!;

    const roleBefore: string = before?.role ?? "";
    const roleAfter: string = after.role ?? "";

    // Only update claims if the role actually changed.
    if (roleBefore === roleAfter) return;

    const isAdmin = ADMIN_ROLES.includes(roleAfter);
    await admin.auth().setCustomUserClaims(uid, {isAdmin});

    functions.logger.info(
      `Set isAdmin=${isAdmin} claim for user ${uid} (role: ${roleAfter})`
    );
  });

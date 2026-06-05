/**
 * Scheduled Firestore backup using the managed-export API.
 *
 * PREREQUISITE — manual GCP setup required before deploying:
 *   1. Create the GCS bucket `gymratz-b1a32-backups` in the GCP Console
 *      (Storage > Create Bucket). Choose the same region as your Firestore
 *      database for lowest latency and to avoid cross-region egress charges.
 *   2. Grant the Firebase/App Engine default service account the
 *      "Storage Admin" role on that bucket so the export can write objects.
 *   Without the bucket the function will deploy successfully but every
 *   scheduled run will fail with a "bucket not found" error.
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const BACKUP_BUCKET = "gs://gymratz-b1a32-backups";

/**
 * Runs daily and exports all Firestore collections to GCS.
 * Export path: gs://gymratz-b1a32-backups/exports/YYYY-MM-DD
 *
 * The export is non-destructive — existing exports at the same path will
 * be overwritten only if the date matches (i.e. a re-run on the same day).
 */
export const scheduledFirestoreBackup = onSchedule("every 24 hours", async () => {
  const projectId = process.env.GCLOUD_PROJECT ?? admin.app().options.projectId;
  if (!projectId) {
    logger.error("scheduledFirestoreBackup: GCLOUD_PROJECT is not set — aborting.");
    return;
  }

  const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
  const outputUriPrefix = `${BACKUP_BUCKET}/exports/${today}`;

  logger.info(
    `scheduledFirestoreBackup: starting export for project ${projectId}`,
    {outputUriPrefix}
  );

  try {
    const client = new admin.firestore.v1.FirestoreAdminClient();
    const databaseName = client.databasePath(projectId, "(default)");

    const [operation] = await client.exportDocuments({
      name: databaseName,
      outputUriPrefix,
      // Empty collectionIds means "export everything".
      collectionIds: [],
    });

    logger.info(
      `scheduledFirestoreBackup: export operation started — ${operation.name}`,
      {outputUriPrefix}
    );
  } catch (err) {
    logger.error("scheduledFirestoreBackup: export failed", err);
    // Re-throw so Cloud Functions marks the invocation as failed and
    // Cloud Monitoring / Alerting can trigger on error rate.
    throw err;
  }
});

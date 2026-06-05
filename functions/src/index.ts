import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Auth triggers
export {onUserCreate} from "./auth/onUserCreate";
export {onUserDelete} from "./auth/onUserDelete";
export {onUserRoleUpdate} from "./auth/onUserRoleUpdate";

// Firestore triggers
export {onWorkoutComplete} from "./triggers/onWorkoutComplete";

// Scheduled jobs
export {scheduledFirestoreBackup} from "./backup/scheduledBackup";

// HTTP endpoints (post-beta)
// export {revenueCatWebhook} from "./webhooks/revenueCatWebhook";

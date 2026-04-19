import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK
admin.initializeApp();

// Auth triggers
export {onUserCreate} from "./auth/onUserCreate";
export {onUserDelete} from "./auth/onUserDelete";

// Firestore triggers
export {onWorkoutComplete} from "./triggers/onWorkoutComplete";

// HTTP endpoints (post-beta)
// export {revenueCatWebhook} from "./webhooks/revenueCatWebhook";

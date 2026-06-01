/** Firestore collection names — keep in sync with Flutter client. */
export const COLLECTIONS = {
  USERS: "users",
  WORKOUTS: "workouts",
  PROGRAMS: "programs",
  PRS: "prs",
  ACHIEVEMENTS: "achievements",
  WEIGHT_ENTRIES: "weightEntries",
  EXERCISES: "exercises",
  PROGRESSION: "progression",
} as const;

/** RevenueCat entitlement ID. */
export const ENTITLEMENT_ID = "pro";

/** All subcollections under a user document. */
export const USER_SUBCOLLECTIONS = [
  COLLECTIONS.WORKOUTS,
  COLLECTIONS.PROGRAMS,
  COLLECTIONS.PRS,
  COLLECTIONS.ACHIEVEMENTS,
  COLLECTIONS.WEIGHT_ENTRIES,
  COLLECTIONS.EXERCISES,
  COLLECTIONS.PROGRESSION,
] as const;

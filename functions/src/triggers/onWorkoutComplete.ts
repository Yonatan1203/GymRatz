import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {COLLECTIONS} from "../shared/constants";

/** Achievement definitions — must stay in sync with Flutter client. */
const ACHIEVEMENT_THRESHOLDS: Record<string, {field: string; total: number}> = {
  first_workout: {field: "totalWorkouts", total: 1},
  century_club: {field: "totalWorkouts", total: 100},
  iron_will: {field: "streak", total: 30},
  consistency: {field: "consecutiveWeeks", total: 4},
  volume_king: {field: "totalVolume", total: 100000},
  pr_machine: {field: "prCount", total: 10},
};

/**
 * Firestore trigger: recalculate achievements when a workout is completed.
 *
 * Fires on any update to a workout document. Only processes when
 * the status changes to "completed".
 */
export const onWorkoutComplete = functions.firestore
  .document("users/{uid}/workouts/{workoutId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only process when status changes to "completed"
    if (before.status === "completed" || after.status !== "completed") {
      return;
    }

    const uid = context.params.uid;
    const firestore = admin.firestore();

    functions.logger.info(
      `Workout ${context.params.workoutId} completed by user ${uid}`
    );

    try {
      const stats = await computeUserStats(firestore, uid);
      await updateAchievements(firestore, uid, stats);
    } catch (error) {
      functions.logger.error(
        `Failed to update achievements for user ${uid}:`,
        error
      );
    }
  });

interface UserStats {
  totalWorkouts: number;
  streak: number;
  consecutiveWeeks: number;
  totalVolume: number;
  prCount: number;
  earlyBirdCount: number;
}

/**
 * Compute aggregate stats from all completed workouts for a user.
 */
async function computeUserStats(
  firestore: admin.firestore.Firestore,
  uid: string,
): Promise<UserStats> {
  const workoutsRef = firestore
    .collection(COLLECTIONS.USERS)
    .doc(uid)
    .collection(COLLECTIONS.WORKOUTS);

  // Get all completed workouts ordered by date
  const snapshot = await workoutsRef
    .where("status", "==", "completed")
    .orderBy("date", "desc")
    .get();

  const workouts = snapshot.docs.map((doc) => doc.data());
  const totalWorkouts = workouts.length;

  // Calculate total volume
  let totalVolume = 0;
  for (const w of workouts) {
    totalVolume += (w.totalVolume as number) || 0;
  }

  // Calculate streak (consecutive days with workouts, counting from today backwards)
  const streak = calculateStreak(workouts);

  // Calculate consecutive weeks
  const consecutiveWeeks = calculateConsecutiveWeeks(workouts);

  // Count early bird workouts (completed before 8am)
  let earlyBirdCount = 0;
  for (const w of workouts) {
    if (w.completedAt) {
      const completedDate = new Date(w.completedAt);
      if (completedDate.getHours() < 8) {
        earlyBirdCount++;
      }
    }
  }

  // Count PRs
  const prsSnapshot = await firestore
    .collection(COLLECTIONS.USERS)
    .doc(uid)
    .collection(COLLECTIONS.PRS)
    .get();
  const prCount = prsSnapshot.size;

  return {
    totalWorkouts,
    streak,
    consecutiveWeeks,
    totalVolume,
    prCount,
    earlyBirdCount,
  };
}

/**
 * Calculate current workout streak (consecutive days from most recent workout).
 */
function calculateStreak(
  workouts: FirebaseFirestore.DocumentData[],
): number {
  if (workouts.length === 0) return 0;

  // Get unique workout dates (YYYY-MM-DD)
  const dates = new Set<string>();
  for (const w of workouts) {
    if (w.date) {
      const d = new Date(w.date);
      dates.add(d.toISOString().split("T")[0]);
    }
  }

  const sortedDates = Array.from(dates).sort().reverse();
  if (sortedDates.length === 0) return 0;

  let streak = 1;
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const mostRecent = new Date(sortedDates[0]);
  mostRecent.setHours(0, 0, 0, 0);

  // Allow a 1-day gap (today or yesterday)
  const diffFromToday = Math.floor(
    (today.getTime() - mostRecent.getTime()) / (1000 * 60 * 60 * 24)
  );
  if (diffFromToday > 1) return 0;

  for (let i = 1; i < sortedDates.length; i++) {
    const current = new Date(sortedDates[i]);
    const previous = new Date(sortedDates[i - 1]);
    const diffDays = Math.floor(
      (previous.getTime() - current.getTime()) / (1000 * 60 * 60 * 24)
    );

    if (diffDays === 1) {
      streak++;
    } else {
      break;
    }
  }

  return streak;
}

/**
 * Calculate consecutive weeks with at least one workout.
 */
function calculateConsecutiveWeeks(
  workouts: FirebaseFirestore.DocumentData[],
): number {
  if (workouts.length === 0) return 0;

  // Get the ISO week number for each workout
  const weeks = new Set<string>();
  for (const w of workouts) {
    if (w.date) {
      const d = new Date(w.date);
      const weekKey = getISOWeekKey(d);
      weeks.add(weekKey);
    }
  }

  const sortedWeeks = Array.from(weeks).sort().reverse();
  if (sortedWeeks.length === 0) return 0;

  let consecutiveWeeks = 1;
  for (let i = 1; i < sortedWeeks.length; i++) {
    const currentWeekNum = weekKeyToNumber(sortedWeeks[i]);
    const prevWeekNum = weekKeyToNumber(sortedWeeks[i - 1]);

    if (prevWeekNum - currentWeekNum === 1) {
      consecutiveWeeks++;
    } else {
      break;
    }
  }

  return consecutiveWeeks;
}

/** Get a sortable YYYY-WW key for a date. */
function getISOWeekKey(date: Date): string {
  const d = new Date(date.getTime());
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + 3 - ((d.getDay() + 6) % 7));
  const yearStart = new Date(d.getFullYear(), 0, 1);
  const weekNum = Math.ceil(
    ((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7
  );
  return `${d.getFullYear()}-${String(weekNum).padStart(2, "0")}`;
}

/** Convert YYYY-WW to a single number for comparison. */
function weekKeyToNumber(weekKey: string): number {
  const [year, week] = weekKey.split("-").map(Number);
  return year * 53 + week;
}

/**
 * Update achievement progress and unlock status based on computed stats.
 */
async function updateAchievements(
  firestore: admin.firestore.Firestore,
  uid: string,
  stats: UserStats,
): Promise<void> {
  const achievementsRef = firestore
    .collection(COLLECTIONS.USERS)
    .doc(uid)
    .collection(COLLECTIONS.ACHIEVEMENTS);

  const statsMap: Record<string, number> = {
    totalWorkouts: stats.totalWorkouts,
    streak: stats.streak,
    consecutiveWeeks: stats.consecutiveWeeks,
    totalVolume: stats.totalVolume,
    prCount: stats.prCount,
    earlyBirdCount: stats.earlyBirdCount,
  };

  const batch = firestore.batch();
  let updates = 0;

  for (const [achievementId, config] of Object.entries(ACHIEVEMENT_THRESHOLDS)) {
    const progress = statsMap[config.field] || 0;
    const docRef = achievementsRef.doc(achievementId);

    const updateData: Record<string, unknown> = {progress};
    if (progress >= config.total) {
      updateData.unlocked = true;
      updateData.unlockedDate = new Date().toISOString();
    }

    batch.update(docRef, updateData);
    updates++;
  }

  // Handle early_bird separately (not in the thresholds map above)
  const earlyBirdRef = achievementsRef.doc("early_bird");
  const earlyBirdData: Record<string, unknown> = {
    progress: stats.earlyBirdCount,
  };
  if (stats.earlyBirdCount >= 5) {
    earlyBirdData.unlocked = true;
    earlyBirdData.unlockedDate = new Date().toISOString();
  }
  batch.update(earlyBirdRef, earlyBirdData);

  await batch.commit();
  functions.logger.info(
    `Updated ${updates + 1} achievements for user ${uid}`
  );
}

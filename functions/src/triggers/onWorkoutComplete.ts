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
 * Firestore trigger: incrementally update the user stats document and
 * recalculate achievements when a workout is completed.
 *
 * GYM-71: replaces the previous full-collection scan with an incremental
 * approach. Cumulative counters (totalWorkouts, totalVolume, earlyBirdCount)
 * use FieldValue.increment so they never require a full read. Streak and
 * consecutive-weeks queries are bounded to the last 35 days / 56 days.
 */
export const onWorkoutComplete = functions.firestore
  .document("users/{uid}/workouts/{workoutId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only process when status changes to "completed".
    if (before.status === "completed" || after.status !== "completed") {
      return;
    }

    const uid = context.params.uid;
    const firestore = admin.firestore();

    functions.logger.info(
      `Workout ${context.params.workoutId} completed by user ${uid}`
    );

    try {
      // --- Incremental counters ---
      const volume: number = (after.totalVolume as number) || 0;
      const isEarlyBird =
        after.completedAt != null &&
        new Date(after.completedAt as string).getHours() < 8;

      const statsRef = firestore.collection(COLLECTIONS.USERS).doc(uid);
      await statsRef.set(
        {
          stats: {
            totalWorkouts: admin.firestore.FieldValue.increment(1),
            totalVolume: admin.firestore.FieldValue.increment(volume),
            earlyBirdCount: admin.firestore.FieldValue.increment(
              isEarlyBird ? 1 : 0
            ),
          },
        },
        {merge: true}
      );

      // --- Bounded streak / week queries ---
      const cutoff35 = new Date();
      cutoff35.setDate(cutoff35.getDate() - 35);

      const recentSnap = await firestore
        .collection(COLLECTIONS.USERS)
        .doc(uid)
        .collection(COLLECTIONS.WORKOUTS)
        .where("status", "==", "completed")
        .where("date", ">=", cutoff35.toISOString().split("T")[0])
        .orderBy("date", "desc")
        .get();

      const recentWorkouts = recentSnap.docs.map((d) => d.data());
      const streak = calculateStreak(recentWorkouts);
      const consecutiveWeeks = calculateConsecutiveWeeks(recentWorkouts);

      // --- PR count (small collection, bounded) ---
      const prsSnap = await firestore
        .collection(COLLECTIONS.USERS)
        .doc(uid)
        .collection(COLLECTIONS.PRS)
        .get();
      const prCount = prsSnap.size;

      // --- Read fresh cumulative counters for achievement checks ---
      const userDoc = await statsRef.get();
      const userStats = userDoc.data()?.stats ?? {};
      const totalWorkouts: number = (userStats.totalWorkouts as number) || 0;
      const totalVolume: number = (userStats.totalVolume as number) || 0;
      const earlyBirdCount: number =
        (userStats.earlyBirdCount as number) || 0;

      await updateAchievements(firestore, uid, {
        totalWorkouts,
        streak,
        consecutiveWeeks,
        totalVolume,
        prCount,
        earlyBirdCount,
      });
    } catch (error) {
      functions.logger.error(
        `Failed to update stats/achievements for user ${uid}:`,
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

function calculateStreak(
  workouts: FirebaseFirestore.DocumentData[]
): number {
  if (workouts.length === 0) return 0;

  const dates = new Set<string>();
  for (const w of workouts) {
    if (w.date) dates.add((w.date as string).split("T")[0]);
  }

  const sorted = Array.from(dates).sort().reverse();
  if (sorted.length === 0) return 0;

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const mostRecent = new Date(sorted[0]);
  mostRecent.setHours(0, 0, 0, 0);

  const diffFromToday = Math.floor(
    (today.getTime() - mostRecent.getTime()) / 86400000
  );
  if (diffFromToday > 1) return 0;

  let streak = 1;
  for (let i = 1; i < sorted.length; i++) {
    const diff = Math.floor(
      (new Date(sorted[i - 1]).getTime() - new Date(sorted[i]).getTime()) /
        86400000
    );
    if (diff === 1) streak++;
    else break;
  }
  return streak;
}

function calculateConsecutiveWeeks(
  workouts: FirebaseFirestore.DocumentData[]
): number {
  if (workouts.length === 0) return 0;

  const weeks = new Set<string>();
  for (const w of workouts) {
    if (w.date) weeks.add(getISOWeekKey(new Date(w.date as string)));
  }

  const sorted = Array.from(weeks).sort().reverse();
  let count = 1;
  for (let i = 1; i < sorted.length; i++) {
    if (weekKeyToNumber(sorted[i - 1]) - weekKeyToNumber(sorted[i]) === 1) {
      count++;
    } else break;
  }
  return count;
}

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

function weekKeyToNumber(key: string): number {
  const [year, week] = key.split("-").map(Number);
  return year * 53 + week;
}

async function updateAchievements(
  firestore: admin.firestore.Firestore,
  uid: string,
  stats: UserStats
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

  for (const [id, config] of Object.entries(ACHIEVEMENT_THRESHOLDS)) {
    const progress = statsMap[config.field] || 0;
    const ref = achievementsRef.doc(id);
    const update: Record<string, unknown> = {progress};
    if (progress >= config.total) {
      update.unlocked = true;
      update.unlockedDate = new Date().toISOString();
    }
    batch.update(ref, update);
  }

  const earlyBirdRef = achievementsRef.doc("early_bird");
  const earlyBirdUpdate: Record<string, unknown> = {
    progress: stats.earlyBirdCount,
  };
  if (stats.earlyBirdCount >= 5) {
    earlyBirdUpdate.unlocked = true;
    earlyBirdUpdate.unlockedDate = new Date().toISOString();
  }
  batch.update(earlyBirdRef, earlyBirdUpdate);

  await batch.commit();
  functions.logger.info(`Updated achievements for user ${uid}`);
}

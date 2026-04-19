import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {COLLECTIONS} from "../shared/constants";

/**
 * Default achievements — must stay in sync with
 * AchievementService.defaultAchievements in the Flutter client.
 */
const DEFAULT_ACHIEVEMENTS = [
  {id: "first_workout", title: "First Workout", description: "Complete your first workout", iconName: "trophy", progress: 0, total: 1, unlocked: false, unlockedDate: null, rarity: "Common", points: 10},
  {id: "week_warrior", title: "Week Warrior", description: "Work out 5 days in a week", iconName: "flame", progress: 0, total: 5, unlocked: false, unlockedDate: null, rarity: "Common", points: 25},
  {id: "pr_machine", title: "PR Machine", description: "Set 10 personal records", iconName: "award", progress: 0, total: 10, unlocked: false, unlockedDate: null, rarity: "Rare", points: 50},
  {id: "iron_will", title: "Iron Will", description: "Maintain a 30-day streak", iconName: "target", progress: 0, total: 30, unlocked: false, unlockedDate: null, rarity: "Epic", points: 100},
  {id: "century_club", title: "Century Club", description: "Complete 100 workouts", iconName: "star", progress: 0, total: 100, unlocked: false, unlockedDate: null, rarity: "Epic", points: 150},
  {id: "volume_king", title: "Volume King", description: "Log 100,000 lbs total volume", iconName: "crown", progress: 0, total: 100000, unlocked: false, unlockedDate: null, rarity: "Legendary", points: 200},
  {id: "consistency", title: "Consistency", description: "Work out for 4 consecutive weeks", iconName: "calendar", progress: 0, total: 4, unlocked: false, unlockedDate: null, rarity: "Rare", points: 50},
  {id: "early_bird", title: "Early Bird", description: "Complete 5 workouts before 8am", iconName: "sunrise", progress: 0, total: 5, unlocked: false, unlockedDate: null, rarity: "Common", points: 25},
  {id: "program_complete", title: "Program Complete", description: "Finish an entire program", iconName: "checkCircle", progress: 0, total: 1, unlocked: false, unlockedDate: null, rarity: "Rare", points: 75},
  {id: "legend", title: "Legend", description: "Reach 1000 total points", iconName: "crown", progress: 0, total: 1000, unlocked: false, unlockedDate: null, rarity: "Legendary", points: 500},
];

/**
 * Auth trigger: safety net to initialize achievements for new users.
 *
 * The client creates the user profile and should also initialize achievements,
 * but this function catches edge cases (app crash during sign-up, race conditions).
 * It waits 5 seconds to let the client act first, then fills in any gaps.
 */
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  const firestore = admin.firestore();

  functions.logger.info(`New user created: ${uid}`);

  // Wait for the client to create the profile and achievements
  await new Promise((resolve) => setTimeout(resolve, 5000));

  const achievementsRef = firestore
    .collection(COLLECTIONS.USERS)
    .doc(uid)
    .collection(COLLECTIONS.ACHIEVEMENTS);

  // Check if achievements already exist (client may have initialized them)
  const existing = await achievementsRef.limit(1).get();
  if (!existing.empty) {
    functions.logger.info(
      `Achievements already initialized for user ${uid}, skipping`
    );
    return;
  }

  // Initialize default achievements
  const batch = firestore.batch();
  for (const achievement of DEFAULT_ACHIEVEMENTS) {
    batch.set(achievementsRef.doc(achievement.id), achievement);
  }
  await batch.commit();

  functions.logger.info(
    `Initialized ${DEFAULT_ACHIEVEMENTS.length} achievements for user ${uid}`
  );
});

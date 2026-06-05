#!/usr/bin/env node
/**
 * seed_community.js  (GYM-13)
 *
 * Generates a realistic community dataset for GymRatz:
 *   • N fake users (default 20) with varied profiles
 *   • 3–5 programs each
 *   • 10–30 logged workouts each
 *
 * Usage:
 *   node scripts/seed_community.js [--count 20] [--dry-run] [--project gymratz-b1a32]
 *
 * Options:
 *   --count <n>   Number of users to seed  (default: 20)
 *   --dry-run     Print what would be written without writing to Firestore
 *   --project <id> Firebase project ID (default: gymratz-b1a32)
 *
 * Requirements:
 *   npm install firebase-admin  (one-time, in project root)
 *   firebase login              (CLI must be authenticated)
 */

const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');
const { v4: uuidv4 } = require('uuid');

// ── CLI args ──────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);

function getArg(flag, defaultVal) {
  const idx = args.indexOf(flag);
  if (idx === -1) return defaultVal;
  return args[idx + 1] !== undefined && !args[idx + 1].startsWith('--')
    ? args[idx + 1]
    : defaultVal;
}

const DRY_RUN = args.includes('--dry-run');
const COUNT = parseInt(getArg('--count', '20'), 10);
const PROJECT_ID = getArg('--project', 'gymratz-b1a32');

// ── Realistic data pools ───────────────────────────────────────────────────────

const FIRST_NAMES = [
  'Alex', 'Jordan', 'Morgan', 'Taylor', 'Casey', 'Riley', 'Drew', 'Avery',
  'Cameron', 'Quinn', 'Peyton', 'Hayden', 'Blake', 'Logan', 'Charlie',
  'Sam', 'Jesse', 'Dana', 'Reece', 'Parker', 'Skyler', 'Jamie', 'Rowan',
  'Elliot', 'Spencer', 'Ryan', 'Evan', 'Dylan', 'Micah', 'Kendall',
];

const LAST_NAMES = [
  'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
  'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez',
  'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
];

const EXPERIENCE_LEVELS = ['Beginner', 'Intermediate', 'Advanced'];
const GOALS = ['Build Muscle', 'Get Stronger', 'Lose Fat', 'Improve Endurance'];
const UNITS = ['lbs', 'kg'];
const STYLES = ['Powerlifting', 'Bodybuilding', 'CrossFit', 'Calisthenics', 'General Fitness', null];
const INJURIES = [
  [], [], [], // most users have no injuries
  ['Lower Back'],
  ['Knee'],
  ['Shoulder'],
];

const EXERCISE_NAMES = [
  'Barbell Squat', 'Deadlift', 'Bench Press', 'Overhead Press',
  'Barbell Row', 'Pull-Up', 'Dip', 'Incline Dumbbell Press',
  'Romanian Deadlift', 'Leg Press', 'Cable Row', 'Lat Pulldown',
  'Bicep Curl', 'Tricep Pushdown', 'Dumbbell Shoulder Press',
  'Bulgarian Split Squat', 'Hip Thrust', 'Face Pull',
  'Hanging Leg Raise', 'Plank', 'Box Jump', 'Farmer Carry',
];

const PROGRAM_NAMES_BY_GOAL = {
  'Build Muscle': ['Hypertrophy Block I', 'PPL Volume', 'Upper Lower Split', 'Arnold Programme', 'PHUL'],
  'Get Stronger': ['Starting Strength', '5/3/1 Wendler', 'Texas Method', 'GZCLP', 'Greyskull LP'],
  'Lose Fat': ['HIIT Cardio + Lift', 'Metabolic Circuit', 'Full Body 4x', 'Fat Shred Protocol', 'Cut Phase'],
  'Improve Endurance': ['Endurance Base Build', 'Cardio Conditioning', 'GPP Programme', 'Zone 2 + Strength', 'Aerobic Block'],
};

// ── Helpers ───────────────────────────────────────────────────────────────────

function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomFloat(min, max, decimals = 1) {
  return parseFloat((Math.random() * (max - min) + min).toFixed(decimals));
}

function isoDate(daysAgo) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  return d.toISOString().split('T')[0];
}

function generateInitials(name) {
  return name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase();
}

function generateUser(index) {
  const firstName = pick(FIRST_NAMES);
  const lastName = pick(LAST_NAMES);
  const name = `${firstName} ${lastName}`;
  const email = `${firstName.toLowerCase()}.${lastName.toLowerCase()}${index}@seed.gymratz.test`;
  const level = pick(EXPERIENCE_LEVELS);
  const goal = pick(GOALS);
  const unit = pick(UNITS);
  const isMetric = unit === 'kg';

  const heightCm = randomInt(155, 195);
  const height = isMetric
    ? `${heightCm} cm`
    : `${Math.floor(heightCm / 30.48)}'${Math.round((heightCm % 30.48) / 2.54)}"`;

  const weightBase = isMetric ? randomFloat(55, 110) : randomFloat(120, 240);

  return {
    uid: `seed-user-${uuidv4()}`,
    name,
    initials: generateInitials(name),
    email,
    age: randomInt(18, 45),
    height,
    weight: weightBase,
    unit,
    experienceLevel: level,
    primaryGoal: goal,
    injuries: pick(INJURIES),
    style: pick(STYLES),
    notificationsEnabled: Math.random() > 0.3,
    healthEnabled: Math.random() > 0.7,
    discovery: pick(['Instagram', 'App Store', 'Friend', 'Google', null]),
    favoriteExerciseIds: [],
    favoriteProgramIds: [],
    role: 'user',
    complimentaryPro: false,
    weekStartsOnMonday: Math.random() > 0.2,
    createdAt: new Date(Date.now() - randomInt(30, 365) * 86400000).toISOString(),
    updatedAt: new Date().toISOString(),
  };
}

function generateProgram(uid, goal, index) {
  const names = PROGRAM_NAMES_BY_GOAL[goal] || PROGRAM_NAMES_BY_GOAL['Build Muscle'];
  const name = names[index % names.length];
  const daysOfWeek = pick([
    ['Monday', 'Wednesday', 'Friday'],
    ['Monday', 'Tuesday', 'Thursday', 'Friday'],
    ['Monday', 'Wednesday', 'Friday', 'Saturday'],
    ['Tuesday', 'Thursday', 'Saturday'],
  ]);

  return {
    id: uuidv4(),
    name,
    description: `A ${goal.toLowerCase()} focused program.`,
    isActive: index === 0,
    assignedByCoach: false,
    daysPerWeek: daysOfWeek.length,
    days: daysOfWeek.map((dayOfWeek, di) => ({
      id: uuidv4(),
      dayOfWeek,
      name: `Day ${di + 1}`,
      exercises: Array.from({ length: randomInt(3, 6) }, () => ({
        id: uuidv4(),
        exerciseId: uuidv4(),
        name: pick(EXERCISE_NAMES),
        sets: randomInt(3, 5),
        reps: randomInt(5, 12),
        weight: randomFloat(20, 120),
        restSeconds: pick([60, 90, 120, 180]),
      })),
    })),
    createdAt: new Date(Date.now() - randomInt(10, 180) * 86400000).toISOString(),
    updatedAt: new Date().toISOString(),
  };
}

function generateWorkout(uid, daysAgo) {
  const exerciseCount = randomInt(3, 7);
  const exercises = Array.from({ length: exerciseCount }, () => {
    const name = pick(EXERCISE_NAMES);
    const sets = Array.from({ length: randomInt(3, 5) }, () => ({
      id: uuidv4(),
      reps: randomInt(5, 15),
      weight: randomFloat(20, 150),
      completed: true,
    }));
    const totalVolume = sets.reduce((s, set) => s + set.reps * set.weight, 0);
    return { id: uuidv4(), name, exerciseId: uuidv4(), sets, totalVolume };
  });

  const totalVolume = exercises.reduce((s, e) => s + e.totalVolume, 0);
  const durationSeconds = randomInt(2400, 5400); // 40–90 min

  const date = new Date(Date.now() - daysAgo * 86400000);

  return {
    id: uuidv4(),
    date: date.toISOString().split('T')[0],
    status: 'completed',
    exercises,
    totalVolume,
    duration: durationSeconds,
    completedAt: date.toISOString(),
    notes: Math.random() > 0.8 ? pick(['Felt strong today', 'Tough session', 'New PR on squat!', 'Cardio after', '']) : '',
    createdAt: date.toISOString(),
  };
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function seed() {
  console.log(`\nGymRatz Community Seeder (GYM-13)`);
  console.log(`  Project : ${PROJECT_ID}`);
  console.log(`  Users   : ${COUNT}`);
  console.log(`  Mode    : ${DRY_RUN ? 'DRY RUN (no writes)' : 'LIVE'}\n`);

  if (!DRY_RUN) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId: PROJECT_ID,
    });
  }

  const db = DRY_RUN ? null : getFirestore();
  let totalDocs = 0;

  for (let i = 0; i < COUNT; i++) {
    const user = generateUser(i);

    // Programs
    const programCount = randomInt(3, 5);
    const programs = Array.from({ length: programCount }, (_, pi) =>
      generateProgram(user.uid, user.primaryGoal, pi)
    );

    // Workouts — spread over last 3–6 months, randomised days
    const workoutCount = randomInt(10, 30);
    const workoutDaysPool = Array.from({ length: 180 }, (_, d) => d + 1);
    const chosenDays = workoutDaysPool
      .sort(() => Math.random() - 0.5)
      .slice(0, workoutCount)
      .sort((a, b) => a - b);
    const workouts = chosenDays.map(d => generateWorkout(user.uid, d));

    totalDocs += 1 + programs.length + workouts.length;

    if (DRY_RUN) {
      console.log(`[DRY RUN] User ${i + 1}/${COUNT}: ${user.name} <${user.email}>`);
      console.log(`  uid      : ${user.uid}`);
      console.log(`  level    : ${user.experienceLevel}  goal: ${user.primaryGoal}  unit: ${user.unit}`);
      console.log(`  programs : ${programs.map(p => p.name).join(', ')}`);
      console.log(`  workouts : ${workouts.length} entries`);
      console.log('');
    } else {
      // Write in batches of 500 ops (Firestore limit).
      const userRef = db.collection('users').doc(user.uid);
      await userRef.set(user);

      // Programs
      for (const prog of programs) {
        await userRef.collection('programs').doc(prog.id).set(prog);
      }

      // Workouts
      let batch = db.batch();
      let batchCount = 0;
      for (const w of workouts) {
        batch.set(userRef.collection('workouts').doc(w.id), w);
        batchCount++;
        if (batchCount === 499) {
          await batch.commit();
          batch = db.batch();
          batchCount = 0;
        }
      }
      if (batchCount > 0) await batch.commit();

      console.log(`[${i + 1}/${COUNT}] Seeded ${user.name} (${user.uid}) — ${programs.length} programs, ${workouts.length} workouts`);
    }
  }

  console.log(`\n${DRY_RUN ? '[DRY RUN] Would write' : 'Wrote'} ${totalDocs} documents for ${COUNT} users.\n`);
}

seed().catch(err => {
  console.error('Fatal:', err.message);
  process.exit(1);
});

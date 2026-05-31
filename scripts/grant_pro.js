#!/usr/bin/env node
/**
 * Grant complimentaryPro = true to specified users in Firestore.
 * Run from the GymRatz project root with Firebase CLI authenticated:
 *
 *   node scripts/grant_pro.js
 *
 * Requirements:
 *   npm install firebase-admin   (one-time)
 *   firebase login               (if not already logged in)
 *
 * How it works:
 *   1. Lists all Firebase Auth users to find UIDs by email
 *   2. Sets users/{uid}.complimentaryPro = true in Firestore
 *   3. Prints a summary
 */

const admin = require('firebase-admin');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

// ── Configuration ─────────────────────────────────────────────────────────────

const PROJECT_ID = 'gymratz-b1a32';

// Emails that should get complimentaryPro = true
// Add any new tester emails here
const TESTER_EMAILS = [
  'yonatanglav67@gmail.com',
  // Add more testers below:
  // 'tester2@example.com',
];

// ── Init ──────────────────────────────────────────────────────────────────────

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: PROJECT_ID,
});

const auth = getAuth();
const db   = getFirestore();

// ── Main ──────────────────────────────────────────────────────────────────────

async function grantPro() {
  console.log(`\nGymRatz — Grant complimentaryPro\nProject: ${PROJECT_ID}\n`);

  let granted = 0;
  let notFound = 0;

  for (const email of TESTER_EMAILS) {
    try {
      // Look up UID by email
      const userRecord = await auth.getUserByEmail(email);
      const uid = userRecord.uid;

      // Set complimentaryPro in Firestore
      await db.collection('users').doc(uid).set(
        { complimentaryPro: true },
        { merge: true }
      );

      console.log(`✅  ${email}  →  uid=${uid}  complimentaryPro=true`);
      granted++;
    } catch (err) {
      if (err.code === 'auth/user-not-found') {
        console.log(`⚠️   ${email}  →  not found in Firebase Auth (user hasn't signed up yet)`);
        notFound++;
      } else {
        console.error(`❌  ${email}  →  error: ${err.message}`);
      }
    }
  }

  console.log(`\nDone. ${granted} granted, ${notFound} not found yet.`);
  console.log('Users with complimentaryPro=true get full Pro access without a paid subscription.\n');
  process.exit(0);
}

grantPro().catch(err => {
  console.error('Fatal:', err.message);
  process.exit(1);
});

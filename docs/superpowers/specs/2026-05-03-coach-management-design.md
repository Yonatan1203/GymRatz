# Coach Management Feature — Design Spec

## Overview

Add a coach-level layer to GymRatz that allows coaches to pay for client memberships (bundle tiers of 5/10/20 clients), manage client programs, and monitor client workout data. Clients keep their own accounts and data; the coach relationship is a linkage layer on top.

## Key Decisions

- **Payment model:** Coach buys a team plan via RevenueCat (coach_5, coach_10, coach_20)
- **Account ownership:** Clients always own their own accounts. Coach relationship is a link.
- **Connection method:** Both invite code and email-based invites supported
- **Coach access level:** Full read + write on client data
- **Client-to-coach ratio:** One coach per client only
- **Disconnection:** Only the coach can remove a client
- **Program control:** Coach controls the client's active/main program. Client can create personal (inactive) programs.
- **Coach onboarding:** Application + admin approval required
- **Coach personal workouts:** Not supported. Coach accounts are management-only.
- **Admin accounts:** Test accounts with permanent pro bypass, no special admin panel (just paywall bypass + coach app approval)
- **Client workout visibility:** After completion only (no real-time)
- **Architecture:** Firestore-only (no Cloud Functions for MVP)

---

## Database Schema

### New Collections

```
coaches/{coachUid}/
  profile (document fields):
    displayName: string
    email: string
    bio: string?
    specializations: string[]
    planTier: "coach_5" | "coach_10" | "coach_20"
    clientCount: int
    maxClients: 5 | 10 | 20
    approvedAt: timestamp
    createdAt: timestamp

  clients/{clientUid} (subcollection):
    clientName: string
    clientEmail: string
    linkedAt: timestamp
    inviteMethod: "code" | "email"

  invites/{inviteId} (subcollection):
    code: string (6-char unique)
    clientEmail: string? (null if code-based)
    status: "pending" | "accepted" | "expired"
    createdAt: timestamp
    expiresAt: timestamp

invite_codes/{code} (top-level, for fast lookup):
  coachUid: string
  inviteId: string
  status: "pending" | "accepted" | "expired"

coach_applications/{uid}:
  email: string
  displayName: string
  reason: string
  status: "pending" | "approved" | "rejected"
  createdAt: timestamp
```

### Modified Existing Documents

```
users/{uid}:
  ...existing fields...
  + coachId: string? (null if no coach)
  + coachLinkedAt: timestamp?
  + role: "user" | "coach" | "admin_user" | "admin_coach"

users/{uid}/programs/{programId}:
  ...existing fields...
  + assignedByCoach: bool (default false)
  + coachId: string? (who assigned it)
```

---

## Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isOwner(uid) {
      return request.auth != null && request.auth.uid == uid;
    }

    function isCoachOf(clientUid) {
      return request.auth != null
        && get(/databases/$(database)/documents/users/$(clientUid)).data.coachId == request.auth.uid;
    }

    function isAdmin() {
      return request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['admin_user', 'admin_coach'];
    }

    match /users/{uid} {
      allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
      allow create: if isOwner(uid);
      allow update: if isOwner(uid) || isCoachOf(uid);
      allow delete: if isOwner(uid);

      match /{subcollection}/{docId} {
        allow read: if isOwner(uid) || isCoachOf(uid) || isAdmin();
        allow create, update: if isOwner(uid) || isCoachOf(uid);
        allow delete: if isOwner(uid) || isCoachOf(uid);
      }
    }

    match /coaches/{coachUid} {
      allow read: if isOwner(coachUid) || isAdmin();
      allow create, update: if isOwner(coachUid);

      match /clients/{clientUid} {
        allow read: if isOwner(coachUid) || isAdmin();
        allow create, update, delete: if isOwner(coachUid);
      }

      match /invites/{inviteId} {
        allow read: if isOwner(coachUid) || request.auth != null;
        allow create, update, delete: if isOwner(coachUid);
      }
    }

    match /invite_codes/{code} {
      allow read: if request.auth != null;
      allow create, update, delete: if false; // written by coach via batch with invite
    }

    match /coach_applications/{uid} {
      allow create: if isOwner(uid);
      allow read, update: if isOwner(uid) || isAdmin();
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

**Note on invite_codes:** The coach writes to `invite_codes/{code}` as part of a batch write when creating an invite. The rules above block direct writes — this needs adjustment. Updated rule:

```
match /invite_codes/{code} {
  allow read: if request.auth != null;
  allow create: if request.auth != null
    && request.resource.data.coachUid == request.auth.uid;
  allow update: if request.auth != null; // client updates status on acceptance
  allow delete: if request.auth != null
    && get(/databases/$(database)/documents/invite_codes/$(code)).data.coachUid == request.auth.uid;
}
```

---

## Entitlement Flow

Pro access resolution for a client:

1. Check RevenueCat: client has own active "GymRatz" entitlement? -> pro
2. Check role: admin_user or admin_coach? -> pro
3. Check Firestore: users/{uid}.coachId exists?
   - Yes -> coach has active plan (coach_5/10/20 entitlement)? -> pro
   - No -> free

---

## Role & Permission Model

### Roles

| Role | Firestore value | Description |
|------|----------------|-------------|
| User | `"user"` | Normal client. Default on sign-up. |
| Coach | `"coach"` | Manages clients. Cannot log own workouts. Approved by admin. |
| User Admin | `"admin_user"` | User + permanent pro + can approve coach apps. |
| Coach Admin | `"admin_coach"` | Coach + permanent pro + unlimited clients + can approve coach apps. |

### Permission Matrix

| Action | User | Coach | Admin User | Admin Coach |
|--------|------|-------|------------|-------------|
| Log own workouts | Y | N | Y | N |
| Create own programs | Y | N | Y | N |
| View client data | N | Y (own) | N | Y (all) |
| Assign programs to clients | N | Y | N | Y |
| Remove clients | N | Y | N | Y |
| Generate invites | N | Y | N | Y |
| Join a coach | Y | N | Y | N |
| Apply to become coach | Y | N | Y | N |
| Approve coach applications | N | N | Y | Y |
| Bypass subscription checks | N | N | Y | Y |
| Unlimited client slots | N | N | N | Y |

### Role Assignment

- `user`: Default on sign-up
- `coach`: Admin sets after approving application
- `admin_user`: Manually set in Firestore console
- `admin_coach`: Manually set in Firestore console

---

## Frontend Architecture

### Coach Shell (separate navigation)

Router detects role on auth:
- role == user / admin_user -> normal 5-tab shell
- role == coach / admin_coach -> coach 4-tab shell

Coach bottom nav:
1. Dashboard — stats, recent client activity
2. Clients — roster management
3. Programs — coach's template library
4. Settings — profile, invites, subscription

### Coach Screens

1. **Coach Dashboard** (`/coach/dashboard`)
   - Active clients / max display
   - Workouts completed this week (all clients)
   - Clients with missed workouts
   - Recent activity feed
   - Pending invites count

2. **Clients List** (`/coach/clients`)
   - Client cards: avatar, name, last active date
   - Status: active / inactive (3+ days)
   - Search/filter
   - "Add Client" FAB -> invite options
   - Tap -> Client Detail

3. **Client Detail** (`/coach/clients/:clientUid`)
   - Overview: profile summary, current program, streak, weekly volume
   - Workouts: chronological completed workouts with full set data
   - Programs: active (coach-assigned) + personal (read-only)
   - Progress: PR history, exercise graphs
   - Actions: assign program, remove client

4. **Assign Program** (`/coach/clients/:clientUid/assign`)
   - Select from coach's program templates
   - Preview days/exercises
   - Confirm -> copies to client, sets active, marks assignedByCoach

5. **Coach Programs** (`/coach/programs`)
   - Template library (stored under coaches/{uid}/programs/)
   - Create/edit/delete templates
   - Same editor as client-side
   - "Assign to Client" action

6. **Invite Management** (`/coach/settings/invites`)
   - Pending/accepted/expired invites list
   - Generate code (6-char alphanumeric)
   - Send email invite
   - Revoke pending

7. **Coach Settings** (`/coach/settings`)
   - Profile editing
   - Subscription management
   - Coach application approval (admin only)

### Client-Side Changes

1. **"My Coach" in Profile/Settings**
   - Shows coach name + linked date if linked
   - "Join a Coach" button if not linked -> invite code input screen
   - No disconnect option (coach-only action)

2. **Programs Screen modifications**
   - Coach-assigned program shows "Assigned by [Coach Name]" badge
   - "Set as Active" disabled while coachId != null
   - Client can still create personal inactive programs

3. **Entitlement provider updated**
   - isProProvider checks: own sub OR admin role OR coach-sponsored

4. **Join Coach Screen** (`/join-coach`)
   - 6-char code input
   - Shows coach name for confirmation
   - Accept -> batch write links accounts

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Coach downgrades below current client count | Block downgrade, show "Remove clients first" |
| Coach cancels subscription | Clients lose coach-sponsored pro, keep data |
| Client has own sub + joins coach | Both valid, no conflict |
| Coach at max clients, invite accepted | Reject with "Roster full" message |
| Invite expires (7 days) | Show "Expired, ask coach for new one" |
| Client tries second coach | Blocked: "Already linked to [Coach]" |
| Coach assigns program during active workout | New program effective on next session |
| Coach removes client | Client loses sponsored pro, program stays but unmarked |
| Coach account deleted | All clients get coachId cleared, data intact |
| Duplicate invite codes | UUID-based codes, invite_codes/{code} enforces uniqueness |
| Offline invite acceptance | Firestore queues writes, syncs when online |

---

## Admin Test Accounts (Seed Data)

### User Admin
```json
// Firebase Auth: sign up admin-user@gymratz.app, note UID
// Firestore: users/{admin_user_uid}
{
  "name": "Admin User",
  "email": "admin-user@gymratz.app",
  "role": "admin_user",
  "uid": "{admin_user_uid}",
  "unit": "lbs",
  "experienceLevel": "Advanced",
  "primaryGoal": "Build Muscle"
}
```

### Coach Admin
```json
// Firebase Auth: sign up admin-coach@gymratz.app, note UID
// Firestore: users/{admin_coach_uid}
{
  "name": "Admin Coach",
  "email": "admin-coach@gymratz.app",
  "role": "admin_coach",
  "uid": "{admin_coach_uid}"
}

// Firestore: coaches/{admin_coach_uid}
{
  "displayName": "Admin Coach",
  "email": "admin-coach@gymratz.app",
  "planTier": "coach_20",
  "clientCount": 0,
  "maxClients": 999,
  "approvedAt": "<timestamp>",
  "createdAt": "<timestamp>"
}
```

---

## Configuration Checklist

### Firebase
- [ ] Firebase Auth: verify Google Sign-In enabled
- [ ] Firebase Auth: verify Apple Sign-In enabled
- [ ] Deploy updated Firestore security rules
- [ ] Create Firestore composite indexes (invite_codes by code+status)
- [ ] Create two admin Firebase Auth accounts, note UIDs
- [ ] Seed admin user documents in Firestore

### RevenueCat
- [ ] Replace `RC_APPLE_KEY` placeholder with real key
- [ ] Verify `RC_GOOGLE_KEY` is correct
- [ ] Create `coach_5` subscription product (App Store + Play Store + RevenueCat)
- [ ] Create `coach_10` subscription product
- [ ] Create `coach_20` subscription product
- [ ] Verify `monthly` and `yearly` individual products exist
- [ ] Verify `GymRatz` entitlement exists and all products are attached
- [ ] Decide: reuse `GymRatz` entitlement for coach plans or create `GymRatz_Coach`

### App Store Connect (iOS)
- [ ] Apple Developer account active
- [ ] App registered
- [ ] In-app purchase products created (monthly, yearly, coach_5, coach_10, coach_20)
- [ ] Subscription group configured
- [ ] Sandbox test accounts created

### Google Play Console (Android)
- [ ] Developer account active
- [ ] App registered
- [ ] Subscription products created (same IDs as iOS)
- [ ] License testing emails added

### Build Environment
- [ ] `RC_APPLE_KEY` — real RevenueCat Apple API key
- [ ] `RC_GOOGLE_KEY` — real RevenueCat Google API key
- [ ] `ENV` — set to `dev` for testing
- [ ] Verify `google-services.json` exists in `android/app/`
- [ ] Verify `GoogleService-Info.plist` exists in `ios/Runner/`
- [ ] SHA-1/SHA-256 fingerprints registered in Firebase (for Android Google Sign-In)

---

## Implementation Scope

### New files to create:
- `lib/features/coach/data/coach_repository.dart`
- `lib/features/coach/domain/coach_service.dart`
- `lib/features/coach/presentation/coach_dashboard_screen.dart`
- `lib/features/coach/presentation/clients_screen.dart`
- `lib/features/coach/presentation/client_detail_screen.dart`
- `lib/features/coach/presentation/assign_program_screen.dart`
- `lib/features/coach/presentation/coach_programs_screen.dart`
- `lib/features/coach/presentation/invite_management_screen.dart`
- `lib/features/coach/presentation/coach_settings_screen.dart`
- `lib/features/coach/presentation/coach_application_screen.dart`
- `lib/features/coach/presentation/coach_approval_screen.dart`
- `lib/shared/models/coach_profile.dart`
- `lib/shared/models/coach_invite.dart`
- `lib/shared/models/coach_client.dart`
- `lib/app/providers/coach_providers.dart`
- `lib/app/coach_router.dart`
- `lib/features/coach/presentation/join_coach_screen.dart` (client-side)

### Files to modify:
- `lib/shared/models/user_profile.dart` — add coachId, coachLinkedAt, role
- `lib/shared/models/program.dart` — add assignedByCoach, coachId
- `lib/app/router.dart` — role-based shell switching
- `lib/features/subscription/domain/entitlement_service.dart` — coach-sponsored pro check
- `lib/features/subscription/data/entitlement_repository.dart` — admin bypass
- `lib/app/providers/subscription_providers.dart` — updated isProProvider
- `firestore.rules` — new rules
- `lib/core/constants.dart` — new product IDs

# GymRatz Control Loop

How changes to the GymRatz app are requested, built, tested, and shipped.

The control surface is **Linear** (team `GymRatz` / `GYM`). There is no separate
dashboard — Linear's workflow states are the pipeline, and saved views are the
tabs. **Amos** (the AI operator) implements changes and opens PRs; **Yonatan**
approves at every human-in-the-loop (HITL) gate. Nothing reaches testing or
production without Yonatan's explicit approval.

## Pipeline states

| State | Meaning | Who acts |
|-------|---------|----------|
| **Triage** | New request (Linear, or later WhatsApp) awaiting scoping | Amos scopes |
| **Todo** | Scoped: acceptance criteria + platform/effort labels set | Amos picks up |
| **In Progress** | Branch created, code being written | Amos |
| **In Review** | PR open + CI green — **HITL gate 1 (code)** | Yonatan approves |
| **Ready for Testing** | Approved & merged; queued to build internal/TestFlight | Amos builds |
| **In Testing** | Build live on Play internal + TestFlight — **HITL gate 2 (test)** | Yonatan tests |
| **Ready for Production** | Test-approved — **HITL gate 3 (go-live)** | Yonatan approves |
| **Released** | Live in production on both stores | — |
| Backlog / Canceled / Duplicate / Done | Standard | — |

## Saved views (the tabs)

- **🔴 Needs My Approval** — In Review + In Testing + Ready for Production (the HITL queue)
- **🏗 In Flight** — Triage + In Progress + In Review
- **🧪 Testing** — Ready for Testing + In Testing
- **🚀 Release Queue** — Ready for Production
- **✅ Released** — Released
- **📥 Intake** — Triage + Backlog

## Labels

- `platform:ios` / `platform:android` / `platform:both`
- `source:whatsapp` / `source:linear`
- `needs-approval` (set whenever an issue is parked at a gate), `hotfix`, `blocked`
- `Feature` / `Bug` / `Improvement` (type)

## The loop

1. **Intake** → a request becomes a Linear issue in **Triage** (created by Yonatan
   in Linear today; auto-created from WhatsApp later). Add `source:*`.
2. **Scope** → Amos writes acceptance criteria, sets `platform:*` and effort,
   moves to **Todo**.
3. **Implement** → Amos creates a feature branch in this repo, implements, opens a
   PR, lets CI run, and moves the issue to **In Review** with the PR link + CI
   status. Adds `needs-approval`.
4. **HITL gate 1 (code)** → Yonatan reviews the PR. On approval, the PR is merged
   to `main` and the issue moves to **Ready for Testing**.
5. **Build to test** → a release build runs: Android AAB → Play **internal**
   track (`release.yml`), iOS IPA → **TestFlight** (`ios-release.yml`). Issue →
   **In Testing**, `needs-approval` re-applied.
6. **HITL gate 2 (test)** → Yonatan installs from internal/TestFlight and tests.
   On sign-off, issue → **Ready for Production**.
7. **HITL gate 3 (go-live)** → Yonatan gives the final go. Amos promotes the
   Play internal release to **production** and submits the iOS build for App
   Store release. Issue → **Released**.

## CI workflows (this repo)

- **`pr.yml`** — on every PR: `flutter analyze`, `flutter test`, debug APK build.
- **`release.yml`** — Android AAB build + Play internal upload (on tag `v*` or
  manual dispatch). iOS is intentionally *not* here.
- **`ios-release.yml`** — manual dispatch with a `build_number`; builds, signs
  (App Store Connect API key, automatic signing), and uploads to TestFlight.

## Current automation status

All state transitions are **manual today** — performed by Amos operating the
board (via the Linear API) *after* Yonatan's explicit approval, or by Yonatan
directly. Linear has no native approval gates, so the gates are enforced by this
contract, not by tooling.

**Planned (not yet built):**
- Auto-create Linear issues in Triage from WhatsApp messages.
- An automated dispatcher that picks up `Todo`/approved issues and drives the
  build/promotion steps.
- Store-promotion automation wired to the `Ready for Testing` /
  `Ready for Production` transitions.

Until then, this document is the source of truth for who does what at each step.

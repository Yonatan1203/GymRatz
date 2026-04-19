# GymRatz UI/UX Polish — Design Spec

**Date:** 2026-04-19
**Branch:** `feature/ui-ux-polish` (branched from `feature/production-readiness`)
**Goal:** Elevate the existing app from "functional" to "industry-standard premium" without redesigning. Clean + approachable personality (Hevy structure meets Strava warmth). Both light and dark mode.

**Key constraint:** Use existing Lucide icons from `AppIcons` throughout. No new icon packages.

---

## 1. Color System Update

### New Coral Accent
Add a warm accent color for energy moments alongside the existing teal primary:

- **Light coral:** `#EF6B4A`
- **Dark coral:** `#C4553B` (toned down to avoid glare on dark backgrounds)

Add to `AppColors`:
- `lightCoral`, `darkCoral`
- `lightCoralForeground`, `darkCoralForeground` (white for both)

### Coral Usage Rules
Coral is used **sparingly** for energy and action:
- **Streaks & fire:** Streak counts, flame icons, consecutive day indicators
- **Personal records:** PR badges, new max indicators
- **Key CTAs:** "Start Workout", "Complete", primary action buttons that drive engagement
- **Active badges:** Active program indicator, in-progress states
- **Notifications & badges:** Unread counts, alert indicators

### Teal Stays For
- Navigation active states
- Headers (tint)
- Borders
- Secondary buttons and links
- Icon backgrounds (informational)
- Progress bar fills
- Selected states
- General UI chrome

### Everything Else Unchanged
All existing colors (background, foreground, card, secondary, accent, muted, destructive, chart colors, achievement gradients) remain exactly as they are.

---

## 2. Header System Redesign

### Main Tab Screens (Home, Workout, Calendar, Programs, Profile)
Replace the current `GradientHeader` (full teal gradient, rounded bottom 20r, shadow) with:
- **Background:** Subtle tint — `primary.withOpacity(0.08)` (light) / `primary.withOpacity(0.12)` (dark)
- **Bottom border:** 1px solid `primary.withOpacity(0.12)` (light) / `primary.withOpacity(0.15)` (dark)
- **No rounded corners** — content flows naturally
- **No shadow** — cleaner, more modern
- **Scroll behavior:** Header tint fades to full background color on scroll, creating a "content slides under header" effect

### Detail/Push Screens (Program Detail, Edit Profile, Settings, etc.)
Same subtle tint treatment + back arrow. Consistent with tab screens.

### Hero Screens (Onboarding Welcome, Paywall)
**Keep full gradient treatment.** These are special moments that deserve visual drama. Welcome uses teal gradient, Ready/Paywall uses gradient with coral accents.

### Implementation
Update the existing `GradientHeader` widget to support a `variant` parameter:
- `HeaderVariant.subtle` (default for all screens)
- `HeaderVariant.hero` (for welcome, paywall)

This avoids creating a new widget — just extend the existing one.

---

## 3. Animation System

### Design Principles
- **Duration:** 150-250ms. Subtle and swift — users feel the polish but don't consciously notice animations.
- **Curve:** `Curves.easeOut` as default. No spring physics, no bouncy overshoot.
- **Purpose-driven:** Only animate where it serves UX. Not every element gets an animation.

### Animation Primitives (New Shared Widgets)
Create reusable animation widgets in `lib/shared/widgets/`:

**`FadeIn`** — 200ms, opacity 0→1
- Used for: screen content appearing, cards loading in, empty states
- Parameters: `duration`, `delay`, `child`

**`SlideUp`** — 200ms, translateY 16px→0 + fade
- Used for: content sections appearing on screen load
- Parameters: `duration`, `delay`, `offset`, `child`

**`StaggeredList`** — 50ms delay between items, each child uses SlideUp
- Used for: workout lists, program cards, menu items, stats grids
- Parameters: `delay` (between items), `children`

**`ScaleTap`** — 150ms, scale 1.0→0.97 on press, back to 1.0 on release
- Used for: all tappable cards and buttons (wraps existing onTap)
- Parameters: `onTap`, `child`

**`AnimatedProgress`** — 250ms easeOut, value fills from 0→target
- Used for: program progress bars, onboarding progress, completion rings
- Parameters: `value`, `duration`, `child` (builder pattern)

### Page Transitions
Configure in GoRouter:

- **Tab switching:** Cross-fade (200ms). Tabs are siblings, not a stack.
- **Push navigation:** Shared axis slide-right (250ms). Back = reverse. Standard iOS/Material feel.
- **Modals & bottom sheets:** Slide up from bottom + backdrop fade (200ms).
- **Onboarding steps:** Horizontal slide (next = left, back = right) with content fade. 250ms.

### Micro-Interactions
- **Set completion:** Checkmark animates in + row briefly highlights with coral tint (200ms). Existing haptic stays.
- **Workout complete:** Stats count up from 0 (duration, volume, sets) over 200ms.
- **Bottom nav tap:** Icon scales 1.0→1.15→1.0 (150ms).
- **Theme toggle:** 200ms rotation transition on the sun/moon icon.
- **Pull to refresh:** Custom refresh indicator with rotation animation instead of default spinner.
- **Number animations:** All stats/counters count up from 0 on first appearance (200ms).

### What We're NOT Doing
- No spring physics or bouncy overshoot
- No parallax scrolling
- No hero animations between screens
- No animated backgrounds or particle effects
- No animation on every single element

---

## 4. Unified Screen Template

### The Problem
Each screen currently feels like it was built independently. Card styles, header treatments, content layouts, and interaction patterns vary from screen to screen.

### The Template
Every screen follows the same rhythm:

```
┌─────────────────────────────┐
│  HEADER ZONE                │
│  - Subtle tint background   │
���  - Title (h1) left-aligned  │
│  - Optional action top-right│
│  - Optional subtitle        │
│  - Safe area top: 48r       │
│  - Bottom border            │
├─────────────────────────────┤
│  CONTENT ZONE (scrollable)  │
│  - Screen padding: 24r H    │
│  - Section gap: 24r         │
│  - Each section starts with │
│    SectionHeader widget     │
│  - Cards use xl radius (14r)│
│  - Content animates in with │
│    StaggeredList            │
└─────────────────────────────┘
```

### Spacing Rhythm (Enforced Consistently)
- Between sections: `AppSpacing.sectionGap` (24r)
- Section header → content: `AppSpacing.itemGap` (12r)
- Between cards in a list: `AppSpacing.itemGap` (12r)
- Inside cards: `AppSpacing.cardPadding` (16r)
- Stats grid gap: `AppSpacing.md` (8r)
- Screen horizontal padding: `AppSpacing.screenPadding` (24r)

### Interaction Pattern (Applied Everywhere)
- All tappable cards wrap in `ScaleTap`
- Chevron icon (`AppIcons.chevronRight`) on navigable items
- Haptic feedback on all taps (existing `PlatformAdapter`)

### Screen-by-Screen Application
- **Home:** Header (greeting + streak badge) → Stats grid → Today's workout card → Quick actions → Recent activity
- **Workout:** Header (title + date) → Workout day cards → Weekly stats
- **Calendar:** Header (month nav + completion ring) → Calendar grid → Streak stats → Weight section
- **Programs:** Header (title) → Create CTA → My programs → Explore
- **Profile:** Header (avatar + name + stats) → PRs → Subscription → Menu sections

All follow identical header treatment, spacing, card styling, and animation patterns.

---

## 5. Card Variants

### The Problem
A single `CustomCard` is used everywhere with the same styling. Workout cards look identical to stat cards, program cards, and menu items.

### Card Variant System
Extend `CustomCard` with a `variant` parameter rather than creating new widgets:

**`CardVariant.standard`** (default)
- Card background + border + xl radius
- For: menus, lists, settings, general content

**`CardVariant.workout`**
- Teal left accent bar (3px) + teal-tinted border (`primary.withOpacity(0.25)`)
- Status badge top-right (teal for ready/completed, coral for active)
- Inline mini-stats row at bottom
- For: workout day cards, exercise cards

**`CardVariant.program`**
- Standard card + progress bar at bottom
- Active badge uses coral
- For: program cards in list

**`CardVariant.stat`**
- Compact card for grid layout
- Icon top (using AppIcons), large value center, label bottom
- For: stats grids (3-column layout)

**`CardVariant.actionCta`**
- Coral-tinted background (`coral.withOpacity(0.08)`) + coral border (`coral.withOpacity(0.2)`)
- Coral chevron
- For: "Start Workout", "Create Program", primary action prompts

### Variant Differentiation
Each variant uses the same base `CustomCard` properties (radius, padding, shadow) but adds its own visual identity through border color, accent elements, and background tinting. The differences are subtle but recognizable — users learn which card type does what.

---

## 6. Onboarding Overhaul

### Step Consolidation: 14 → 9 Steps

| New Step | Content | Merged From |
|----------|---------|-------------|
| 1. Welcome | Hero screen — gradient, branding, CTA | Welcome |
| 2. Showcase | App features overview | Showcase |
| 3. Goal + Experience | Two-section screen: goal selection + experience level | Goal, Experience |
| 4. Style + Injury | Training style (multi-select) + injury toggle with detail | Style, Injury |
| 5. Body Metrics | Unit toggle at top, height picker + weight picker below | Units, Height, Weight |
| 6. Health | Health conditions (standalone — sensitive topic) | Health |
| 7. Account | Email + password + notifications permission toggle | Email, Notifications |
| 8. Summary | Profile summary with animated stat reveals | Summary |
| 9. Ready! | Hero screen — coral CTA, "Let's go" | Welcome final |

### Merged Screen Layouts

**Step 3 — Goal + Experience:**
Title "Tell us about yourself" → Goal selection cards (single-select, top section) → visual divider → Experience level cards (single-select, bottom section) → "Continue" button.

**Step 4 — Style + Injury:**
Title "Your training" → Style cards (multi-select with teal highlight) → visual divider → "Any injuries or limitations?" toggle → optional detail text input if toggled on → "Continue" button.

**Step 5 — Body Metrics:**
Title "Your body" → Unit toggle (metric/imperial) positioned top-right of title → Height picker → Weight picker. Both pickers update immediately when unit toggle changes. Fix all unit display formatting bugs.

**Step 7 — Account:**
Title "Create your account" → Email input (mail icon prefix) → Password input (lock icon + eye toggle) → Notifications card with "Allow notifications" toggle (not a separate screen). Single "Create Account" button.

### Visual Improvements

**Transitions:** Horizontal slide between steps (250ms). Forward = slide left, back = slide right. Content fades in after slide completes (150ms).

**Progress bar:** Animated fill between steps (250ms easeOut). 9 segments. Completed = teal, current = coral, upcoming = muted. Animated transition between steps.

**Selection cards:** Tappable cards with teal border highlight + teal tint background (10% opacity) on selection. ScaleTap feedback (0.97). Clear selected vs unselected contrast.

**Content entry animation:** Title slides up first (100ms) → subtitle fades (100ms delay) → options stagger in (50ms each). Quick cascade that creates visual flow.

**Hero screens (1 & 9):** Keep full gradient treatment. Welcome = teal gradient. Ready = includes coral in CTA. These bookend the flow as "wow" moments.

**Unit display fix:** All unit values format correctly for both metric and imperial. Pickers update live on toggle. No display bugs.

---

## 7. Loading, Empty & Error States

### Loading — Skeleton Loaders
Replace all `CircularProgressIndicator` spinners with skeleton loaders:

- Skeleton shapes mirror the content they replace (workout card skeleton looks like a workout card outline)
- Shimmer animation: left→right gradient sweep, 1.5s loop, subtle
- Colors: `muted` for skeleton bars, slightly lighter for shimmer highlight
- Create a `SkeletonLoader` widget with configurable shapes (line, circle, card)
- Each screen provides its own skeleton layout matching its content structure

### Empty States — Enhanced EmptyStateWidget
Update the existing `EmptyStateWidget`:

- Larger icon container: 64px rounded square (16r radius) with 10% tint background + border
- More descriptive copy: explain the value of creating the content, not just "nothing here"
- CTA button uses coral action styling (`CardVariant.actionCta` pattern)
- Staggered entry animation: icon fades in (200ms) → title slides up (150ms) → subtitle fades (100ms) → button slides up (100ms)
- Consistent across all empty states in the app

### Error States
Update error display pattern:

- Icon container uses destructive color tint (same 64px rounded square pattern)
- Specific error messages: "Couldn't load workouts" not "Something went wrong"
- Retry button uses teal styling (errors shouldn't feel exciting)
- Same staggered animation as empty states
- Consistent across all error states

---

## 8. Bottom Navigation Polish

### Current State
Color change only. No animation, no active indicator beyond color.

### Improvements
- **Active indicator:** Teal pill (20px wide, 3px tall) above the active tab icon, positioned at the top of the nav bar. Animated slide between tabs (200ms easeOut).
- **Active icon:** Scale to 1.1. Label font weight bumps from w400 to w600.
- **Tap feedback:** Icon does a quick scale pulse (1.0→1.15→1.0, 150ms) on tap.
- **Colors stay the same:** Active = primary (teal), inactive = mutedForeground. No changes needed.

---

## 9. Color Usage Standardization

### Status Colors (Consistent Across App)
- **Completed:** Teal tint background + teal icon/text
- **Active / In-progress:** Coral tint background + coral icon/text
- **Scheduled / Upcoming:** Muted background + border only
- **Missed:** Orange (keep existing `#F97316`)
- **Rest day:** Card background + subtle border

Applied consistently in: calendar day cells, workout cards, program badges, activity list items.

### Icon Background Pattern
All icon containers follow one pattern:
- 10% opacity tint of the semantic color
- 1px border at 15% opacity of the same color
- Rounded square (10r radius)
- Teal for informational, coral for action/energy, destructive for errors

### Text Hierarchy (3 Levels Only)
- **Primary:** `foreground` — titles, values, important content
- **Secondary:** `mutedForeground` — supporting text, labels, metadata
- **Tertiary:** `mutedForeground` at 60% opacity — timestamps, captions, minor details

No more random opacity values scattered across screens. Enforce these three levels everywhere.

### Interactive States
- **Pressed:** ScaleTap (0.97) + opacity 0.9
- **Disabled:** 40% opacity, no tap response
- **Focused inputs:** Teal border (existing, keep)
- **Selected option:** Teal fill at 10% + teal border

---

## 10. Small Details

- **Dividers:** Replace hard 1px dividers with 8px vertical spacing where possible. Where dividers are needed, use `mutedForeground` at 15% opacity.
- **Safe areas & bottom padding:** Audit all screens for consistent bottom padding that accounts for bottom nav height + safe area. No content cut off.
- **Scroll physics:** Keep existing `AppScrollBehavior`. No changes needed.
- **Theme toggle:** Add 200ms rotation transition to the sun/moon icon swap.

---

## Scope Boundaries

### In Scope
- All changes described above across all existing screens
- Both light and dark mode
- Using existing Lucide icons from `AppIcons` only
- Extending existing widgets (`CustomCard`, `GradientHeader`, `EmptyStateWidget`)
- Creating new animation primitive widgets
- Onboarding step consolidation and visual polish
- Unit display bug fixes in onboarding

### Out of Scope
- No new features or functionality
- No new screens
- No changes to business logic, data models, or API calls
- No new icon packages or fonts
- No changes to the Montserrat typography scale
- No changes to the existing spacing/radius/shadow token values
- No changes to navigation structure (same 5 tabs, same routes)

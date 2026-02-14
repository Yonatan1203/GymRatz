## 1. Progressive Overload Engine (Updated)

### 1.1 Core Inputs (Per Working Set Logged)

For each *working* set (warmups excluded):

- equipmentType: Barbell | Dumbbell | MachineStack | MachinePlateLoaded | Bodyweight 
- weightValue: numeric (kg/lb); for dumbbells store “per-hand” weight; for barbell store “total on bar”
- reps: int
- RIR: 0–10 (reps in reserve)
- isWarmup: boolean (warmups never drive progression)

***

## 2. Session Summary (Per Exercise)

After workout completion (per exercise, using only working sets):

- repsMin = MIN(reps)
- repsAvg = AVG(reps)
- rirMin = MIN(RIR) (most conservative)
- rirAvg = AVG(RIR)


### Range status (based on prescription)

- BelowRange: repsMin < repMin
- InRange: repMin ≤ repsMin ≤ repMax
- AboveRange: repsMin > repMax


### Effort status (based on targetRir)

- rirLow: rirMin < targetRir
- rirOnTarget: targetRir ≤ rirAvg ≤ targetRir+1
- rirHigh: rirAvg > targetRir+1

***

## 3. Load Quantization (Snap Rules)

All load changes must “snap” to what the equipment can actually do.

### 3.1 Barbell (BB) snapping

Use standard plate pairs. Typical Olympic plates include 1.25 kg and 2.5 kg (so the smallest common *total* jump is 2.5 kg by adding 1.25 kg per side).
In pounds, common small plates include 2.5 lb (so the smallest common *total* jump is 5 lb by adding 2.5 lb per side).

**Default BB minIncrementTotal**

- kg gyms: 2.5 kg (1.25 kg/side)
- lb gyms: 5 lb (2.5 lb/side)

(If the user has micro-plates, allow smaller jumps via override.)

### 3.2 Dumbbell (DB) snapping

Dumbbells usually increase in discrete steps; common increment options include 2.5 lb, 5 lb, and 10 lb depending on the set.
**Default DB minIncrementPerHand**

- lb gyms: 5 lb per hand (common fixed dumbbell rack behavior)
- kg gyms: set-dependent; often 2 kg or 2.5 kg per hand in many gyms (make this a per-gym setting / override in the app rather than hardcoding).


### 3.3 Machine (selectorized stack) snapping

Selector stacks move by the plate spacing; machines often progress by 10 lb per plate, with some offering smaller 5 lb or 2.5 lb steps.
**Default MachineStack increment**

- Use the machine’s declared step (user sets it once per machine): 5 lb / 10 lb or 2.5 kg / 5 kg are typical.


### 3.4 Plate-loaded machines

Treat like barbell snapping (available plates determine the step), but note leverage varies by machine—so keep weekly caps conservative.

### 3.5 Bodyweight

“Weight” is body mass plus any added load. If no load is available, progression is reps/sets/variation, not external weight.

***

## 4. Default Progression Rules (MVP, by Equipment)

### 4.1 Barbell (BB) — Big Compounds

**Mode:** LoadFirst (default)

IF InRange AND rirOnTarget:

- nextWeight = snap(currentWeight + BB_minIncrementTotal)
- constrain: do not exceed maxWeeklyIncreasePercent (default 10%)

IF InRange AND rirHigh (or AboveRange):

- nextWeight = snap(currentWeight + bigJumpMultiplier × BB_minIncrementTotal) (default multiplier 2×)

IF BelowRange OR rirLow:

- nextWeight = currentWeight (maintain)
- after 2–3 poor sessions: deload by 1 increment (snap downward)


### 4.2 Dumbbell (DB) — Compounds + Accessories

**Mode:** Mixed (reps → load), because DB jumps are usually bigger *relative* to load.

IF InRange AND rirOnTarget AND repsAvg ≥ repMax−1:

- nextWeightPerHand = snap(currentPerHand + DB_minIncrementPerHand)

ELSE IF InRange:

- keep weight, aim to add reps toward the top of the range

IF BelowRange OR rirLow:

- maintain for up to 3 sessions, then reduce by 1 DB increment if still failing range


### 4.3 Machine (selectorized stack)

**Mode:** RepsFirst → small load step, because increments are fixed and often coarse.

IF repsAvg ≥ repMax AND rirOnTarget:

- nextStack = snap(currentStack + machineStep)

ELSE:

- keep load, add reps (or add a set if user is in “volume priority” block)

IF BelowRange OR rirLow for 2–3 sessions:

- deload 1 step (snap down)


### 4.4 Plate-loaded machines

Use the **Barbell snapping** rules, but the progression behavior can follow “Secondary Compounds” logic (Mixed) unless the user marks it as a true primary lift.

### 4.5 Bodyweight

**Mode:** RepsFirst → Sets → Harder variation → Load (if available).

IF AboveRange AND rirHigh:

- First: increase target rep range (e.g., 8–12 → 10–14)
- Or: add a set (e.g., 3 → 4)
- Or: add load (belt/vest) and then use snapping rules for that load source (DB/plates).

IF BelowRange OR rirLow:

- reduce rep target slightly or regress variation until InRange with targetRir is achievable

***

## 5. Advanced Mode (Per-Exercise Overrides)

User can override per exercise:

- goalPreset: Strength | Hypertrophy | RepsBased 
- repMin/repMax, targetRir
- incrementPolicy: AutoFromEquipment | Custom 
- minIncrement (BB total / DB per-hand / machine step)
- maxWeeklyIncreasePercent (default 10%, adjustable 5–15%)
- rirHighThreshold = targetRir + X; bigJumpMultiplier = 2× or 3×

Preset defaults (same concept, now equipment-aware):

- Strength: 3–6 reps, LoadFirst where possible, RIR 1–3
- Hypertrophy: 6–12 reps, Mixed/RepsFirst on DB/machines, RIR 0–3
- RepsBased: 8–20 reps, RepsFirst, RIR 1–4

***

## 6. Safety Rules (All Equipment)

- Always snap to available jumps (BB plate pairs; DB step; machine plate spacing).
- Cap increases by maxWeeklyIncreasePercent per exercise (default 10%).
- 2–3 poor sessions → auto deload one increment/step.
- Incomplete sessions → no progression change.

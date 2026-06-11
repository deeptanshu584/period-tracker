# Cycle Math – Source of Truth

This file defines every calculation the app performs.
Gemini must not invent formulas. If a calculation is not defined here, ask before implementing.
All logic lives in `lib/domain/cycle_calculator.dart` and `lib/domain/irregularity_detector.dart`.
These are pure Dart classes — zero Flutter, zero Floor imports.

---

## Inputs

| Input                      | Type        | Source                          |
|----------------------------|-------------|---------------------------------|
| `cycles`                   | `List<CycleEntry>` sorted oldest→newest | Floor DAO     |
| `userPrefs.preferredCycleLength` | `int`  | UserPrefs table                 |
| `userPrefs.preferredPeriodLength`| `int`  | UserPrefs table                 |
| `today`                    | `DateTime`  | passed in, never use `DateTime.now()` inside domain classes |

> **Rule:** Domain classes never call `DateTime.now()` directly.
> The caller passes `today` as a parameter. This makes every function unit-testable
> without time-dependent mocking.

---

## Step 1 — Sanitize the Cycle List

Before any calculation, sanitize the raw list from the DB.

```
sanitize(cycles):
  1. Sort by startDate ascending (oldest first).
  2. Remove any entry where startDate is in the future (startDate > today).
  3. For each entry with no endDate:
       effectiveEndDate = min(today, startDate + 6 days)
       (this is the 7-day auto-cap: day 1 through day 7 = 6 days after start)
  4. Remove duplicate startDates — keep only the most recently created entry.
  5. Return the cleaned list.
```

The sanitized list is used for all calculations below. Never operate on the raw list.

---

## Step 2 — Compute Cycle Gaps

A cycle gap is the number of days from one period's start to the next period's start.
This is NOT the same as period duration.

```
computeGaps(sanitizedCycles):
  gaps = []
  for i from 1 to len(sanitizedCycles) - 1:
    gap = sanitizedCycles[i].startDate − sanitizedCycles[i-1].startDate  (in days)
    if gap >= 20 AND gap <= 45:
      gaps.append(gap)
    else:
      // Implausible gap — skip it entirely, do not clamp
      // Log a debug warning but do not surface to user
  return gaps
```

**Why skip instead of clamp?**
A 10-day gap means the user accidentally logged a duplicate or made a data entry error.
Using 10 days in the average would corrupt all predictions. It is better to ignore it.

---

## Step 3 — Rolling Average Cycle Length

```
rollingAverage(gaps, window = 3):
  if len(gaps) == 0:
    return userPrefs.preferredCycleLength   // fallback
  useGaps = gaps.takeLast(window)           // at most last 3 gaps
  return sum(useGaps) / len(useGaps)        // plain mean, not rounded
```

The result is a `double`, not an `int`. Keep the decimal for downstream math.
Only round when displaying to the user ("28.5 days").

---

## Step 4 — Predict Next Period Start

```
predictNextPeriodStart(sanitizedCycles, averageCycleLength):
  if sanitizedCycles is empty:
    return today + averageCycleLength days   // best guess with no history

  lastStart = sanitizedCycles.last.startDate
  return lastStart + averageCycleLength days (rounded to nearest whole day)
```

Rounding rule: `(lastStart + averageCycleLength).round()` — use `Duration(days: averageCycleLength.round())`.

---

## Step 5 — Ovulation Day

```
ovulationDay = nextPeriodStart − 14 days
```

This is the standard luteal phase estimate. It is always exactly 14 days before
the predicted period start. Do not make this configurable.

---

## Step 6 — Fertile Window

```
fertileWindowStart = ovulationDay − 5 days
fertileWindowEnd   = ovulationDay          // inclusive
```

The fertile window is 6 days total: 5 days before ovulation plus ovulation day itself.

---

## Step 7 — Current Cycle Day

```
currentCycleDay(sanitizedCycles, today):
  if sanitizedCycles is empty:
    return null

  lastStart = sanitizedCycles.last.startDate
  day = today − lastStart + 1     // day 1 = the start date itself
  return day
```

If `day > averageCycleLength + 14`, the period is significantly late.
Surface this as "late" on the HomeScreen — do not call it a new cycle automatically.

---

## Step 8 — Period Duration

```
periodDuration(entry):
  if entry.endDate is not null:
    return entry.endDate − entry.startDate + 1    // inclusive of both ends
  else:
    elapsed = today − entry.startDate
    return clamp(elapsed + 1, 1, 7)               // auto-cap at 7 days
```

Note: `+1` is intentional. A period that starts and ends on the same day = 1 day, not 0.

---

## Step 9 — Average Period Duration

```
averagePeriodDuration(sanitizedCycles):
  durations = [periodDuration(c) for c in sanitizedCycles if c.endDate is not null]
  if durations is empty:
    return userPrefs.preferredPeriodLength    // fallback
  return sum(durations) / len(durations)
```

Only use entries with a confirmed `endDate` for this average.
Open/ongoing entries use the auto-cap value for display but are excluded from the average.

---

## Edge Cases — All Must Be Handled

| Scenario | Expected Behaviour |
|---|---|
| 0 cycles logged | All predictions use `userPrefs.preferredCycleLength`. `cyclesUsedForPrediction = 0`. |
| 1 cycle logged | 0 gaps available. Fallback to `preferredCycleLength`. `cyclesUsedForPrediction = 1` but gap count = 0. |
| 2 cycles logged | 1 gap available. Average = that single gap (if plausible). `cyclesUsedForPrediction = 2`. |
| 3+ cycles logged | Use last 3 gaps. Standard rolling average. |
| All gaps implausible | Fallback to `preferredCycleLength`. Same as 0 cycles case. |
| No `endDate` on latest entry | Period is "ongoing". Use auto-cap for duration display. Exclude from gap calc. |
| Duplicate `startDate` entries | Keep most recently created. Discard duplicate before gap calc. |
| Gap < 20 days | Skip gap entirely. Do not clamp to 20. |
| Gap > 45 days | Skip gap entirely. Do not clamp to 45. |
| `nextPeriodStart` is in the past | Still valid. Show as "X days late" not as an error. |
| Single cycle with no `endDate` | Duration shown as capped value. No gap. Predictions use fallback. |

---

## Irregularity Detection

Implemented in `IrregularityDetector`, separate from `CycleCalculator`.

```
detectIrregularity(gaps, rollingAverage):
  if len(gaps) < 2:
    return CycleRegularity.insufficientData

  lookback = gaps.takeLast(6)
  irregularCount = count of gaps where |gap − rollingAverage| > 7

  if irregularCount >= 2:  return CycleRegularity.irregular
  if irregularCount == 1:  return CycleRegularity.slightlyIrregular
  else:                    return CycleRegularity.regular
```

### Explanation string

```
buildExplanation(gaps, rollingAverage):
  lastGap = gaps.last
  diff = lastGap − rollingAverage

  if diff > 0:  "Your last cycle was {diff.round()} days longer than your average."
  if diff < 0:  "Your last cycle was {diff.abs().round()} days shorter than your average."
  if diff == 0: "Your last cycle matched your average exactly."
```

Never use: "abnormal", "irregular period", "health concern", "warning".
Allowed: "longer than average", "shorter than average", "slightly irregular", "irregular".

---

## Worked Examples

### Example A — Standard case (3 cycles)

```
Cycles logged:
  Cycle 1: start = Jan 1
  Cycle 2: start = Jan 29  → gap = 28 days
  Cycle 3: start = Feb 25  → gap = 27 days
  Cycle 4: start = Mar 24  → gap = 27 days

Gaps = [28, 27, 27]
Rolling average (last 3) = (28 + 27 + 27) / 3 = 27.33 days

Last start = Mar 24
Next period start = Mar 24 + 27 days = Apr 20
Ovulation day     = Apr 20 − 14     = Apr 6
Fertile window    = Apr 1 – Apr 6

Current cycle day (if today = Apr 2) = Apr 2 − Mar 24 + 1 = 10
```

---

### Example B — Only 1 cycle (fallback)

```
Cycles logged:
  Cycle 1: start = Mar 1  (no end date)

userPrefs.preferredCycleLength = 28

Gaps = []  (need 2 starts to get 1 gap)
Rolling average = preferredCycleLength = 28  (fallback)

Last start = Mar 1
Next period start = Mar 1 + 28 = Mar 29
Ovulation day     = Mar 29 − 14 = Mar 15
Fertile window    = Mar 10 – Mar 15

cyclesUsedForPrediction = 1, but gap count = 0, so fallback label shown on UI.
```

---

### Example C — Implausible gap skipped

```
Cycles logged:
  Cycle 1: start = Jan 1
  Cycle 2: start = Jan 8   → gap = 7 days  ← IMPLAUSIBLE, skip
  Cycle 3: start = Feb 5   → gap = 28 days ← valid
  Cycle 4: start = Mar 5   → gap = 28 days ← valid

Gaps after sanitize = [28, 28]
Rolling average (last 3, but only 2 available) = (28 + 28) / 2 = 28.0
```

---

### Example D — Ongoing period, duration cap

```
Cycle logged:
  start = Apr 1, endDate = null
  today = Apr 10

elapsed = Apr 10 − Apr 1 = 9 days
durationDays = clamp(9 + 1, 1, 7) = 7   ← capped

This entry is excluded from gap calculations.
It IS displayed in history with duration = 7 days (with a note: "auto-capped").
```

---

### Example E — Irregularity detection

```
Gaps = [28, 27, 29, 28, 19, 38]
Rolling average of last 3 = (28 + 19 + 38) / 3 = 28.33

Lookback (last 6) = [28, 27, 29, 28, 19, 38]
Deviations from 28.33:
  28 → |28 − 28.33| = 0.33  ✓ regular
  27 → |27 − 28.33| = 1.33  ✓ regular
  29 → |29 − 28.33| = 0.67  ✓ regular
  28 → |28 − 28.33| = 0.33  ✓ regular
  19 → |19 − 28.33| = 9.33  ✗ irregular  (> 7)
  38 → |38 − 28.33| = 9.67  ✗ irregular  (> 7)

irregularCount = 2 → CycleRegularity.irregular

Last gap = 38, diff = 38 − 28.33 = 9.67 ≈ 10
Explanation: "Your last cycle was 10 days longer than your average."
```

---

## Function Signatures (Dart)

```dart
// lib/domain/cycle_calculator.dart

class CycleCalculator {

  static List<CycleEntry> sanitize(List<CycleEntry> cycles, DateTime today);

  static List<int> computeGaps(List<CycleEntry> sanitizedCycles);

  static double rollingAverage(List<int> gaps, {int window = 3, required int fallback});

  static DateTime predictNextPeriodStart(
      List<CycleEntry> sanitizedCycles, double averageCycleLength, DateTime today);

  static DateTime ovulationDay(DateTime nextPeriodStart);

  static DateTime fertileWindowStart(DateTime ovulationDay);

  static DateTime fertileWindowEnd(DateTime ovulationDay);

  static int? currentCycleDay(List<CycleEntry> sanitizedCycles, DateTime today);

  static int periodDuration(CycleEntry entry, DateTime today);

  static double averagePeriodDuration(List<CycleEntry> sanitizedCycles,
      DateTime today, {required int fallback});

  static PredictionResult predict(
      List<CycleEntry> rawCycles, UserPrefs prefs, DateTime today);
  // predict() is the single public entry point — calls all of the above in order.
}
```

```dart
// lib/domain/irregularity_detector.dart

class IrregularityDetector {

  static CycleRegularity detect(List<int> gaps, double rollingAverage);

  static String buildExplanation(List<int> gaps, double rollingAverage);
}
```

---

## What Gemini Must Not Do

- Do not call `DateTime.now()` inside any domain class. Always use the `today` parameter.
- Do not round `averageCycleLength` before passing it to `predictNextPeriodStart`. Round only at the final `Duration` conversion.
- Do not use `endDate` of one entry as the `startDate` proxy for the next cycle. Gaps are always start-to-start.
- Do not average period durations using the auto-capped value of open entries.
- Do not skip implausible gaps silently without a debug log.
- Do not surface raw gap values or internal irregularity scores to the user.

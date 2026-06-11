# Period Tracker – Gemini CLI Context File

## Project Overview

A **privacy-first, fully offline** period and cycle tracking app built with Flutter.
There is no backend, no cloud sync, no accounts, and no telemetry of any kind.
All data lives on-device, encrypted. This is a personal health tool — not a platform.

---

## Tech Stack

| Layer             | Technology                                      |
|-------------------|-------------------------------------------------|
| Framework         | Flutter (Dart)                                  |
| Local DB          | Floor (Room-like ORM) with SQLCipher encryption |
| State Management  | Bloc (Events → Bloc → States, no logic in UI)  |
| Notifications     | flutter_local_notifications (local only)        |
| Secure Storage    | flutter_secure_storage (DB key storage)         |
| Storage policy    | On-device only. Zero network calls, ever.       |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/        # All magic numbers live here, nowhere else
│   ├── utils/            # Date helpers, formatting, cycle math utilities
│   └── errors/           # Custom Failure types, Either helpers
├── data/
│   ├── models/           # Dart data classes: CycleEntry, CycleRating, UserPrefs, PredictionResult
│   ├── repositories/     # Abstract interfaces only
│   └── local/            # Floor DAOs, AppDatabase, encryption bootstrap
├── domain/
│   ├── cycle_calculator.dart     # Pure math — no Flutter/DB imports
│   └── irregularity_detector.dart
├── features/
│   ├── onboarding/       # First-launch seed flow
│   ├── log_period/       # Log start / end date + rating + note
│   ├── history/          # Scrollable list of all past cycles
│   ├── calendar/         # Color-coded month view
│   ├── insights/         # Stats panel: avg length, regularity score, etc.
│   └── settings/         # Cycle length preference, notification lead time
├── notifications/
│   └── notification_scheduler.dart  # Schedules local-only reminders
└── main.dart
```

---

## Feature Specifications

### 1. Onboarding (first launch only)

Shown once on fresh install. Collects seed data so predictions work immediately.

**Steps:**
1. "When did your last period start?" — date picker, defaults to today − 28 days.
2. "How long are your cycles usually?" — number input, default 28, range 20–45.
3. "How long does your period usually last?" — number input, default 5, range 1–10.
4. Save as `UserPrefs` and a single seed `CycleEntry` (no end_date required).

After onboarding, never show this screen again. Provide an edit path via Settings.

---

### 2. Period Logging

User can log a period from the home screen or calendar.

**Fields:**
- `start_date` — required, date picker
- `end_date` — optional, date picker. If skipped: auto-cap at 7 days in calculations.
- `rating` — optional, see CycleRating model below
- `notes` — optional, free-text string, max 500 chars

**Rules:**
- Do not allow a start_date in the future.
- Do not allow end_date before start_date.
- If a period is already open (no end_date), prompt to close it before starting a new one.
- Editing and deleting past entries must be supported.

---

### 3. Cycle History

A scrollable list of all logged cycles, newest first.

**Each row shows:**
- Start date (formatted: "12 Jan 2025")
- End date or "Ongoing"
- Duration in days
- Comfort rating icon (if logged)
- Tap to expand: shows full rating breakdown + note

This screen is read-only browsing. Edit/delete via a long-press or icon button.

---

### 4. Calendar View

A full monthly calendar with color-coded day types.

| Day Type          | Color Role     | Notes                              |
|-------------------|----------------|------------------------------------|
| Period (logged)   | Primary/Red    | Solid fill                         |
| Period (predicted)| Primary/Muted  | Dashed border or lighter fill      |
| Fertile window    | Accent/Green   | Subtle tint                        |
| Ovulation day     | Accent/Green   | Stronger tint or dot marker        |
| Today             | Neutral        | Circle outline                     |

Tapping a day: show a bottom sheet with what that day represents.
Allow swiping between months. Do not render future months beyond 3 months out.

---

### 5. Cycle Predictions (displayed on home + calendar)

```
Average Cycle Length  = rolling mean of last 3 logged cycle gaps (start-to-start)
Next Period Start      = last period start + average cycle length
Ovulation Day          = next period start − 14
Fertile Window Start   = ovulation day − 5
Fertile Window End     = ovulation day
```

If fewer than 2 cycles are logged, use `userPrefs.preferredCycleLength` as the average.

---

### 6. Insights / Stats Panel

Show the following computed stats, updated live from DB:

| Stat                    | Formula / Source                                      |
|-------------------------|-------------------------------------------------------|
| Average cycle length    | Rolling mean of all recorded cycle gaps               |
| Average period duration | Mean of all logged period durations                   |
| Shortest cycle          | Min gap across all history                            |
| Longest cycle           | Max gap across all history                            |
| Cycle regularity        | See Irregularity Detector below                       |
| Total cycles logged     | Count of CycleEntry rows                              |

Display as a card list, not a chart (keeps it simple, no charting library needed).

---

### 7. Cycle Rating

Attached optionally to any logged period. Stored in `CycleRating` linked to `CycleEntry`.

**Rating fields:**

```dart
class CycleRating {
  final int cycleEntryId;         // FK to CycleEntry
  final int comfortLevel;         // 1 (fine) to 5 (very uncomfortable)
  final bool hadCramps;
  final bool hadHeadache;
  final bool hadMoodSwings;
  final bool hadBloating;
  final FlowLevel flowLevel;      // enum: light | medium | heavy
}

enum FlowLevel { light, medium, heavy }
```

UI: a simple form with a 1–5 comfort slider, toggle chips for symptoms, and a flow selector.
All fields optional — user can submit with none filled.

---

### 8. User Preferences (Settings screen)

Stored in `UserPrefs` table (single row, always upserted, never deleted).

```dart
class UserPrefs {
  final int preferredCycleLength;   // default 28, range 20–45
  final int preferredPeriodLength;  // default 5, range 1–10
  final int notificationLeadDays;   // how many days before to notify, default 2, range 1–5
  final bool notificationsEnabled;  // master toggle
}
```

Settings screen exposes:
- Cycle length picker (stepper or slider, 20–45)
- Period length picker (stepper, 1–10)
- Notification toggle
- Notification lead time picker (1–5 days), shown only when notifications are enabled

`preferredCycleLength` is used as the prediction fallback when history is insufficient.
It does NOT override the rolling average once 2+ cycles are logged.

---

### 9. Notifications (Local Only)

Use `flutter_local_notifications`. Never use FCM, APNs cloud delivery, or any remote push.

**Trigger:** After any period is logged or any setting changes, reschedule the next reminder.

```
Notification date = predictedNextPeriodStart − userPrefs.notificationLeadDays
Notification time = 09:00 local time
Title: "Period incoming"
Body:  "Your period is expected in X days."
```

**Rules:**
- Cancel and reschedule on every prediction update.
- If notifications are disabled in settings, cancel all pending notifications.
- Request permission on first enable, handle denial gracefully (no crash, show in-app message).
- Do not schedule notifications more than 60 days in advance.

---

### 10. Irregular Cycle Detection

Computed in `IrregularityDetector`, a pure Dart class.

**Definition of irregular:** a cycle gap that deviates from the user's rolling average by more than ±7 days.

**Algorithm:**
1. Compute `rollingAverage` from last 3 cycles.
2. For each of the last 6 cycle gaps, check if `|gap − rollingAverage| > 7`.
3. If 2 or more of the last 6 gaps are irregular → mark as `CycleRegularity.irregular`.
4. If 1 gap is irregular → `CycleRegularity.slightlyIrregular`.
5. Otherwise → `CycleRegularity.regular`.

**Surface it as:**
- A regularity badge on the Insights screen ("Regular ✓", "Slightly Irregular", "Irregular").
- A one-line explanation: "Your last cycle was 8 days longer than your average."
- Never use alarming language. Do not use the word "abnormal". Suggest seeing a doctor only in settings/help copy, not inline.

---

## Data Models (complete)

### `CycleEntry`

```dart
@Entity(tableName: 'cycle_entries')
class CycleEntry {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final DateTime startDate;        // stored as UTC ISO-8601 string
  final DateTime? endDate;         // nullable
  final String? notes;             // max 500 chars
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed — never stored in DB
  int get durationDays {
    if (endDate != null) return endDate!.difference(startDate).inDays + 1;
    final elapsed = DateTime.now().difference(startDate).inDays;
    return elapsed.clamp(1, 7);
  }

  bool get isOngoing => endDate == null;
}
```

### `CycleRating`

```dart
@Entity(tableName: 'cycle_ratings',
        foreignKeys: [ForeignKey(entity: CycleEntry, parentColumns: ['id'],
                                 childColumns: ['cycleEntryId'],
                                 onDelete: ForeignKeyAction.cascade)])
class CycleRating {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int cycleEntryId;
  final int comfortLevel;      // 1–5
  final bool hadCramps;
  final bool hadHeadache;
  final bool hadMoodSwings;
  final bool hadBloating;
  final String flowLevel;      // 'light' | 'medium' | 'heavy' stored as string
}
```

### `UserPrefs`

```dart
@Entity(tableName: 'user_prefs')
class UserPrefs {
  @PrimaryKey()
  final int id = 1;            // always single row

  final int preferredCycleLength;
  final int preferredPeriodLength;
  final int notificationLeadDays;
  final bool notificationsEnabled;
  final bool onboardingComplete;
}
```

### `PredictionResult` (not stored — computed on demand)

```dart
class PredictionResult {
  final DateTime nextPeriodStart;
  final DateTime ovulationDay;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final double averageCycleLength;
  final int cyclesUsedForPrediction; // 0 = used userPrefs fallback
  final CycleRegularity regularity;
}

enum CycleRegularity { regular, slightlyIrregular, irregular, insufficientData }
```

---

## Core Constants

```dart
// lib/core/constants/cycle_constants.dart
const int kDefaultCycleLength        = 28;
const int kDefaultPeriodDuration     = 5;
const int kRollingAverageWindow      = 3;
const int kMaxPeriodDurationFallback = 7;
const int kMinPlausibleCycleLength   = 20;
const int kMaxPlausibleCycleLength   = 45;
const int kIrregularityThresholdDays = 7;
const int kIrregularityLookbackCycles = 6;
const int kMaxNotificationLeadDays   = 5;
const int kMaxFutureNotificationDays = 60;
const int kNotificationHour          = 9;   // 09:00 local
const int kMaxNoteLength             = 500;
```

---

## Privacy Constraints — Non-Negotiable

- **Zero network calls.** No HTTP client anywhere. No package that phones home.
- **No Firebase, Sentry, Mixpanel, Crashlytics, or any analytics SDK.**
- **Database encrypted** via SQLCipher. Encryption key stored in `flutter_secure_storage`.
- **Disable cloud backup** for the DB file: set `NSFileProtectionComplete` on iOS, exclude from Android Auto Backup via `backup_rules.xml`.
- **Notifications are local only.** `flutter_local_notifications` with no cloud delivery path.
- **Data export is opt-in, user-initiated**, with a clear confirmation dialog before any file is written. (Post-MVP feature — do not implement until explicitly requested.)

---

## Coding Conventions

- **Dart style:** `dart format` + `flutter_lints`. No `// ignore` without an inline explanation.
- **Immutability:** All models are immutable. Use `copyWith` for updates.
- **Pure domain logic:** `CycleCalculator` and `IrregularityDetector` are plain Dart classes. Zero Flutter or Floor imports. 100% unit-testable without mocks.
- **Bloc pattern:** Events → Bloc → States. Widgets only dispatch events and render states.
- **Date storage:** Always store and compute in UTC. Convert to local time only in the UI layer (formatting).
- **Error handling:** All repository methods return `Either<Failure, T>`. No silent catch blocks.
- **No magic numbers** outside of `core/constants/cycle_constants.dart`.
- **Cascade deletes:** Deleting a `CycleEntry` must cascade-delete its `CycleRating`.

---

## What NOT to Build

- No user accounts, auth, or registration.
- No cloud sync of any kind.
- No pregnancy mode or conception planning.
- No social / sharing features.
- No remote push notifications (FCM, APNs cloud).
- No AI/ML model calls — all predictions are deterministic math.
- No ads, paywalls, or in-app purchases.
- No symptom tracking beyond the `CycleRating` fields defined above.

---

## Testing Expectations

**`CycleCalculator` unit tests:**
- 0 cycles → uses `userPrefs.preferredCycleLength`
- 1 cycle → uses `userPrefs.preferredCycleLength` (not enough for a gap)
- 2 cycles → computes 1 gap, uses it
- 3 cycles → correct rolling average of 2 gaps
- Missing `end_date` → capped at 7 days, entry excluded from gap calculation
- Implausible gap (< 20 or > 45 days) → clamped, not excluded
- `preferredCycleLength` does NOT override rolling average when 2+ cycles exist

**`IrregularityDetector` unit tests:**
- All gaps within ±7 of average → `regular`
- One gap outside ±7 → `slightlyIrregular`
- Two or more gaps outside ±7 in last 6 → `irregular`
- Fewer than 2 cycles → `insufficientData`

**Bloc tests:**
- `LogPeriodBloc`: start → in-progress → saved state transitions
- `HistoryBloc`: loads entries sorted newest-first
- `SettingsBloc`: updating prefs triggers notification reschedule

---

## Glossary

| Term               | Definition                                                              |
|--------------------|-------------------------------------------------------------------------|
| Cycle              | Span from one period's start date to the next period's start date       |
| Cycle Gap          | `nextStart − prevStart` in days — input to rolling average              |
| Period Duration    | Days of active bleeding (`endDate − startDate + 1`, inclusive)          |
| Rolling Average    | Mean of the last 3 cycle gaps (or fewer if history is short)            |
| Ovulation Day      | `nextPeriodStart − 14`                                                  |
| Fertile Window     | `ovulationDay − 5` through `ovulationDay` (6 days inclusive)           |
| Seed Entry         | The single CycleEntry created during onboarding to bootstrap predictions|
| Irregularity       | A cycle gap deviating from rolling average by more than ±7 days        |
| Preferred Length   | User-set cycle length from Settings; used only as prediction fallback   |

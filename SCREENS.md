# Period Tracker – Screen Map

This file defines every screen in the app: its route, the Bloc that powers it,
all UI states it must handle, what widgets it contains, and how it connects to
other screens. Gemini should never create a new screen without checking this file first.

---

## Navigation Structure

```
App Launch
 └── OnboardingScreen         (shown once, if onboardingComplete == false)
      └── [completes] ──────► MainShell (BottomNavigationBar)
                                  ├── Tab 0: HomeScreen
                                  ├── Tab 1: CalendarScreen
                                  ├── Tab 2: HistoryScreen
                                  └── Tab 3: InsightsScreen

From HomeScreen:
 └── FAB ──────────────────► LogPeriodSheet (modal bottom sheet)
                                  └── [optional] RatingSheet (pushed on top)

From HistoryScreen:
 └── Tap row ──────────────► CycleDetailSheet (modal bottom sheet, read-only)
 └── Edit icon ────────────► LogPeriodSheet (pre-filled for edit)

From CalendarScreen:
 └── Tap day ──────────────► DayDetailSheet (modal bottom sheet)
 └── FAB (if no open period)► LogPeriodSheet

From MainShell (top-right icon):
 └── Settings icon ────────► SettingsScreen (pushed, not a tab)
```

Bottom sheets are modal — they do NOT have their own routes. They are shown with
`showModalBottomSheet`. Do not push them as named routes.

---

## Screen Index

| # | Screen / Sheet         | Route Name         | Bloc(s)                          |
|---|------------------------|--------------------|----------------------------------|
| 1 | OnboardingScreen       | `/onboarding`      | `OnboardingBloc`                 |
| 2 | MainShell              | `/`                | none (shell only)                |
| 3 | HomeScreen             | tab index 0        | `HomeBloc`                       |
| 4 | CalendarScreen         | tab index 1        | `CalendarBloc`                   |
| 5 | HistoryScreen          | tab index 2        | `HistoryBloc`                    |
| 6 | InsightsScreen         | tab index 3        | `InsightsBloc`                   |
| 7 | SettingsScreen         | `/settings`        | `SettingsBloc`                   |
| 8 | LogPeriodSheet         | modal bottom sheet | `LogPeriodBloc`                  |
| 9 | RatingSheet            | modal bottom sheet | `LogPeriodBloc` (shared)         |
|10 | CycleDetailSheet       | modal bottom sheet | `HistoryBloc` (shared)           |
|11 | DayDetailSheet         | modal bottom sheet | `CalendarBloc` (shared)          |

---

## 1. OnboardingScreen

**File:** `lib/features/onboarding/onboarding_screen.dart`
**Bloc:** `OnboardingBloc`
**Shown when:** `UserPrefs.onboardingComplete == false` on app launch.
**Never shown again** once completed. Edit path is in SettingsScreen.

### Steps (PageView, 3 pages)

```
Page 1: "When did your last period start?"
  Widget: DatePicker (no future dates allowed)
  Default: today − 28 days

Page 2: "How long are your cycles usually?"
  Widget: NumberStepper, range 20–45, default 28
  Subtitle: "Most cycles are between 21 and 35 days"

Page 3: "How long does your period usually last?"
  Widget: NumberStepper, range 1–10, default 5
  Button: "Get Started"
```

### Bloc States

| State                  | UI                                              |
|------------------------|-------------------------------------------------|
| `OnboardingInitial`    | Show page 1 with default values                 |
| `OnboardingSaving`     | Show loading spinner on "Get Started" button    |
| `OnboardingComplete`   | Navigate to MainShell, replace route stack      |
| `OnboardingError`      | Show inline error message, re-enable button     |

### Bloc Events
- `OnboardingPageChanged(int page)`
- `OnboardingDateSelected(DateTime date)`
- `OnboardingCycleLengthChanged(int days)`
- `OnboardingPeriodLengthChanged(int days)`
- `OnboardingSubmitted`

### Rules
- "Get Started" is disabled until page 3.
- Back navigation goes to previous page, not out of onboarding.
- On `OnboardingSubmitted`: save `UserPrefs` + one seed `CycleEntry` (startDate only),
  then set `onboardingComplete = true`, then emit `OnboardingComplete`.

---

## 2. MainShell

**File:** `lib/features/shell/main_shell.dart`
**Bloc:** none — this is a layout widget only.

### Widgets
- `BottomNavigationBar` with 4 items: Home, Calendar, History, Insights
- `IndexedStack` to preserve tab state across switches
- Settings `IconButton` in the `AppBar` (top-right), navigates to SettingsScreen

### Rules
- Tab state is preserved (use `IndexedStack`, not `PageView`).
- The AppBar title changes to match the active tab name.
- Settings icon is always visible regardless of active tab.

---

## 3. HomeScreen

**File:** `lib/features/home/home_screen.dart`
**Bloc:** `HomeBloc`

### Purpose
The primary landing screen. Shows current cycle status and next prediction at a glance.

### Widgets (top to bottom)

```
┌─────────────────────────────────────┐
│  CycleStatusCard                    │  ← "Day 14 of your cycle"
│  NextPeriodCard                     │  ← "Period expected in 8 days · Jan 28"
│  FertileWindowCard                  │  ← "Fertile window: Jan 14 – Jan 19"
│  OvulationCard                      │  ← "Ovulation: Jan 19"
│  [if period is ongoing]             │
│  OngoingPeriodBanner                │  ← "Period in progress · Day 3 · Tap to end"
└─────────────────────────────────────┘
FAB (bottom-right): "Log Period" (hidden if period is ongoing)
```

### Bloc States

| State                    | UI                                                           |
|--------------------------|--------------------------------------------------------------|
| `HomeLoading`            | Shimmer placeholders for all cards                           |
| `HomeLoaded(data)`       | Render all cards with prediction data                        |
| `HomePeriodOngoing`      | Show `OngoingPeriodBanner`, hide FAB                         |
| `HomeNoHistory`          | Show a friendly empty state: "Log your first period to start"|
| `HomeError`              | Show error card with retry button                            |

### Bloc Events
- `HomeStarted` — load on screen init
- `HomeRefreshRequested` — pull to refresh
- `HomeEndPeriodTapped` — user tapped "Tap to end" on the ongoing banner

### Rules
- `HomeEndPeriodTapped` opens `LogPeriodSheet` pre-filled with the open entry
  (so the user can set the end date and optionally add a rating).
- Predictions are always recalculated fresh from the DB on `HomeStarted`.
- If `cyclesUsedForPrediction == 0`, show a subtle label: "Based on your default cycle length".

---

## 4. CalendarScreen

**File:** `lib/features/calendar/calendar_screen.dart`
**Bloc:** `CalendarBloc`

### Purpose
Color-coded monthly calendar. The user's primary visual overview of their cycle.

### Widgets
- `CalendarWidget` — custom monthly grid (do not use table_calendar unless explicitly approved)
- Month navigation arrows (previous / next)
- Color legend row at the bottom

### Day Color Coding

| Day Type            | Visual Treatment                         |
|---------------------|------------------------------------------|
| Period (logged)     | Solid primary-red fill, white text       |
| Period (predicted)  | Light red fill or dashed red border      |
| Fertile window      | Soft green tint                          |
| Ovulation day       | Solid green dot marker                   |
| Today               | Circle outline (no fill unless also red) |
| Default             | No treatment                             |

A day can have multiple types (e.g. today + fertile). Layer them: fertile tint behind,
today outline on top.

### Bloc States

| State                    | UI                                              |
|--------------------------|-------------------------------------------------|
| `CalendarLoading`        | Show empty grid skeleton                        |
| `CalendarLoaded(data)`   | Render marked calendar for current month        |
| `CalendarError`          | Inline error with retry                         |

### Bloc Events
- `CalendarStarted`
- `CalendarMonthChanged(DateTime month)`
- `CalendarDayTapped(DateTime day)`

### Rules
- On `CalendarDayTapped`: emit state that opens `DayDetailSheet`.
- Do not render months more than 3 months in the future.
- Allow scrolling back through all past months with logged history.
- FAB ("Log Period") is shown if no period is currently ongoing.

---

## 5. HistoryScreen

**File:** `lib/features/history/history_screen.dart`
**Bloc:** `HistoryBloc`

### Purpose
Scrollable read-only log of all past cycle entries, newest first.

### Widgets
- `ListView.builder` of `CycleHistoryTile` widgets
- Each tile shows: start date, end date (or "Ongoing"), duration, comfort icon (if rated)
- Tap: opens `CycleDetailSheet`
- Long-press or swipe: reveals Edit and Delete actions

### Bloc States

| State                    | UI                                                        |
|--------------------------|-----------------------------------------------------------|
| `HistoryLoading`         | Shimmer list of 5 placeholder tiles                       |
| `HistoryLoaded(entries)` | Full list, newest first                                   |
| `HistoryEmpty`           | Empty state: "No periods logged yet. Tap + to start."     |
| `HistoryError`           | Error card with retry                                     |
| `HistoryDeleting`        | Show loading indicator on the affected tile               |

### Bloc Events
- `HistoryStarted`
- `HistoryDeleteRequested(int cycleEntryId)`
- `HistoryDeleteConfirmed(int cycleEntryId)`
- `HistoryEditRequested(CycleEntry entry)` — opens LogPeriodSheet pre-filled

### Rules
- Delete requires a confirmation dialog before `HistoryDeleteConfirmed` is dispatched.
- Deleting an entry also deletes its `CycleRating` (handled by DB cascade).
- After delete or edit, reload the list automatically.
- Editing opens `LogPeriodSheet` with the existing entry pre-filled.

---

## 6. InsightsScreen

**File:** `lib/features/insights/insights_screen.dart`
**Bloc:** `InsightsBloc`

### Purpose
Computed stats panel. No charts — cards only. The user reads and interprets themselves.

### Widgets (card list, top to bottom)

```
┌─────────────────────────────────────┐
│  RegularityCard                     │  ← Badge: "Regular ✓" / "Slightly Irregular" / "Irregular"
│                                     │     + one-line explanation
│  AverageCycleLengthCard             │  ← "28.5 days average"
│  AveragePeriodDurationCard          │  ← "5 days average"
│  ShortestLongestCycleCard           │  ← "Shortest: 26 days · Longest: 31 days"
│  TotalCyclesCard                    │  ← "12 cycles logged"
└─────────────────────────────────────┘
```

### Bloc States

| State                      | UI                                                      |
|----------------------------|---------------------------------------------------------|
| `InsightsLoading`          | Shimmer cards                                           |
| `InsightsLoaded(stats)`    | Render all cards with data                              |
| `InsightsInsufficient`     | Show cards with "—" for values, note: "Log more cycles" |
| `InsightsError`            | Error card with retry                                   |

### Bloc Events
- `InsightsStarted`
- `InsightsRefreshRequested`

### Rules
- `RegularityCard` must never use the word "abnormal". See `gemini.md §10` for allowed language.
- If `cyclesUsedForPrediction == 0`, all stat cards show "—" with a soft explanation.
- Stats are computed fresh on every `InsightsStarted` — do not cache across sessions.

---

## 7. SettingsScreen

**File:** `lib/features/settings/settings_screen.dart`
**Bloc:** `SettingsBloc`
**Route:** `/settings` (pushed from MainShell AppBar)

### Widgets (settings list)

```
Section: Cycle
  ├── CycleLengthTile     — stepper/slider, 20–45 days
  └── PeriodLengthTile    — stepper, 1–10 days

Section: Notifications
  ├── NotificationToggle  — master on/off switch
  └── LeadTimeTile        — "Notify X days before" (visible only when toggle is ON)
                            stepper, 1–5 days

Section: Data
  └── EditOnboardingTile  — "Update my cycle defaults" → opens OnboardingScreen
                            in edit mode (same UI, different title, no page skip)
```

### Bloc States

| State                    | UI                                                         |
|--------------------------|------------------------------------------------------------|
| `SettingsLoading`        | Show skeleton tiles                                        |
| `SettingsLoaded(prefs)`  | Render all controls with current values                    |
| `SettingsSaving`         | Show brief loading indicator; controls remain interactive  |
| `SettingsSaved`          | Show a transient SnackBar: "Settings saved"                |
| `SettingsError`          | Show error SnackBar, revert optimistic UI if needed        |

### Bloc Events
- `SettingsStarted`
- `SettingsCycleLengthChanged(int days)`
- `SettingsPeriodLengthChanged(int days)`
- `SettingsNotificationsToggled(bool enabled)`
- `SettingsLeadTimeChanged(int days)`

### Rules
- Changes are saved immediately on each event (no explicit "Save" button needed).
- After any change that affects predictions, dispatch `NotificationRescheduleRequested`
  to `NotificationScheduler`.
- If the user disables notifications, cancel all pending notifications immediately.
- `LeadTimeTile` is hidden (not just disabled) when notifications are off.

---

## 8. LogPeriodSheet (Modal Bottom Sheet)

**File:** `lib/features/log_period/log_period_sheet.dart`
**Bloc:** `LogPeriodBloc`
**Opened from:** HomeScreen FAB, CalendarScreen FAB, HistoryScreen edit action,
                 HomeScreen ongoing banner tap.

### Modes
- **New entry:** all fields blank, no pre-fill.
- **Edit entry:** `CycleEntry` passed in; fields pre-filled; "Save changes" not "Log Period".
- **Close ongoing:** `CycleEntry` passed in with no end_date; start_date locked; focus on end_date.

### Widgets

```
Handle bar (drag to dismiss)
Title: "Log Period" / "Edit Period" / "End Period"

DateField: Start Date    (date picker, no future dates)
DateField: End Date      (optional, date picker, must be ≥ start date)
           Hint: "Leave empty if still ongoing"

[Add Rating] button      → pushes RatingSheet on top (does not close this sheet)
[Note field]             → multiline text input, max 500 chars, char counter shown

[Primary Button]         → "Log Period" / "Save Changes"
[Secondary Button]       → "Cancel" (dismisses sheet, no save)
```

### Bloc States

| State                    | UI                                                           |
|--------------------------|--------------------------------------------------------------|
| `LogPeriodInitial`       | Empty form or pre-filled form                                |
| `LogPeriodValidationError`| Inline error under the invalid field                        |
| `LogPeriodSaving`        | Primary button shows loading spinner, inputs disabled        |
| `LogPeriodSaved`         | Close sheet, emit event to parent to refresh                 |
| `LogPeriodError`         | SnackBar error, re-enable inputs                             |

### Bloc Events
- `LogPeriodStartDateChanged(DateTime date)`
- `LogPeriodEndDateChanged(DateTime? date)`
- `LogPeriodNoteChanged(String note)`
- `LogPeriodRatingAttached(CycleRating rating)` — fired when RatingSheet returns
- `LogPeriodSubmitted`

### Rules
- Validate before submit: start_date required; end_date ≥ start_date if set.
- If a period is already open and mode is "New", show an alert:
  "You have an ongoing period. Do you want to close it first?"
- Rating is optional — submit is allowed without it.
- On `LogPeriodSaved`, the parent screen must call its own refresh event.

---

## 9. RatingSheet (Modal Bottom Sheet)

**File:** `lib/features/log_period/rating_sheet.dart`
**Bloc:** `LogPeriodBloc` (shared state with LogPeriodSheet)
**Opened from:** LogPeriodSheet "Add Rating" button.

### Widgets

```
Handle bar
Title: "How was this period?"

ComfortSlider     — 1 to 5, labeled "Fine" to "Very uncomfortable"
FlowSelector      — 3 chips: Light / Medium / Heavy
SymptomChips      — toggle chips: Cramps, Headache, Mood Swings, Bloating
                    (multi-select, all optional)

[Done] button     → returns CycleRating to LogPeriodSheet, closes this sheet only
[Skip] button     → closes without attaching a rating
```

### Rules
- All fields optional. "Done" can be tapped with nothing selected.
- Does not save to DB — passes `CycleRating` back to `LogPeriodBloc` via
  `LogPeriodRatingAttached`. The DB write happens only on `LogPeriodSubmitted`.
- Closing this sheet (back or Skip) returns to LogPeriodSheet, which remains open.

---

## 10. CycleDetailSheet (Modal Bottom Sheet)

**File:** `lib/features/history/cycle_detail_sheet.dart`
**Bloc:** `HistoryBloc` (shared)
**Opened from:** HistoryScreen row tap.

### Widgets

```
Handle bar
Title: "Jan 12 – Jan 17, 2025"  (start – end dates)

Duration row:     "6 days"
Flow row:         "Medium" (if rated)
Comfort row:      "3 / 5" with label "Moderate" (if rated)
Symptoms row:     Chip list of logged symptoms (if any)
Notes section:    Full note text (if any). Greyed out if empty: "No notes added."

[Edit] button     → opens LogPeriodSheet pre-filled
[Delete] button   → confirm dialog, then delete
```

### Rules
- This sheet is read-only except for the Edit and Delete buttons.
- If no `CycleRating` exists for the entry, hide all rating rows entirely (do not show dashes).
- Delete triggers `HistoryDeleteRequested` on the `HistoryBloc`.

---

## 11. DayDetailSheet (Modal Bottom Sheet)

**File:** `lib/features/calendar/day_detail_sheet.dart`
**Bloc:** `CalendarBloc` (shared)
**Opened from:** CalendarScreen day tap.

### Widgets

```
Handle bar
Title: "Tuesday, Jan 14"

[One or more info rows describing what this day is:]
  "Period day (logged)"         — if inside a logged period
  "Predicted period day"        — if inside a predicted period
  "Fertile window"              — if inside fertile window
  "Ovulation day"               — if this is the predicted ovulation day
  "No data for this day"        — if none of the above

[If it's a logged period day:]
  [View Details] button → opens CycleDetailSheet for that entry

[If no period is ongoing and day is today or past:]
  [Log Period Starting Today] button → opens LogPeriodSheet with date pre-filled
```

### Rules
- A day can match multiple categories (e.g., fertile + predicted period). Show all that apply.
- Do not show the "Log Period" button for future days.
- Do not show the "Log Period" button if a period is currently ongoing.

---

## Cross-Screen Rules

1. **Refresh propagation:** After any write (log, edit, delete), all screens that display
   predictions or history must reload. Use a shared stream or BlocListener at the shell level.
   Do not manually call refresh on each screen — drive it from a single event.

2. **No business logic in widgets.** Every conditional, calculation, or decision lives in
   a Bloc or domain class. Widgets only call `context.read<Bloc>().add(Event())` and
   render states.

3. **Bottom sheets do not have routes.** Never push a bottom sheet via `Navigator.pushNamed`.
   Always use `showModalBottomSheet`.

4. **Loading states must never be empty.** Every loading state shows a shimmer or skeleton
   — never a blank screen.

5. **Error states must always offer recovery.** Every error state has a retry button or
   a clear instruction. Never show a raw exception message to the user.

6. **Date display format (UI layer only):** `d MMM yyyy` → "14 Jan 2025".
   All internal computation uses UTC `DateTime`. Format only in widget build methods.

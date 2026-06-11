import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker_app/core/constants/cycle_constants.dart';
import 'package:period_tracker_app/data/models/cycle_entry.dart';
import 'package:period_tracker_app/data/models/user_prefs.dart';
import 'package:period_tracker_app/domain/cycle_calculator.dart';
import 'package:period_tracker_app/domain/irregularity_detector.dart';

void main() {
  group('CycleCalculator Tests', () {
    final today = DateTime.utc(2025, 4, 10);
    final defaultPrefs = UserPrefs(
      id: 1,
      preferredCycleLength: kDefaultCycleLength,
      preferredPeriodLength: kDefaultPeriodDuration,
      notificationLeadDays: 2,
      notificationsEnabled: true,
      onboardingComplete: true,
    );

    CycleEntry makeEntry(String start, {String? end, String? created}) {
      return CycleEntry(
        id: null,
        startDate: start,
        endDate: end,
        createdAt: created ?? DateTime.utc(2025, 1, 1).toIso8601String(),
        updatedAt: DateTime.utc(2025, 1, 1).toIso8601String(),
      );
    }

    test('0 cycles -> uses preferredCycleLength', () {
      final result = CycleCalculator.predict([], defaultPrefs, today);
      expect(result.cyclesUsedForPrediction, 0);
      expect(result.averageCycleLength, 28.0);
      expect(result.nextPeriodStart, today.add(const Duration(days: 28)));
    });

    test('1 cycle -> uses preferredCycleLength, fallback prediction', () {
      final cycles = [
        makeEntry('2025-03-01T00:00:00Z', end: '2025-03-05T00:00:00Z'),
      ];
      final result = CycleCalculator.predict(cycles, defaultPrefs, today);
      expect(result.cyclesUsedForPrediction, 1);
      expect(result.averageCycleLength, 28.0);
      // Last start + 28 days = March 1 + 28 = March 29
      expect(result.nextPeriodStart, DateTime.utc(2025, 3, 29));
    });

    test('2 cycles -> computes 1 gap, uses it', () {
      final cycles = [
        makeEntry('2025-02-01T00:00:00Z', end: '2025-02-05T00:00:00Z'),
        makeEntry('2025-03-01T00:00:00Z', end: '2025-03-05T00:00:00Z'),
      ];
      // gap between Feb 1 (leap year? 2025 is not leap -> 28 days in feb)
      // Feb 1 to Mar 1 = 28 days.
      final result = CycleCalculator.predict(cycles, defaultPrefs, today);
      expect(result.cyclesUsedForPrediction, 2);
      expect(result.averageCycleLength, 28.0);
      expect(result.nextPeriodStart, DateTime.utc(2025, 3, 29));
    });

    test('3 cycles -> correct rolling average of 2 gaps', () {
      final cycles = [
        makeEntry('2025-01-01T00:00:00Z'),
        makeEntry('2025-01-29T00:00:00Z'), // gap 28
        makeEntry('2025-02-25T00:00:00Z'), // gap 27
      ];
      final result = CycleCalculator.predict(cycles, defaultPrefs, today);
      expect(result.averageCycleLength, 27.5);
      // rounded 27.5 is 28. Feb 25 + 28 = Mar 25
      expect(result.nextPeriodStart, DateTime.utc(2025, 3, 25));
    });

    test('Implausible gap is skipped (CYCLE_MATH.md precedence)', () {
      final cycles = [
        makeEntry('2025-01-01T00:00:00Z'),
        makeEntry('2025-01-08T00:00:00Z'), // gap 7 -> IMPLAUSIBLE
        makeEntry('2025-02-05T00:00:00Z'), // gap 28
      ];
      final result = CycleCalculator.predict(cycles, defaultPrefs, today);
      expect(result.averageCycleLength, 28.0); // The 7-day gap is skipped
      expect(result.cyclesUsedForPrediction, 3); // 3 valid records, but gaps calculated internally
    });

    test('Period duration caps correctly when endDate is missing', () {
      final ongoingEntry = makeEntry('2025-04-01T00:00:00Z', end: null);
      final duration = CycleCalculator.periodDuration(ongoingEntry, today);
      // April 1 to April 10 is 9 days -> capped to 7
      expect(duration, 7);
      
      final recentOngoing = makeEntry('2025-04-08T00:00:00Z', end: null);
      final duration2 = CycleCalculator.periodDuration(recentOngoing, today);
      // April 8 to April 10 is 2 days + 1 = 3
      expect(duration2, 3);
    });
  });

  group('IrregularityDetector Tests', () {
    test('regular', () {
      final result = IrregularityDetector.detect([28, 27, 29, 28, 28, 28], 28.0);
      expect(result, CycleRegularity.regular);
    });

    test('slightlyIrregular (one deviation > 7)', () {
      final result = IrregularityDetector.detect([28, 27, 29, 28, 28, 19], 28.0);
      expect(result, CycleRegularity.slightlyIrregular);
    });

    test('irregular (two deviations > 7)', () {
      final result = IrregularityDetector.detect([28, 27, 29, 28, 19, 38], 28.33);
      expect(result, CycleRegularity.irregular);
    });
  });
}

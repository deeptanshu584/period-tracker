import '../core/constants/cycle_constants.dart';
import '../data/models/cycle_entry.dart';
import '../data/models/prediction_result.dart';
import '../data/models/user_prefs.dart';
import 'irregularity_detector.dart';

class CycleCalculator {
  static List<CycleEntry> sanitize(List<CycleEntry> cycles, DateTime today) {
    if (cycles.isEmpty) return [];

    // 1. Sort by startDate ascending (oldest first).
    final sorted = List<CycleEntry>.from(cycles)
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    // 2. Remove any entry where startDate is in the future.
    // 3. (Handled in periodDuration) For each entry with no endDate, effectively cap at 7 days.
    // 4. Remove duplicate startDates — keep only the most recently created.
    final Map<DateTime, CycleEntry> uniqueStarts = {};

    for (var entry in sorted) {
      final start = entry.startDateTime;
      final normalizedStart = DateTime.utc(start.year, start.month, start.day);
      final normalizedToday = DateTime.utc(today.year, today.month, today.day);

      if (normalizedStart.isAfter(normalizedToday)) {
        continue; // Skip future dates
      }

      // Keep the most recently created one if duplicate start dates exist
      if (uniqueStarts.containsKey(normalizedStart)) {
        final existing = uniqueStarts[normalizedStart]!;
        final existingCreated = DateTime.parse(existing.createdAt);
        final newCreated = DateTime.parse(entry.createdAt);
        if (newCreated.isAfter(existingCreated)) {
          uniqueStarts[normalizedStart] = entry;
        }
      } else {
        uniqueStarts[normalizedStart] = entry;
      }
    }

    final sanitizedList = uniqueStarts.values.toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return sanitizedList;
  }

  static List<int> computeGaps(List<CycleEntry> sanitizedCycles) {
    List<int> gaps = [];
    for (int i = 1; i < sanitizedCycles.length; i++) {
      final prevStart = sanitizedCycles[i - 1].startDateTime;
      final currentStart = sanitizedCycles[i].startDateTime;
      
      final prevNorm = DateTime.utc(prevStart.year, prevStart.month, prevStart.day);
      final currNorm = DateTime.utc(currentStart.year, currentStart.month, currentStart.day);
      
      final gap = currNorm.difference(prevNorm).inDays;
      if (gap >= kMinPlausibleCycleLength && gap <= kMaxPlausibleCycleLength) {
        gaps.add(gap);
      }
    }
    return gaps;
  }

  static double rollingAverage(List<int> gaps, {int window = kRollingAverageWindow, required int fallback}) {
    if (gaps.isEmpty) {
      return fallback.toDouble();
    }
    final useGaps = gaps.length > window ? gaps.sublist(gaps.length - window) : gaps;
    final sum = useGaps.fold<int>(0, (prev, element) => prev + element);
    return sum / useGaps.length;
  }

  static DateTime predictNextPeriodStart(List<CycleEntry> sanitizedCycles, double averageCycleLength, DateTime today) {
    final avgDays = averageCycleLength.round();
    
    if (sanitizedCycles.isEmpty) {
      return today.add(Duration(days: avgDays));
    }

    final lastStart = sanitizedCycles.last.startDateTime;
    final normalizedLastStart = DateTime.utc(lastStart.year, lastStart.month, lastStart.day);
    return normalizedLastStart.add(Duration(days: avgDays));
  }

  static DateTime ovulationDay(DateTime nextPeriodStart) {
    return nextPeriodStart.subtract(const Duration(days: 14));
  }

  static DateTime fertileWindowStart(DateTime ovulationDay) {
    return ovulationDay.subtract(const Duration(days: 5));
  }

  static DateTime fertileWindowEnd(DateTime ovulationDay) {
    return ovulationDay;
  }

  static int? currentCycleDay(List<CycleEntry> sanitizedCycles, DateTime today) {
    if (sanitizedCycles.isEmpty) return null;

    final lastStart = sanitizedCycles.last.startDateTime;
    final normalizedLastStart = DateTime.utc(lastStart.year, lastStart.month, lastStart.day);
    final normalizedToday = DateTime.utc(today.year, today.month, today.day);
    
    return normalizedToday.difference(normalizedLastStart).inDays + 1;
  }

  static int periodDuration(CycleEntry entry, DateTime today) {
    final start = entry.startDateTime;
    final normalizedStart = DateTime.utc(start.year, start.month, start.day);
    
    if (entry.endDate != null) {
      final end = entry.endDateTime!;
      final normalizedEnd = DateTime.utc(end.year, end.month, end.day);
      return normalizedEnd.difference(normalizedStart).inDays + 1;
    } else {
      final normalizedToday = DateTime.utc(today.year, today.month, today.day);
      final elapsed = normalizedToday.difference(normalizedStart).inDays;
      return (elapsed + 1).clamp(1, kMaxPeriodDurationFallback);
    }
  }

  static double averagePeriodDuration(List<CycleEntry> sanitizedCycles, DateTime today, {required int fallback}) {
    final durations = sanitizedCycles
        .where((c) => c.endDate != null)
        .map((c) => periodDuration(c, today))
        .toList();
        
    if (durations.isEmpty) {
      return fallback.toDouble();
    }
    
    final sum = durations.fold<int>(0, (prev, element) => prev + element);
    return sum / durations.length;
  }

  static PredictionResult predict(List<CycleEntry> rawCycles, UserPrefs prefs, DateTime today) {
    final sanitized = sanitize(rawCycles, today);
    final gaps = computeGaps(sanitized);
    final avgCycleLen = rollingAverage(gaps, fallback: prefs.preferredCycleLength);
    final nextPeriod = predictNextPeriodStart(sanitized, avgCycleLen, today);
    final ovDay = ovulationDay(nextPeriod);
    
    int cyclesUsed = 0;
    if (sanitized.isNotEmpty && gaps.isEmpty) {
      cyclesUsed = 1; 
    } else if (sanitized.isNotEmpty && gaps.isNotEmpty) {
      cyclesUsed = sanitized.length;
    }

    final regularity = IrregularityDetector.detect(gaps, avgCycleLen);

    return PredictionResult(
      nextPeriodStart: nextPeriod,
      ovulationDay: ovDay,
      fertileWindowStart: fertileWindowStart(ovDay),
      fertileWindowEnd: fertileWindowEnd(ovDay),
      averageCycleLength: avgCycleLen,
      cyclesUsedForPrediction: cyclesUsed,
      regularity: regularity,
    );
  }
}

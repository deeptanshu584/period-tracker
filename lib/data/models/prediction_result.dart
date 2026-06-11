import '../../domain/irregularity_detector.dart';

class PredictionResult {
  final DateTime nextPeriodStart;
  final DateTime ovulationDay;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final double averageCycleLength;
  final int cyclesUsedForPrediction; // 0 = used userPrefs fallback
  final CycleRegularity regularity;

  const PredictionResult({
    required this.nextPeriodStart,
    required this.ovulationDay,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.averageCycleLength,
    required this.cyclesUsedForPrediction,
    required this.regularity,
  });
}

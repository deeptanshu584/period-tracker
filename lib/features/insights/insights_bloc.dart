import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../domain/cycle_calculator.dart';
import '../../domain/irregularity_detector.dart';

abstract class InsightsEvent extends Equatable {
  const InsightsEvent();
  @override
  List<Object?> get props => [];
}

class InsightsStarted extends InsightsEvent {}
class InsightsRefreshRequested extends InsightsEvent {}

abstract class InsightsState extends Equatable {
  const InsightsState();
  @override
  List<Object?> get props => [];
}

class InsightsLoading extends InsightsState {}

class InsightsLoaded extends InsightsState {
  final double averageCycleLength;
  final double averagePeriodDuration;
  final int shortestCycle;
  final int longestCycle;
  final int totalCycles;
  final CycleRegularity regularity;
  final String regularityExplanation;

  const InsightsLoaded({
    required this.averageCycleLength,
    required this.averagePeriodDuration,
    required this.shortestCycle,
    required this.longestCycle,
    required this.totalCycles,
    required this.regularity,
    required this.regularityExplanation,
  });

  @override
  List<Object?> get props => [
        averageCycleLength,
        averagePeriodDuration,
        shortestCycle,
        longestCycle,
        totalCycles,
        regularity,
        regularityExplanation,
      ];
}

class InsightsInsufficient extends InsightsState {
  final int totalCycles;
  const InsightsInsufficient(this.totalCycles);
  @override
  List<Object?> get props => [totalCycles];
}

class InsightsError extends InsightsState {
  final String message;
  const InsightsError(this.message);
  @override
  List<Object?> get props => [message];
}

class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  final CycleRepository repository;

  InsightsBloc({required this.repository}) : super(InsightsLoading()) {
    on<InsightsStarted>(_onStarted);
    on<InsightsRefreshRequested>(_onRefresh);
  }

  Future<void> _onStarted(InsightsStarted event, Emitter<InsightsState> emit) async {
    await _loadData(emit);
  }

  Future<void> _onRefresh(InsightsRefreshRequested event, Emitter<InsightsState> emit) async {
    emit(InsightsLoading());
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<InsightsState> emit) async {
    try {
      final cycles = await repository.getCycles();
      final prefs = await repository.getUserPrefs();
      final today = DateTime.now().toUtc();

      if (cycles.length < 2) {
        emit(InsightsInsufficient(cycles.length));
        return;
      }

      final sanitized = CycleCalculator.sanitize(cycles, today);
      final gaps = CycleCalculator.computeGaps(sanitized);

      if (gaps.isEmpty) {
        emit(InsightsInsufficient(cycles.length));
        return;
      }

      final avgCycle = CycleCalculator.rollingAverage(gaps, fallback: prefs.preferredCycleLength);
      final avgPeriod = CycleCalculator.averagePeriodDuration(sanitized, today, fallback: prefs.preferredPeriodLength);
      
      final shortest = gaps.reduce((a, b) => a < b ? a : b);
      final longest = gaps.reduce((a, b) => a > b ? a : b);
      
      final regularity = IrregularityDetector.detect(gaps, avgCycle);
      final explanation = IrregularityDetector.buildExplanation(gaps, avgCycle);

      emit(InsightsLoaded(
        averageCycleLength: avgCycle,
        averagePeriodDuration: avgPeriod,
        shortestCycle: shortest,
        longestCycle: longest,
        totalCycles: cycles.length,
        regularity: regularity,
        regularityExplanation: explanation,
      ));
    } catch (e) {
      emit(const InsightsError("Failed to load insights."));
    }
  }
}

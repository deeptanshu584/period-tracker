import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../data/models/prediction_result.dart';
import '../../domain/cycle_calculator.dart';
import '../../data/models/cycle_entry.dart';
import '../../notifications/notification_scheduler.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {}
class HomeRefreshRequested extends HomeEvent {}

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final PredictionResult prediction;
  final CycleEntry? ongoingPeriod;
  final bool hasHistory;

  const HomeLoaded({
    required this.prediction,
    this.ongoingPeriod,
    required this.hasHistory,
  });

  @override
  List<Object?> get props => [prediction, ongoingPeriod, hasHistory];
}

class HomeNoHistory extends HomeState {}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final CycleRepository repository;

  HomeBloc({required this.repository}) : super(HomeLoading()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshRequested>(_onRefresh);
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    await _loadData(emit);
  }

  Future<void> _onRefresh(HomeRefreshRequested event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    await _loadData(emit);
  }

  Future<void> _loadData(Emitter<HomeState> emit) async {
    try {
      final cycles = await repository.getCycles();
      final prefs = await repository.getUserPrefs();
      final today = DateTime.now().toUtc();

      if (cycles.isEmpty) {
        emit(HomeNoHistory());
        return;
      }

      final prediction = CycleCalculator.predict(cycles, prefs, today);
      
      CycleEntry? ongoing;
      final sorted = List<CycleEntry>.from(cycles)..sort((a,b) => a.startDateTime.compareTo(b.startDateTime));
      if (sorted.isNotEmpty && sorted.last.isOngoing) {
        ongoing = sorted.last;
      }

      emit(HomeLoaded(
        prediction: prediction,
        ongoingPeriod: ongoing,
        hasHistory: true,
      ));

      // Reschedule notifications based on the new prediction
      await NotificationScheduler.reschedule(prediction, prefs);
    } catch (e) {
      // Typically we'd emit HomeError here
    }
  }
}

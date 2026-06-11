import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../data/models/cycle_entry.dart';
import '../../data/models/prediction_result.dart';
import '../../domain/cycle_calculator.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();
  @override
  List<Object?> get props => [];
}

class CalendarStarted extends CalendarEvent {}

class CalendarMonthChanged extends CalendarEvent {
  final DateTime month;
  const CalendarMonthChanged(this.month);
  @override
  List<Object?> get props => [month];
}

abstract class CalendarState extends Equatable {
  const CalendarState();
  @override
  List<Object?> get props => [];
}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<CycleEntry> entries;
  final PredictionResult? prediction;
  final DateTime currentMonth;

  const CalendarLoaded({
    required this.entries,
    this.prediction,
    required this.currentMonth,
  });

  @override
  List<Object?> get props => [entries, prediction, currentMonth];
}

class CalendarError extends CalendarState {
  final String message;
  const CalendarError(this.message);
  @override
  List<Object?> get props => [message];
}

class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  final CycleRepository repository;

  CalendarBloc({required this.repository}) : super(CalendarLoading()) {
    on<CalendarStarted>(_onStarted);
    on<CalendarMonthChanged>(_onMonthChanged);
  }

  Future<void> _onStarted(CalendarStarted event, Emitter<CalendarState> emit) async {
    emit(CalendarLoading());
    try {
      final cycles = await repository.getCycles();
      final prefs = await repository.getUserPrefs();
      PredictionResult? pred;
      if (cycles.isNotEmpty) {
        pred = CycleCalculator.predict(cycles, prefs, DateTime.now().toUtc());
      }
      
      emit(CalendarLoaded(
        entries: cycles,
        prediction: pred,
        currentMonth: DateTime.now(),
      ));
    } catch (e) {
      emit(const CalendarError("Failed to load calendar data."));
    }
  }

  Future<void> _onMonthChanged(CalendarMonthChanged event, Emitter<CalendarState> emit) async {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      emit(CalendarLoaded(
        entries: currentState.entries,
        prediction: currentState.prediction,
        currentMonth: event.month,
      ));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../data/models/cycle_entry.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class HistoryStarted extends HistoryEvent {}

class HistoryDeleteRequested extends HistoryEvent {
  final int cycleEntryId;
  const HistoryDeleteRequested(this.cycleEntryId);
  @override
  List<Object?> get props => [cycleEntryId];
}

class HistoryDeleteConfirmed extends HistoryEvent {
  final CycleEntry entry;
  const HistoryDeleteConfirmed(this.entry);
  @override
  List<Object?> get props => [entry];
}

abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<CycleEntry> entries;
  const HistoryLoaded(this.entries);
  @override
  List<Object?> get props => [entries];
}

class HistoryEmpty extends HistoryState {}

class HistoryDeleting extends HistoryState {
  final int entryId;
  const HistoryDeleting(this.entryId);
  @override
  List<Object?> get props => [entryId];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final CycleRepository repository;

  HistoryBloc({required this.repository}) : super(HistoryLoading()) {
    on<HistoryStarted>(_onStarted);
    on<HistoryDeleteConfirmed>(_onDeleteConfirmed);
  }

  Future<void> _onStarted(HistoryStarted event, Emitter<HistoryState> emit) async {
    emit(HistoryLoading());
    try {
      final cycles = await repository.getCycles();
      if (cycles.isEmpty) {
        emit(HistoryEmpty());
      } else {
        // Floor already returns them ordered by startDate DESC according to the DAO
        emit(HistoryLoaded(cycles));
      }
    } catch (e) {
      emit(const HistoryError("Failed to load history."));
    }
  }

  Future<void> _onDeleteConfirmed(HistoryDeleteConfirmed event, Emitter<HistoryState> emit) async {
    if (event.entry.id != null) {
      emit(HistoryDeleting(event.entry.id!));
      try {
        await repository.db.cycleEntryDao.deleteEntry(event.entry);
        add(HistoryStarted());
      } catch (e) {
        emit(const HistoryError("Failed to delete entry."));
      }
    }
  }
}

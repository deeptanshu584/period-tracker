import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../data/models/user_prefs.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsStarted extends SettingsEvent {}

class SettingsCycleLengthChanged extends SettingsEvent {
  final int days;
  const SettingsCycleLengthChanged(this.days);
  @override
  List<Object?> get props => [days];
}

class SettingsPeriodLengthChanged extends SettingsEvent {
  final int days;
  const SettingsPeriodLengthChanged(this.days);
  @override
  List<Object?> get props => [days];
}

class SettingsNotificationsToggled extends SettingsEvent {
  final bool enabled;
  const SettingsNotificationsToggled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsLeadTimeChanged extends SettingsEvent {
  final int days;
  const SettingsLeadTimeChanged(this.days);
  @override
  List<Object?> get props => [days];
}

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final UserPrefs prefs;
  const SettingsLoaded(this.prefs);
  @override
  List<Object?> get props => [prefs];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final CycleRepository repository;

  SettingsBloc({required this.repository}) : super(SettingsLoading()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsCycleLengthChanged>(_onCycleLengthChanged);
    on<SettingsPeriodLengthChanged>(_onPeriodLengthChanged);
    on<SettingsNotificationsToggled>(_onNotificationsToggled);
    on<SettingsLeadTimeChanged>(_onLeadTimeChanged);
  }

  Future<void> _onStarted(SettingsStarted event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    try {
      final prefs = await repository.getUserPrefs();
      emit(SettingsLoaded(prefs));
    } catch (e) {
      emit(const SettingsError("Failed to load settings."));
    }
  }

  Future<void> _updatePrefs(UserPrefs newPrefs, Emitter<SettingsState> emit) async {
    try {
      await repository.saveUserPrefs(newPrefs);
      emit(SettingsLoaded(newPrefs));
      // Typically we would trigger NotificationRescheduleRequested here to the NotificationScheduler
    } catch (e) {
      emit(const SettingsError("Failed to save setting."));
    }
  }

  Future<void> _onCycleLengthChanged(SettingsCycleLengthChanged event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final prefs = (state as SettingsLoaded).prefs;
      await _updatePrefs(prefs.copyWith(preferredCycleLength: event.days), emit);
    }
  }

  Future<void> _onPeriodLengthChanged(SettingsPeriodLengthChanged event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final prefs = (state as SettingsLoaded).prefs;
      await _updatePrefs(prefs.copyWith(preferredPeriodLength: event.days), emit);
    }
  }

  Future<void> _onNotificationsToggled(SettingsNotificationsToggled event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final prefs = (state as SettingsLoaded).prefs;
      await _updatePrefs(prefs.copyWith(notificationsEnabled: event.enabled), emit);
    }
  }

  Future<void> _onLeadTimeChanged(SettingsLeadTimeChanged event, Emitter<SettingsState> emit) async {
    if (state is SettingsLoaded) {
      final prefs = (state as SettingsLoaded).prefs;
      await _updatePrefs(prefs.copyWith(notificationLeadDays: event.days), emit);
    }
  }
}

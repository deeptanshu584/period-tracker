import 'package:floor/floor.dart';

@Entity(tableName: 'user_prefs')
class UserPrefs {
  @PrimaryKey()
  final int id; // always single row

  final int preferredCycleLength;
  final int preferredPeriodLength;
  final int notificationLeadDays;
  final bool notificationsEnabled;
  final bool onboardingComplete;

  UserPrefs({
    this.id = 1,
    required this.preferredCycleLength,
    required this.preferredPeriodLength,
    required this.notificationLeadDays,
    required this.notificationsEnabled,
    required this.onboardingComplete,
  });

  UserPrefs copyWith({
    int? id,
    int? preferredCycleLength,
    int? preferredPeriodLength,
    int? notificationLeadDays,
    bool? notificationsEnabled,
    bool? onboardingComplete,
  }) {
    return UserPrefs(
      id: id ?? this.id,
      preferredCycleLength: preferredCycleLength ?? this.preferredCycleLength,
      preferredPeriodLength: preferredPeriodLength ?? this.preferredPeriodLength,
      notificationLeadDays: notificationLeadDays ?? this.notificationLeadDays,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}

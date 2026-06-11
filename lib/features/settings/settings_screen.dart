import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_bloc.dart';
import '../../core/constants/cycle_constants.dart';
import '../home/home_bloc.dart';
import '../calendar/calendar_bloc.dart';
import '../../notifications/notification_scheduler.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is SettingsLoaded) {
            // When settings change, we should refresh the home and calendar blocs 
            // since predictions might change if there's no history.
            context.read<HomeBloc>().add(HomeStarted());
            context.read<CalendarBloc>().add(CalendarStarted());
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SettingsLoaded) {
            final prefs = state.prefs;
            return ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text("CYCLE PREFERENCES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                ListTile(
                  title: const Text("Average Cycle Length"),
                  subtitle: Text("${prefs.preferredCycleLength} days"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: prefs.preferredCycleLength > kMinPlausibleCycleLength 
                            ? () => context.read<SettingsBloc>().add(SettingsCycleLengthChanged(prefs.preferredCycleLength - 1)) 
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: prefs.preferredCycleLength < kMaxPlausibleCycleLength 
                            ? () => context.read<SettingsBloc>().add(SettingsCycleLengthChanged(prefs.preferredCycleLength + 1)) 
                            : null,
                      ),
                    ],
                  ),
                ),
                ListTile(
                  title: const Text("Average Period Duration"),
                  subtitle: Text("${prefs.preferredPeriodLength} days"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: prefs.preferredPeriodLength > 1 
                            ? () => context.read<SettingsBloc>().add(SettingsPeriodLengthChanged(prefs.preferredPeriodLength - 1)) 
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: prefs.preferredPeriodLength < 10 
                            ? () => context.read<SettingsBloc>().add(SettingsPeriodLengthChanged(prefs.preferredPeriodLength + 1)) 
                            : null,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text("NOTIFICATIONS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                SwitchListTile(
                  title: const Text("Enable Reminders"),
                  subtitle: const Text("Get local notifications before your period starts"),
                  value: prefs.notificationsEnabled,
                  onChanged: (val) {
                    if (val) {
                      NotificationScheduler.requestPermissions();
                    }
                    context.read<SettingsBloc>().add(SettingsNotificationsToggled(val));
                  },
                ),
                if (prefs.notificationsEnabled)
                  ListTile(
                    title: const Text("Remind me beforehand"),
                    subtitle: Text("${prefs.notificationLeadDays} days before"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: prefs.notificationLeadDays > 1 
                              ? () => context.read<SettingsBloc>().add(SettingsLeadTimeChanged(prefs.notificationLeadDays - 1)) 
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: prefs.notificationLeadDays < kMaxNotificationLeadDays 
                              ? () => context.read<SettingsBloc>().add(SettingsLeadTimeChanged(prefs.notificationLeadDays + 1)) 
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

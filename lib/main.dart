import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'data/local/app_database.dart';
import 'data/repositories/cycle_repository.dart';
import 'features/shell/main_shell.dart';
import 'features/home/home_bloc.dart';
import 'features/history/history_bloc.dart';
import 'features/calendar/calendar_bloc.dart';
import 'features/insights/insights_bloc.dart';
import 'features/settings/settings_bloc.dart';
import 'notifications/notification_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationScheduler.init();

  // 1. Retrieve or generate secure DB password
  const secureStorage = FlutterSecureStorage();
  String? dbPassword = await secureStorage.read(key: 'db_password');
  if (dbPassword == null) {
    dbPassword = const Uuid().v4();
    await secureStorage.write(key: 'db_password', value: dbPassword);
  }

  // 2. Initialize encrypted Floor database
  final database = await DatabaseConfig.getDatabase(dbPassword);
  
  // 3. Create repository layer
  final cycleRepository = CycleRepository(database);

  runApp(PeriodTrackerApp(repository: cycleRepository));
}

class PeriodTrackerApp extends StatelessWidget {
  final CycleRepository repository;

  const PeriodTrackerApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => HomeBloc(repository: repository)..add(HomeStarted())),
          BlocProvider(create: (_) => HistoryBloc(repository: repository)..add(HistoryStarted())),
          BlocProvider(create: (_) => CalendarBloc(repository: repository)..add(CalendarStarted())),
          BlocProvider(create: (_) => InsightsBloc(repository: repository)..add(InsightsStarted())),
          BlocProvider(create: (_) => SettingsBloc(repository: repository)..add(SettingsStarted())),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Period Tracker',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.light),
            useMaterial3: true,
          ),
          home: const MainShell(),
        ),
      ),
    );
  }
}

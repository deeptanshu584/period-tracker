import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqflite;

import '../models/cycle_entry.dart';
import '../models/cycle_rating.dart';
import '../models/user_prefs.dart';
import 'daos.dart';

part 'app_database.g.dart';

@Database(version: 1, entities: [CycleEntry, CycleRating, UserPrefs])
abstract class AppDatabase extends FloorDatabase {
  CycleEntryDao get cycleEntryDao;
  CycleRatingDao get cycleRatingDao;
  UserPrefsDao get userPrefsDao;
}

class DatabaseConfig {
  static Future<AppDatabase> getDatabase(String password) async {
    final database = await $FloorAppDatabase
        .databaseBuilder('period_tracker_app.db')
        .addCallback(Callback(
          onConfigure: (database) async {
            // Set the SQLCipher password before any other operations
            await database.execute("PRAGMA key = '$password'");
          },
        ))
        .build();
    
    return database;
  }
}

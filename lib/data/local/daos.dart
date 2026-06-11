import 'package:floor/floor.dart';
import '../models/cycle_entry.dart';
import '../models/cycle_rating.dart';
import '../models/user_prefs.dart';

@dao
abstract class CycleEntryDao {
  @Query('SELECT * FROM cycle_entries ORDER BY startDate DESC')
  Future<List<CycleEntry>> findAllEntries();

  @Query('SELECT * FROM cycle_entries WHERE id = :id')
  Future<CycleEntry?> findEntryById(int id);

  @insert
  Future<int> insertEntry(CycleEntry entry);

  @update
  Future<int> updateEntry(CycleEntry entry);

  @delete
  Future<int> deleteEntry(CycleEntry entry);
}

@dao
abstract class CycleRatingDao {
  @Query('SELECT * FROM cycle_ratings WHERE cycleEntryId = :cycleEntryId')
  Future<CycleRating?> findRatingForEntry(int cycleEntryId);

  @insert
  Future<int> insertRating(CycleRating rating);

  @update
  Future<int> updateRating(CycleRating rating);

  @delete
  Future<int> deleteRating(CycleRating rating);
}

@dao
abstract class UserPrefsDao {
  @Query('SELECT * FROM user_prefs WHERE id = 1')
  Future<UserPrefs?> getUserPrefs();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertOrUpdatePrefs(UserPrefs prefs);
}

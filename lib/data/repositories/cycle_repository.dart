import '../local/app_database.dart';
import '../models/cycle_entry.dart';
import '../models/user_prefs.dart';

class CycleRepository {
  final AppDatabase db;
  CycleRepository(this.db);

  Future<List<CycleEntry>> getCycles() => db.cycleEntryDao.findAllEntries();
  
  Future<void> saveCycle(CycleEntry entry) {
    if (entry.id == null) {
      return db.cycleEntryDao.insertEntry(entry);
    } else {
      return db.cycleEntryDao.updateEntry(entry);
    }
  }
  
  Future<UserPrefs> getUserPrefs() async {
    final prefs = await db.userPrefsDao.getUserPrefs();
    if (prefs != null) return prefs;
    
    // Default fallback
    final defaultPrefs = UserPrefs(
      preferredCycleLength: 28,
      preferredPeriodLength: 5,
      notificationLeadDays: 2,
      notificationsEnabled: true,
      onboardingComplete: false,
    );
    await db.userPrefsDao.insertOrUpdatePrefs(defaultPrefs);
    return defaultPrefs;
  }
  
  Future<void> saveUserPrefs(UserPrefs prefs) => db.userPrefsDao.insertOrUpdatePrefs(prefs);
}

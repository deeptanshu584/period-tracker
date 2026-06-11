// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  CycleEntryDao? _cycleEntryDaoInstance;

  CycleRatingDao? _cycleRatingDaoInstance;

  UserPrefsDao? _userPrefsDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `cycle_entries` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `startDate` TEXT NOT NULL, `endDate` TEXT, `notes` TEXT, `createdAt` TEXT NOT NULL, `updatedAt` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `cycle_ratings` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `cycleEntryId` INTEGER NOT NULL, `comfortLevel` INTEGER NOT NULL, `hadCramps` INTEGER NOT NULL, `hadHeadache` INTEGER NOT NULL, `hadMoodSwings` INTEGER NOT NULL, `hadBloating` INTEGER NOT NULL, `flowLevel` TEXT NOT NULL, FOREIGN KEY (`cycleEntryId`) REFERENCES `cycle_entries` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `user_prefs` (`id` INTEGER NOT NULL, `preferredCycleLength` INTEGER NOT NULL, `preferredPeriodLength` INTEGER NOT NULL, `notificationLeadDays` INTEGER NOT NULL, `notificationsEnabled` INTEGER NOT NULL, `onboardingComplete` INTEGER NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  CycleEntryDao get cycleEntryDao {
    return _cycleEntryDaoInstance ??= _$CycleEntryDao(database, changeListener);
  }

  @override
  CycleRatingDao get cycleRatingDao {
    return _cycleRatingDaoInstance ??=
        _$CycleRatingDao(database, changeListener);
  }

  @override
  UserPrefsDao get userPrefsDao {
    return _userPrefsDaoInstance ??= _$UserPrefsDao(database, changeListener);
  }
}

class _$CycleEntryDao extends CycleEntryDao {
  _$CycleEntryDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _cycleEntryInsertionAdapter = InsertionAdapter(
            database,
            'cycle_entries',
            (CycleEntry item) => <String, Object?>{
                  'id': item.id,
                  'startDate': item.startDate,
                  'endDate': item.endDate,
                  'notes': item.notes,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt
                }),
        _cycleEntryUpdateAdapter = UpdateAdapter(
            database,
            'cycle_entries',
            ['id'],
            (CycleEntry item) => <String, Object?>{
                  'id': item.id,
                  'startDate': item.startDate,
                  'endDate': item.endDate,
                  'notes': item.notes,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt
                }),
        _cycleEntryDeletionAdapter = DeletionAdapter(
            database,
            'cycle_entries',
            ['id'],
            (CycleEntry item) => <String, Object?>{
                  'id': item.id,
                  'startDate': item.startDate,
                  'endDate': item.endDate,
                  'notes': item.notes,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CycleEntry> _cycleEntryInsertionAdapter;

  final UpdateAdapter<CycleEntry> _cycleEntryUpdateAdapter;

  final DeletionAdapter<CycleEntry> _cycleEntryDeletionAdapter;

  @override
  Future<List<CycleEntry>> findAllEntries() async {
    return _queryAdapter.queryList(
        'SELECT * FROM cycle_entries ORDER BY startDate DESC',
        mapper: (Map<String, Object?> row) => CycleEntry(
            id: row['id'] as int?,
            startDate: row['startDate'] as String,
            endDate: row['endDate'] as String?,
            notes: row['notes'] as String?,
            createdAt: row['createdAt'] as String,
            updatedAt: row['updatedAt'] as String));
  }

  @override
  Future<CycleEntry?> findEntryById(int id) async {
    return _queryAdapter.query('SELECT * FROM cycle_entries WHERE id = ?1',
        mapper: (Map<String, Object?> row) => CycleEntry(
            id: row['id'] as int?,
            startDate: row['startDate'] as String,
            endDate: row['endDate'] as String?,
            notes: row['notes'] as String?,
            createdAt: row['createdAt'] as String,
            updatedAt: row['updatedAt'] as String),
        arguments: [id]);
  }

  @override
  Future<int> insertEntry(CycleEntry entry) {
    return _cycleEntryInsertionAdapter.insertAndReturnId(
        entry, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateEntry(CycleEntry entry) {
    return _cycleEntryUpdateAdapter.updateAndReturnChangedRows(
        entry, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteEntry(CycleEntry entry) {
    return _cycleEntryDeletionAdapter.deleteAndReturnChangedRows(entry);
  }
}

class _$CycleRatingDao extends CycleRatingDao {
  _$CycleRatingDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _cycleRatingInsertionAdapter = InsertionAdapter(
            database,
            'cycle_ratings',
            (CycleRating item) => <String, Object?>{
                  'id': item.id,
                  'cycleEntryId': item.cycleEntryId,
                  'comfortLevel': item.comfortLevel,
                  'hadCramps': item.hadCramps ? 1 : 0,
                  'hadHeadache': item.hadHeadache ? 1 : 0,
                  'hadMoodSwings': item.hadMoodSwings ? 1 : 0,
                  'hadBloating': item.hadBloating ? 1 : 0,
                  'flowLevel': item.flowLevel
                }),
        _cycleRatingUpdateAdapter = UpdateAdapter(
            database,
            'cycle_ratings',
            ['id'],
            (CycleRating item) => <String, Object?>{
                  'id': item.id,
                  'cycleEntryId': item.cycleEntryId,
                  'comfortLevel': item.comfortLevel,
                  'hadCramps': item.hadCramps ? 1 : 0,
                  'hadHeadache': item.hadHeadache ? 1 : 0,
                  'hadMoodSwings': item.hadMoodSwings ? 1 : 0,
                  'hadBloating': item.hadBloating ? 1 : 0,
                  'flowLevel': item.flowLevel
                }),
        _cycleRatingDeletionAdapter = DeletionAdapter(
            database,
            'cycle_ratings',
            ['id'],
            (CycleRating item) => <String, Object?>{
                  'id': item.id,
                  'cycleEntryId': item.cycleEntryId,
                  'comfortLevel': item.comfortLevel,
                  'hadCramps': item.hadCramps ? 1 : 0,
                  'hadHeadache': item.hadHeadache ? 1 : 0,
                  'hadMoodSwings': item.hadMoodSwings ? 1 : 0,
                  'hadBloating': item.hadBloating ? 1 : 0,
                  'flowLevel': item.flowLevel
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CycleRating> _cycleRatingInsertionAdapter;

  final UpdateAdapter<CycleRating> _cycleRatingUpdateAdapter;

  final DeletionAdapter<CycleRating> _cycleRatingDeletionAdapter;

  @override
  Future<CycleRating?> findRatingForEntry(int cycleEntryId) async {
    return _queryAdapter.query(
        'SELECT * FROM cycle_ratings WHERE cycleEntryId = ?1',
        mapper: (Map<String, Object?> row) => CycleRating(
            id: row['id'] as int?,
            cycleEntryId: row['cycleEntryId'] as int,
            comfortLevel: row['comfortLevel'] as int,
            hadCramps: (row['hadCramps'] as int) != 0,
            hadHeadache: (row['hadHeadache'] as int) != 0,
            hadMoodSwings: (row['hadMoodSwings'] as int) != 0,
            hadBloating: (row['hadBloating'] as int) != 0,
            flowLevel: row['flowLevel'] as String),
        arguments: [cycleEntryId]);
  }

  @override
  Future<int> insertRating(CycleRating rating) {
    return _cycleRatingInsertionAdapter.insertAndReturnId(
        rating, OnConflictStrategy.abort);
  }

  @override
  Future<int> updateRating(CycleRating rating) {
    return _cycleRatingUpdateAdapter.updateAndReturnChangedRows(
        rating, OnConflictStrategy.abort);
  }

  @override
  Future<int> deleteRating(CycleRating rating) {
    return _cycleRatingDeletionAdapter.deleteAndReturnChangedRows(rating);
  }
}

class _$UserPrefsDao extends UserPrefsDao {
  _$UserPrefsDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _userPrefsInsertionAdapter = InsertionAdapter(
            database,
            'user_prefs',
            (UserPrefs item) => <String, Object?>{
                  'id': item.id,
                  'preferredCycleLength': item.preferredCycleLength,
                  'preferredPeriodLength': item.preferredPeriodLength,
                  'notificationLeadDays': item.notificationLeadDays,
                  'notificationsEnabled': item.notificationsEnabled ? 1 : 0,
                  'onboardingComplete': item.onboardingComplete ? 1 : 0
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<UserPrefs> _userPrefsInsertionAdapter;

  @override
  Future<UserPrefs?> getUserPrefs() async {
    return _queryAdapter.query('SELECT * FROM user_prefs WHERE id = 1',
        mapper: (Map<String, Object?> row) => UserPrefs(
            id: row['id'] as int,
            preferredCycleLength: row['preferredCycleLength'] as int,
            preferredPeriodLength: row['preferredPeriodLength'] as int,
            notificationLeadDays: row['notificationLeadDays'] as int,
            notificationsEnabled: (row['notificationsEnabled'] as int) != 0,
            onboardingComplete: (row['onboardingComplete'] as int) != 0));
  }

  @override
  Future<void> insertOrUpdatePrefs(UserPrefs prefs) async {
    await _userPrefsInsertionAdapter.insert(prefs, OnConflictStrategy.replace);
  }
}

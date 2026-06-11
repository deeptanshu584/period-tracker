import 'package:floor/floor.dart';
import 'cycle_entry.dart';

@Entity(
  tableName: 'cycle_ratings',
  foreignKeys: [
    ForeignKey(
      childColumns: ['cycleEntryId'],
      parentColumns: ['id'],
      entity: CycleEntry,
      onDelete: ForeignKeyAction.cascade,
    )
  ],
)
class CycleRating {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int cycleEntryId;
  final int comfortLevel; // 1–5
  final bool hadCramps;
  final bool hadHeadache;
  final bool hadMoodSwings;
  final bool hadBloating;
  final String flowLevel; // 'light' | 'medium' | 'heavy' stored as string

  CycleRating({
    this.id,
    required this.cycleEntryId,
    required this.comfortLevel,
    required this.hadCramps,
    required this.hadHeadache,
    required this.hadMoodSwings,
    required this.hadBloating,
    required this.flowLevel,
  });

  CycleRating copyWith({
    int? id,
    int? cycleEntryId,
    int? comfortLevel,
    bool? hadCramps,
    bool? hadHeadache,
    bool? hadMoodSwings,
    bool? hadBloating,
    String? flowLevel,
  }) {
    return CycleRating(
      id: id ?? this.id,
      cycleEntryId: cycleEntryId ?? this.cycleEntryId,
      comfortLevel: comfortLevel ?? this.comfortLevel,
      hadCramps: hadCramps ?? this.hadCramps,
      hadHeadache: hadHeadache ?? this.hadHeadache,
      hadMoodSwings: hadMoodSwings ?? this.hadMoodSwings,
      hadBloating: hadBloating ?? this.hadBloating,
      flowLevel: flowLevel ?? this.flowLevel,
    );
  }
}

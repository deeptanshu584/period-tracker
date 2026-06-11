import 'package:floor/floor.dart';

@Entity(tableName: 'cycle_entries')
class CycleEntry {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String startDate; // stored as UTC ISO-8601 string
  final String? endDate;  // nullable
  final String? notes;    // max 500 chars
  final String createdAt;
  final String updatedAt;

  CycleEntry({
    this.id,
    required this.startDate,
    this.endDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper properties to work with DateTime
  DateTime get startDateTime => DateTime.parse(startDate);
  DateTime? get endDateTime => endDate != null ? DateTime.parse(endDate!) : null;

  // Computed — never stored in DB
  int get durationDays {
    if (endDateTime != null) {
      return endDateTime!.difference(startDateTime).inDays + 1;
    }
    final elapsed = DateTime.now().difference(startDateTime).inDays;
    return elapsed.clamp(1, 7);
  }

  bool get isOngoing => endDate == null;

  CycleEntry copyWith({
    int? id,
    String? startDate,
    String? endDate,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return CycleEntry(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

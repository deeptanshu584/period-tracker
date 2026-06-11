import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/cycle_entry.dart';
import '../../data/models/prediction_result.dart';
import '../history/cycle_detail_sheet.dart';
import '../log_period/log_period_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'calendar_bloc.dart';
import '../home/home_bloc.dart';
import '../history/history_bloc.dart';

class DayDetailSheet extends StatelessWidget {
  final DateTime day;
  final List<CycleEntry> entries;
  final PredictionResult? prediction;

  const DayDetailSheet({
    super.key,
    required this.day,
    required this.entries,
    this.prediction,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  CycleEntry? _getLoggedEntry(DateTime day) {
    for (var entry in entries) {
      final start = entry.startDateTime.toLocal();
      final end = entry.endDateTime?.toLocal() ?? DateTime.now(); // approximate
      final d = DateTime(day.year, day.month, day.day);
      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);
      if (d.compareTo(s) >= 0 && d.compareTo(e) <= 0) return entry;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final entry = _getLoggedEntry(day);
    final isLogged = entry != null;
    
    bool isPredicted = false;
    bool isFertile = false;
    bool isOvulation = false;

    if (prediction != null) {
      final start = prediction!.nextPeriodStart.toLocal();
      final end = start.add(const Duration(days: 4));
      final d = DateTime(day.year, day.month, day.day);
      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);
      isPredicted = d.compareTo(s) >= 0 && d.compareTo(e) <= 0;

      final fStart = prediction!.fertileWindowStart.toLocal();
      final fEnd = prediction!.fertileWindowEnd.toLocal();
      final fs = DateTime(fStart.year, fStart.month, fStart.day);
      final fe = DateTime(fEnd.year, fEnd.month, fEnd.day);
      isFertile = d.compareTo(fs) >= 0 && d.compareTo(fe) <= 0;

      isOvulation = _isSameDay(day, prediction!.ovulationDay.toLocal());
    }

    // Determine if we can log a period today
    final isFuture = day.isAfter(DateTime.now());
    final isOngoing = entries.isNotEmpty && entries.last.isOngoing;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text(DateFormat('EEEE, MMM d').format(day), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          
          if (isLogged) const ListTile(leading: Icon(Icons.water_drop, color: Colors.red), title: Text("Period day (logged)")),
          if (isPredicted && !isLogged) const ListTile(leading: Icon(Icons.water_drop_outlined, color: Colors.red), title: Text("Predicted period day")),
          if (isFertile) const ListTile(leading: Icon(Icons.favorite_border, color: Colors.green), title: Text("Fertile window")),
          if (isOvulation) const ListTile(leading: Icon(Icons.egg_alt_outlined, color: Colors.green), title: Text("Ovulation day")),
          
          if (!isLogged && !isPredicted && !isFertile && !isOvulation)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text("No data for this day."),
            ),

          const SizedBox(height: 24),

          if (isLogged && entry != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => CycleDetailSheet(entry: entry),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text("View Details"),
              ),
            ),

          if (!isOngoing && !isFuture && !isLogged)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) {
                      final newEntry = CycleEntry(
                        startDate: day.toUtc().toIso8601String(),
                        createdAt: DateTime.now().toUtc().toIso8601String(),
                        updatedAt: DateTime.now().toUtc().toIso8601String(),
                      );
                      return LogPeriodSheet(entryToEdit: newEntry);
                    },
                  ).then((_) {
                    if (context.mounted) {
                      context.read<CalendarBloc>().add(CalendarStarted());
                      context.read<HistoryBloc>().add(HistoryStarted());
                      context.read<HomeBloc>().add(HomeStarted());
                    }
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Log Period Starting Today"),
              ),
            ),
            
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

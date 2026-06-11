import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/cycle_entry.dart';
import 'history_bloc.dart';
import '../home/home_bloc.dart'; // To refresh home after delete/edit
import '../log_period/log_period_sheet.dart';

class CycleDetailSheet extends StatelessWidget {
  final CycleEntry entry;
  const CycleDetailSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final startStr = fmt.format(entry.startDateTime.toLocal());
    final endStr = entry.endDateTime != null ? fmt.format(entry.endDateTime!.toLocal()) : "Ongoing";

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
          Text("$startStr – $endStr", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text("Duration"),
            trailing: Text("${entry.durationDays} days ${entry.isOngoing ? '(capped)' : ''}", style: const TextStyle(fontSize: 16)),
          ),
          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text("Notes", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(entry.notes!),
            ),
          ] else ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text("Notes", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("No notes added.", style: TextStyle(color: Colors.grey)),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close detail sheet
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => LogPeriodSheet(entryToEdit: entry),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<HistoryBloc>().add(HistoryStarted());
                      context.read<HomeBloc>().add(HomeStarted());
                    }
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text("Edit"),
              ),
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text("Delete Period"),
                      content: const Text("Are you sure you want to delete this log?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancel")),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    Navigator.pop(context); // close sheet
                    context.read<HistoryBloc>().add(HistoryDeleteConfirmed(entry));
                    context.read<HomeBloc>().add(HomeStarted());
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete),
                label: const Text("Delete"),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

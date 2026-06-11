import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../data/models/cycle_entry.dart';

class LogPeriodSheet extends StatefulWidget {
  final CycleEntry? entryToEdit;
  const LogPeriodSheet({super.key, this.entryToEdit});

  @override
  State<LogPeriodSheet> createState() => _LogPeriodSheetState();
}

class _LogPeriodSheetState extends State<LogPeriodSheet> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      startDate = widget.entryToEdit!.startDateTime;
      endDate = widget.entryToEdit!.endDateTime;
    } else {
      startDate = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.entryToEdit == null ? "Log Period" : "Edit/End Period", 
               style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.water_drop_outlined, color: Colors.red),
            title: const Text("Start Date"),
            subtitle: Text(startDate != null ? startDate!.toLocal().toString().split(' ')[0] : "Select"),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => startDate = d);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text("End Date"),
            subtitle: Text(endDate != null ? endDate!.toLocal().toString().split(' ')[0] : "Ongoing (Leave empty if still active)"),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: endDate ?? startDate ?? DateTime.now(),
                firstDate: startDate ?? DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => endDate = d);
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (startDate == null) return;
                final repo = context.read<CycleRepository>();
                final entry = CycleEntry(
                  id: widget.entryToEdit?.id,
                  startDate: startDate!.toUtc().toIso8601String(),
                  endDate: endDate?.toUtc().toIso8601String(),
                  createdAt: widget.entryToEdit?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
                  updatedAt: DateTime.now().toUtc().toIso8601String(),
                );
                await repo.saveCycle(entry);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Save Entry"),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

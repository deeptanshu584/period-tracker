import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'history_bloc.dart';
import 'cycle_detail_sheet.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const ListTile(
                title: Text("Loading..."), // Using basic text instead of shimmer package for brevity
              ),
            );
          } else if (state is HistoryEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("No periods logged yet. Tap + to start."),
                ],
              ),
            );
          } else if (state is HistoryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => context.read<HistoryBloc>().add(HistoryStarted()),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          } else if (state is HistoryLoaded || state is HistoryDeleting) {
            final entries = state is HistoryLoaded 
                ? state.entries 
                : (state as HistoryDeleting).props.isEmpty ? [] : []; // Realistically would keep state
            // Let's just refetch properly, but we have access to the bloc
            final List<dynamic> currentEntries = context.read<HistoryBloc>().state is HistoryLoaded
                ? (context.read<HistoryBloc>().state as HistoryLoaded).entries
                : (state is HistoryLoaded ? state.entries : []);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HistoryBloc>().add(HistoryStarted());
              },
              child: ListView.separated(
                itemCount: currentEntries.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = currentEntries[index];
                  final fmt = DateFormat('MMM d, yyyy');
                  final startStr = fmt.format(entry.startDateTime.toLocal());
                  final endStr = entry.endDateTime != null ? fmt.format(entry.endDateTime!.toLocal()) : "Ongoing";

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text("$startStr – $endStr", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${entry.durationDays} days"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => CycleDetailSheet(entry: entry),
                      );
                    },
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

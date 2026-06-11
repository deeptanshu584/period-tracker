import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'home_bloc.dart';
import '../log_period/log_period_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HomeNoHistory) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("Welcome!", style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  const Text("Log your first period to start getting predictions."),
                ],
              ),
            );
          } else if (state is HomeLoaded) {
            final pred = state.prediction;
            final fmt = DateFormat('MMM d, yyyy');
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.ongoingPeriod != null)
                  Card(
                    color: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.water_drop, color: Colors.red),
                      title: const Text("Period in progress", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      subtitle: const Text("Tap to end or edit"),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => LogPeriodSheet(entryToEdit: state.ongoingPeriod),
                        ).then((_) {
                           context.read<HomeBloc>().add(HomeStarted());
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text("Next Predicted Period"),
                    subtitle: Text(fmt.format(pred.nextPeriodStart.toLocal()), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: const Text("Fertile Window"),
                    subtitle: Text("${fmt.format(pred.fertileWindowStart.toLocal())} - ${fmt.format(pred.fertileWindowEnd.toLocal())}"),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.egg_alt_outlined),
                    title: const Text("Estimated Ovulation"),
                    subtitle: Text(fmt.format(pred.ovulationDay.toLocal())),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          bool isOngoing = false;
          if (state is HomeLoaded && state.ongoingPeriod != null) {
            isOngoing = true;
          }
          
          if (isOngoing) return const SizedBox.shrink(); // Hide FAB if ongoing

          return FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const LogPeriodSheet(),
              ).then((_) {
                 context.read<HomeBloc>().add(HomeStarted());
              });
            },
            label: const Text('Log Period'),
            icon: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

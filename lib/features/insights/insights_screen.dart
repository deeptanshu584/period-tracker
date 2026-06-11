import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'insights_bloc.dart';
import '../../domain/irregularity_detector.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  Widget _buildCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  String _getRegularityLabel(CycleRegularity reg) {
    switch (reg) {
      case CycleRegularity.regular: return "Regular ✓";
      case CycleRegularity.slightlyIrregular: return "Slightly Irregular";
      case CycleRegularity.irregular: return "Irregular";
      case CycleRegularity.insufficientData: return "Not enough data";
    }
  }

  Color _getRegularityColor(CycleRegularity reg) {
    switch (reg) {
      case CycleRegularity.regular: return Colors.green;
      case CycleRegularity.slightlyIrregular: return Colors.orange;
      case CycleRegularity.irregular: return Colors.red;
      case CycleRegularity.insufficientData: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<InsightsBloc, InsightsState>(
        builder: (context, state) {
          if (state is InsightsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is InsightsError) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => context.read<InsightsBloc>().add(InsightsRefreshRequested()),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          } else if (state is InsightsInsufficient) {
            return ListView(
              padding: const EdgeInsets.only(top: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text("Log at least 2 periods to see your personalized insights.", style: TextStyle(color: Colors.grey)),
                ),
                _buildCard(context, "Regularity", "—", Icons.query_stats),
                _buildCard(context, "Average Cycle Length", "—", Icons.calendar_month),
                _buildCard(context, "Average Period Duration", "—", Icons.water_drop),
                _buildCard(context, "Shortest / Longest Cycle", "—", Icons.compare_arrows),
                _buildCard(context, "Total Cycles Logged", "${state.totalCycles}", Icons.history),
              ],
            );
          } else if (state is InsightsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<InsightsBloc>().add(InsightsRefreshRequested());
              },
              child: ListView(
                padding: const EdgeInsets.only(top: 16, bottom: 32),
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.health_and_safety, color: _getRegularityColor(state.regularity)),
                              const SizedBox(width: 16),
                              Text(_getRegularityLabel(state.regularity), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(state.regularityExplanation),
                        ],
                      ),
                    ),
                  ),
                  _buildCard(context, "Average Cycle Length", "${state.averageCycleLength.toStringAsFixed(1)} days", Icons.calendar_month),
                  _buildCard(context, "Average Period Duration", "${state.averagePeriodDuration.toStringAsFixed(1)} days", Icons.water_drop),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      leading: Icon(Icons.compare_arrows, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Cycle Range"),
                      subtitle: Text("Shortest: ${state.shortestCycle}d · Longest: ${state.longestCycle}d"),
                    ),
                  ),
                  _buildCard(context, "Total Cycles Logged", "${state.totalCycles}", Icons.history),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

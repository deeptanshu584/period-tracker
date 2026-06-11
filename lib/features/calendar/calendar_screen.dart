import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'calendar_bloc.dart';
import 'calendar_widget.dart';
import 'day_detail_sheet.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<CalendarBloc, CalendarState>(
        builder: (context, state) {
          if (state is CalendarLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CalendarError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: () => context.read<CalendarBloc>().add(CalendarStarted()),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          } else if (state is CalendarLoaded) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: CalendarWidget(
                currentMonth: state.currentMonth,
                entries: state.entries,
                prediction: state.prediction,
                onMonthChanged: (newMonth) {
                  context.read<CalendarBloc>().add(CalendarMonthChanged(newMonth));
                },
                onDayTapped: (day) {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => DayDetailSheet(
                      day: day,
                      entries: state.entries,
                      prediction: state.prediction,
                    ),
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

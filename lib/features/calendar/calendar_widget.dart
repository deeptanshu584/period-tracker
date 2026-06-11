import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/cycle_entry.dart';
import '../../data/models/prediction_result.dart';

class CalendarWidget extends StatelessWidget {
  final DateTime currentMonth;
  final List<CycleEntry> entries;
  final PredictionResult? prediction;
  final Function(DateTime) onMonthChanged;
  final Function(DateTime) onDayTapped;

  const CalendarWidget({
    super.key,
    required this.currentMonth,
    required this.entries,
    required this.prediction,
    required this.onMonthChanged,
    required this.onDayTapped,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isLoggedPeriodDay(DateTime day) {
    for (var entry in entries) {
      final start = entry.startDateTime.toLocal();
      final end = entry.endDateTime?.toLocal() ?? DateTime.now(); // approximate
      
      // Zero out time
      final d = DateTime(day.year, day.month, day.day);
      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);
      
      if (d.compareTo(s) >= 0 && d.compareTo(e) <= 0) return true;
    }
    return false;
  }

  bool _isPredictedPeriodDay(DateTime day) {
    if (prediction == null) return false;
    final start = prediction!.nextPeriodStart.toLocal();
    final end = start.add(const Duration(days: 4)); // Using 5 days (start + 4) as visual proxy
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return d.compareTo(s) >= 0 && d.compareTo(e) <= 0;
  }

  bool _isFertileWindow(DateTime day) {
    if (prediction == null) return false;
    final start = prediction!.fertileWindowStart.toLocal();
    final end = prediction!.fertileWindowEnd.toLocal();
    final d = DateTime(day.year, day.month, day.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return d.compareTo(s) >= 0 && d.compareTo(e) <= 0;
  }

  bool _isOvulationDay(DateTime day) {
    if (prediction == null) return false;
    return _isSameDay(day, prediction!.ovulationDay.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    
    // Calculate leading empty days (assuming Sunday = 7, Monday = 1)
    int firstWeekday = firstDayOfMonth.weekday;
    if (firstWeekday == 7) firstWeekday = 0; // Make Sunday 0 for easier math

    final totalDays = lastDayOfMonth.day;
    final weeks = ((totalDays + firstWeekday) / 7).ceil();

    return Column(
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onMonthChanged(DateTime(currentMonth.year, currentMonth.month - 1)),
            ),
            Text(DateFormat('MMMM yyyy').format(currentMonth), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                // Do not render months more than 3 months in the future
                if (nextMonth.isBefore(DateTime.now().add(const Duration(days: 90)))) {
                  onMonthChanged(nextMonth);
                }
              },
            ),
          ],
        ),
        
        // Days of week
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text(d, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))))
              .toList(),
        ),

        // Grid
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: weeks * 7,
            itemBuilder: (context, index) {
              if (index < firstWeekday || index >= firstWeekday + totalDays) {
                return const SizedBox.shrink(); // Empty day
              }

              final dayNum = index - firstWeekday + 1;
              final currentDay = DateTime(currentMonth.year, currentMonth.month, dayNum);
              
              final isToday = _isSameDay(currentDay, DateTime.now());
              final isLogged = _isLoggedPeriodDay(currentDay);
              final isPredicted = _isPredictedPeriodDay(currentDay);
              final isFertile = _isFertileWindow(currentDay);
              final isOvulation = _isOvulationDay(currentDay);

              // Styling according to SCREENS.md
              Color? bgColor;
              Color? borderColor;
              Color textColor = Colors.black;

              if (isLogged) {
                bgColor = Colors.red;
                textColor = Colors.white;
              } else if (isPredicted) {
                bgColor = Colors.red.withOpacity(0.2);
                borderColor = Colors.red;
                textColor = Colors.red;
              } else if (isFertile) {
                bgColor = Colors.green.withOpacity(0.2);
              }

              if (isToday && !isLogged) {
                borderColor = Colors.black;
              }

              return GestureDetector(
                onTap: () => onDayTapped(currentDay),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: borderColor != null 
                        ? (isPredicted && !isLogged ? Border.all(color: borderColor, style: BorderStyle.solid) // Basic border instead of dashed for simplicity
                                                    : Border.all(color: borderColor)) 
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(dayNum.toString(), style: TextStyle(color: textColor, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                      if (isOvulation)
                        Positioned(
                          bottom: 2,
                          child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

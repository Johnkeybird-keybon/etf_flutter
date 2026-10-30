import 'package:flutter/material.dart';

class MonthYearSelector extends StatelessWidget {
  final int month;
  final int year;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const MonthYearSelector({
    super.key,
    required this.month,
    required this.year,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().year;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      DropdownButton<int>(
        value: month,
        items: List.generate(12, (i) =>
            DropdownMenuItem(value: i + 1, child: Text(_months[i]))),
        onChanged: (v) => v != null ? onMonthChanged(v) : null,
      ),
      const SizedBox(width: 8),
      DropdownButton<int>(
        value: year,
        items: List.generate(7, (i) {
          final y = now - 5 + i;
          return DropdownMenuItem(value: y, child: Text('$y'));
        }),
        onChanged: (v) => v != null ? onYearChanged(v) : null,
      ),
    ]);
  }
}
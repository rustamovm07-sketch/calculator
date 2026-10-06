import 'package:flutter/material.dart';

enum DateRangeMode { today, sevenDays, month, year, custom }

class DateRange {
  const DateRange({
    required this.start,
    required this.endExclusive,
    required this.label,
  });

  final DateTime start;
  final DateTime endExclusive;
  final String label;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(endExclusive);
}

class DateRangeSelector extends StatefulWidget {
  const DateRangeSelector({required this.onChanged, super.key});

  final ValueChanged<DateRange> onChanged;

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  DateRangeMode _mode = DateRangeMode.today;
  DateTimeRange? _custom;

  DateRange _range() {
    final today = DateUtils.dateOnly(DateTime.now());
    return switch (_mode) {
      DateRangeMode.today => DateRange(
          start: today,
          endExclusive: today.add(const Duration(days: 1)),
          label: 'Bugun',
        ),
      DateRangeMode.sevenDays => DateRange(
          start: today.subtract(const Duration(days: 6)),
          endExclusive: today.add(const Duration(days: 1)),
          label: 'Oxirgi 7 kun',
        ),
      DateRangeMode.month => DateRange(
          start: DateTime(today.year, today.month),
          endExclusive: DateTime(today.year, today.month + 1),
          label: 'Bu oy',
        ),
      DateRangeMode.year => DateRange(
          start: DateTime(today.year),
          endExclusive: DateTime(today.year + 1),
          label: 'Bu yil',
        ),
      DateRangeMode.custom => DateRange(
          start: _custom?.start ?? today,
          endExclusive: (_custom?.end ?? today).add(const Duration(days: 1)),
          label: _custom == null
              ? 'Maxsus davr'
              : '${_custom!.start.day.toString().padLeft(2, '0')}.${_custom!.start.month.toString().padLeft(2, '0')}.${_custom!.start.year} – '
                  '${_custom!.end.day.toString().padLeft(2, '0')}.${_custom!.end.month.toString().padLeft(2, '0')}.${_custom!.end.year}',
        ),
    };
  }

  Future<void> _selectCustom() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final chosen = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 20),
      initialDateRange: _custom ?? DateTimeRange(start: today, end: today),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _mode = DateRangeMode.custom;
      _custom = chosen;
    });
    widget.onChanged(_range());
  }

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _choice('Bugun', DateRangeMode.today),
          _choice('7 kun', DateRangeMode.sevenDays),
          _choice('Bu oy', DateRangeMode.month),
          _choice('Bu yil', DateRangeMode.year),
          ActionChip(
            avatar: const Icon(Icons.date_range_outlined, size: 18),
            label:
                Text(_mode == DateRangeMode.custom ? _range().label : 'Maxsus'),
            onPressed: _selectCustom,
          ),
        ],
      );

  Widget _choice(String label, DateRangeMode mode) => ChoiceChip(
        label: Text(label),
        selected: _mode == mode,
        onSelected: (selected) {
          if (!selected) return;
          setState(() => _mode = mode);
          widget.onChanged(_range());
        },
      );
}

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../widgets/calendar_widget.dart';
import 'document_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  final _db = DatabaseHelper.instance;
  DateTime _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Set<String> _datesWithEntries = {};
  Set<String> _datesWithIncompleteTodos = {};

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final entries = await _db.getDatesWithEntries();
    final incomplete = await _db.getDatesWithIncompleteTodos();
    if (mounted) {
      setState(() {
        _datesWithEntries = entries;
        _datesWithIncompleteTodos = incomplete;
      });
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _openDate(DateTime date) async {
    final key = _dateKey(date);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentScreen(date: key),
      ),
    );
    refresh();
  }

  Future<void> openToday() async {
    await _openDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: CalendarWidget(
          displayMonth: _displayMonth,
          datesWithEntries: _datesWithEntries,
          datesWithIncompleteTodos: _datesWithIncompleteTodos,
          onDateTap: _openDate,
          onPreviousMonth: () {
            setState(() {
              _displayMonth = DateTime(
                  _displayMonth.year, _displayMonth.month - 1);
            });
          },
          onNextMonth: () {
            setState(() {
              _displayMonth = DateTime(
                  _displayMonth.year, _displayMonth.month + 1);
            });
          },
        ),
      ),
    );
  }
}

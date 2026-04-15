import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../utils/date_formatter.dart';
import 'document_screen.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final _db = DatabaseHelper.instance;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  int? _selectedYear;
  int? _selectedMonth;

  final int _currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _selectedYear = _currentYear;
    _selectedMonth = DateTime.now().month;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await _db.getIncompleteTodos(
      year: _selectedYear,
      month: _selectedMonth,
    );
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Generate year list
    final years = List.generate(5, (i) => _currentYear - 2 + i);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.filterIncompleteTodos),
      ),
      body: Column(
        children: [
          // Filter controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Year picker
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      labelText: loc.year,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(loc.allTime),
                      ),
                      ...years.map((y) => DropdownMenuItem<int?>(
                            value: y,
                            child: Text('$y'),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedYear = v;
                        if (v == null) _selectedMonth = null;
                      });
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Month picker
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: loc.month,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(loc.allTime),
                      ),
                      ...List.generate(
                        12,
                        (i) => DropdownMenuItem<int?>(
                          value: i + 1,
                          child: Text(loc.monthNames[i]),
                        ),
                      ),
                    ],
                    onChanged: _selectedYear == null
                        ? null
                        : (v) {
                            setState(() => _selectedMonth = v);
                            _loadData();
                          },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Results
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          loc.noTodos,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final row = _results[index];
                          final date = row['entry_date'] as String;
                          final content = row['content'] as String;

                          return ListTile(
                            leading: Icon(
                              Icons.radio_button_unchecked,
                              color: Colors.orange.shade600,
                            ),
                            title: Text(content),
                            subtitle: Text(
                              formatEntryDate(date, loc),
                              style: theme.textTheme.bodySmall,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DocumentScreen(date: date),
                                ),
                              );
                              _loadData();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

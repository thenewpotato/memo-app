import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/diary_entry.dart';
import '../models/todo_item.dart';
import '../l10n/app_localizations.dart';
import 'document_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => TaskListScreenState();
}

class TaskListScreenState extends State<TaskListScreen> {
  final _db = DatabaseHelper.instance;
  List<DiaryEntry> _entries = [];
  Map<int, List<TodoItem>> _todosByEntry = {};
  Set<String> _datesWithIncompleteTodos = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    final entries = await _db.getAllEntries();
    final Map<int, List<TodoItem>> todosMap = {};
    for (final entry in entries) {
      todosMap[entry.id!] = await _db.getTodosForEntry(entry.id!);
    }
    final incomplete = await _db.getDatesWithIncompleteTodos();
    if (mounted) {
      setState(() {
        _entries = entries;
        _todosByEntry = todosMap;
        _datesWithIncompleteTodos = incomplete;
        _loading = false;
      });
    }
  }

  Future<void> _openEntry(DiaryEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentScreen(date: entry.date),
      ),
    );
    refresh();
  }

  String _formatDate(String dateStr, AppLocalizations loc) {
    final parts = dateStr.split('-');
    final dt = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final monthName = loc.monthNames[dt.month - 1];
    return '${dt.day} $monthName ${dt.year}';
  }

  bool _entryHasContent(DiaryEntry entry) {
    final todos = _todosByEntry[entry.id] ?? [];
    return entry.textContent.isNotEmpty || todos.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter out entries with no content
    final visibleEntries =
        _entries.where((e) => _entryHasContent(e)).toList();

    if (visibleEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            loc.noEntries,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: visibleEntries.length,
        itemBuilder: (context, index) {
          final entry = visibleEntries[index];
          final todos = _todosByEntry[entry.id] ?? [];
          final hasIncompleteTodo =
              _datesWithIncompleteTodos.contains(entry.date);
          final incompleteCount =
              todos.where((t) => t.isIncomplete).length;
          final completedCount = todos
              .where((t) =>
                  t.status == TodoStatus.completed ||
                  t.status == TodoStatus.excellent)
              .length;

          return Card(
            margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openEntry(entry),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (hasIncompleteTodo)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _formatDate(entry.date, loc),
                            style:
                                theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (todos.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$completedCount/${todos.length}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (entry.textContent.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.textContent.length > 100
                            ? '${entry.textContent.substring(0, 100)}...'
                            : entry.textContent,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (incompleteCount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.radio_button_unchecked,
                              size: 16,
                              color: Colors.orange.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '$incompleteCount ${loc.incomplete}',
                            style:
                                theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

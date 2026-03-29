import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/diary_entry.dart';
import '../models/todo_item.dart';
import '../l10n/app_localizations.dart';
import '../widgets/todo_item_widget.dart';

class DocumentScreen extends StatefulWidget {
  final String date; // yyyy-MM-dd

  const DocumentScreen({super.key, required this.date});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final _db = DatabaseHelper.instance;
  final _textController = TextEditingController();
  final _todoInputController = TextEditingController();
  final _textFocus = FocusNode();
  final _todoInputFocus = FocusNode();

  DiaryEntry? _entry;
  List<TodoItem> _todos = [];
  bool _loading = true;
  bool _textDirty = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _saveTextIfDirty();
    _textController.dispose();
    _todoInputController.dispose();
    _textFocus.dispose();
    _todoInputFocus.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final entry = await _db.getOrCreateEntry(widget.date);
    final todos = await _db.getTodosForEntry(entry.id!);
    if (mounted) {
      setState(() {
        _entry = entry;
        _todos = todos;
        _textController.text = entry.textContent;
        _loading = false;
      });
    }
  }

  Future<void> _saveTextIfDirty() async {
    if (_textDirty && _entry != null) {
      await _db.updateEntryText(_entry!.id!, _textController.text);
      _textDirty = false;
    }
  }

  Future<void> _addTodo() async {
    final text = _todoInputController.text.trim();
    if (text.isEmpty || _entry == null) return;

    final todo = TodoItem(
      entryId: _entry!.id!,
      content: text,
      sortOrder: _todos.length,
    );
    final inserted = await _db.insertTodo(todo);
    setState(() {
      _todos.add(inserted);
      _todoInputController.clear();
    });
  }

  Future<void> _toggleTodoStatus(int index) async {
    final todo = _todos[index];
    final newStatus = todo.status.next();
    await _db.updateTodoStatus(todo.id!, newStatus);
    setState(() {
      _todos[index] = todo.copyWith(status: newStatus);
    });
  }

  Future<void> _setTodoStatus(int index, TodoStatus status) async {
    final todo = _todos[index];
    await _db.updateTodoStatus(todo.id!, status);
    setState(() {
      _todos[index] = todo.copyWith(status: status);
    });
  }

  Future<void> _deleteTodo(int index) async {
    final todo = _todos[index];
    await _db.deleteTodo(todo.id!);
    setState(() {
      _todos.removeAt(index);
    });
    if (mounted) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.todoDeleted)),
      );
    }
  }

  Future<void> _editTodoContent(int index) async {
    final todo = _todos[index];
    final controller = TextEditingController(text: todo.content);
    final loc = AppLocalizations.of(context);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.editTodo),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: loc.newTodoHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(loc.save),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result != null && result.isNotEmpty) {
      await _db.updateTodoContent(todo.id!, result);
      setState(() {
        _todos[index] = todo.copyWith(content: result);
      });
    }
  }

  String _formatDateHeader() {
    final parts = widget.date.split('-');
    final dt = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final loc = AppLocalizations.of(context);
    final monthName = loc.monthNames[dt.month - 1];
    return '${dt.day} $monthName ${dt.year}';
  }

  Future<void> _deleteEntry() async {
    final loc = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteEntry),
        content: Text(loc.deleteEntryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.confirm,
                style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );

    if (confirmed == true && _entry != null) {
      await _db.deleteEntry(_entry!.id!);
      if (mounted) {
        Navigator.pop(context, true); // true means entry was deleted
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDateHeader()),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteEntry,
            tooltip: loc.deleteEntry,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
          _saveTextIfDirty();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Notes section
            Row(
              children: [
                Icon(Icons.note_alt_outlined,
                    color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  loc.notes,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              focusNode: _textFocus,
              maxLines: null,
              minLines: 4,
              decoration: InputDecoration(
                hintText: loc.tapToEdit,
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              onChanged: (_) {
                _textDirty = true;
              },
              onEditingComplete: _saveTextIfDirty,
            ),
            const SizedBox(height: 24),

            // Todos section
            Row(
              children: [
                Icon(Icons.checklist,
                    color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  loc.todos,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Todo items
            ..._todos.asMap().entries.map((e) {
              final index = e.key;
              final todo = e.value;
              return TodoItemWidget(
                todo: todo,
                onTapStatus: () => _toggleTodoStatus(index),
                onLongPress: () {
                  showTodoStatusMenu(
                    context,
                    todo,
                    (status) => _setTodoStatus(index, status),
                    () => _editTodoContent(index),
                    () => _deleteTodo(index),
                  );
                },
                onDelete: () => _deleteTodo(index),
                onContentChanged: (content) async {
                  await _db.updateTodoContent(todo.id!, content);
                  setState(() {
                    _todos[index] = todo.copyWith(content: content);
                  });
                },
              );
            }),

            // New todo input
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.add_circle_outline,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _todoInputController,
                    focusNode: _todoInputFocus,
                    decoration: InputDecoration(
                      hintText: loc.newTodoHint,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: theme.textTheme.bodyLarge,
                    onSubmitted: (_) {
                      _addTodo();
                      _todoInputFocus.requestFocus();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send,
                      color: theme.colorScheme.primary),
                  onPressed: () {
                    _addTodo();
                    _todoInputFocus.requestFocus();
                  },
                ),
              ],
            ),
            const SizedBox(height: 100), // Extra space for scroll
          ],
        ),
      ),
    );
  }
}

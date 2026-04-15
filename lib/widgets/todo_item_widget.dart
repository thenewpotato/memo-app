import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../l10n/app_localizations.dart';

class TodoItemWidget extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onTapStatus;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const TodoItemWidget({
    super.key,
    required this.todo,
    required this.onTapStatus,
    required this.onLongPress,
    required this.onDelete,
  });

  IconData _statusIcon(TodoStatus status) {
    switch (status) {
      case TodoStatus.incomplete:
        return Icons.radio_button_unchecked;
      case TodoStatus.completed:
        return Icons.check_circle;
      case TodoStatus.excellent:
        return Icons.stars;
      case TodoStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _statusColor(TodoStatus status) {
    switch (status) {
      case TodoStatus.incomplete:
        return Colors.grey.shade500;
      case TodoStatus.completed:
        return Colors.green.shade600;
      case TodoStatus.excellent:
        return Colors.amber.shade700;
      case TodoStatus.cancelled:
        return Colors.red.shade400;
    }
  }

  String _statusLabel(TodoStatus status, AppLocalizations loc) {
    switch (status) {
      case TodoStatus.incomplete:
        return loc.incomplete;
      case TodoStatus.completed:
        return loc.completed;
      case TodoStatus.excellent:
        return loc.excellent;
      case TodoStatus.cancelled:
        return loc.cancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isStrikethrough =
        todo.status == TodoStatus.completed ||
        todo.status == TodoStatus.excellent ||
        todo.status == TodoStatus.cancelled;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status icon button - large touch target
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(
                  _statusIcon(todo.status),
                  color: _statusColor(todo.status),
                  size: 26,
                ),
                onPressed: onTapStatus,
                tooltip: _statusLabel(todo.status, loc),
                padding: EdgeInsets.zero,
              ),
            ),
            // Content
            Expanded(
              child: Text(
                todo.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  decoration:
                      isStrikethrough ? TextDecoration.lineThrough : null,
                  color: isStrikethrough
                      ? theme.colorScheme.onSurface.withOpacity(0.5)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showTodoStatusMenu(
  BuildContext context,
  TodoItem todo,
  ValueChanged<TodoStatus> onStatusChanged,
  VoidCallback onEdit,
  VoidCallback onDelete,
) {
  final loc = AppLocalizations.of(context);
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              loc.statusMenu,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.radio_button_unchecked,
                color: Colors.grey),
            title: Text(loc.incomplete),
            selected: todo.status == TodoStatus.incomplete,
            onTap: () {
              Navigator.pop(ctx);
              onStatusChanged(TodoStatus.incomplete);
            },
          ),
          ListTile(
            leading: Icon(Icons.check_circle,
                color: Colors.green.shade600),
            title: Text(loc.completed),
            selected: todo.status == TodoStatus.completed,
            onTap: () {
              Navigator.pop(ctx);
              onStatusChanged(TodoStatus.completed);
            },
          ),
          ListTile(
            leading: Icon(Icons.stars,
                color: Colors.amber.shade700),
            title: Text(loc.excellent),
            selected: todo.status == TodoStatus.excellent,
            onTap: () {
              Navigator.pop(ctx);
              onStatusChanged(TodoStatus.excellent);
            },
          ),
          ListTile(
            leading: Icon(Icons.cancel,
                color: Colors.red.shade400),
            title: Text(loc.cancelled),
            selected: todo.status == TodoStatus.cancelled,
            onTap: () {
              Navigator.pop(ctx);
              onStatusChanged(TodoStatus.cancelled);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text(loc.editTodo),
            onTap: () {
              Navigator.pop(ctx);
              onEdit();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red.shade400),
            title: Text(loc.deleteTodo,
                style: TextStyle(color: Colors.red.shade400)),
            onTap: () {
              Navigator.pop(ctx);
              onDelete();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

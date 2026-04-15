import 'package:flutter_test/flutter_test.dart';

import 'package:diary_app/models/todo_item.dart';
import 'package:diary_app/models/diary_entry.dart';

void main() {
  group('TodoStatus', () {
    test('fromValue maps known values', () {
      expect(TodoStatus.fromValue(0), TodoStatus.incomplete);
      expect(TodoStatus.fromValue(1), TodoStatus.completed);
      expect(TodoStatus.fromValue(2), TodoStatus.excellent);
      expect(TodoStatus.fromValue(3), TodoStatus.cancelled);
    });

    test('fromValue defaults unknown to incomplete', () {
      expect(TodoStatus.fromValue(99), TodoStatus.incomplete);
    });

    test('next cycles through all states', () {
      expect(TodoStatus.incomplete.next(), TodoStatus.completed);
      expect(TodoStatus.completed.next(), TodoStatus.excellent);
      expect(TodoStatus.excellent.next(), TodoStatus.cancelled);
      expect(TodoStatus.cancelled.next(), TodoStatus.incomplete);
    });
  });

  group('TodoItem.fromMap', () {
    test('round-trips through toMap', () {
      final t = TodoItem(
        id: 7,
        entryId: 3,
        content: 'buy milk',
        status: TodoStatus.completed,
        sortOrder: 2,
        createdAt: DateTime.parse('2025-01-02T03:04:05.000'),
      );
      final roundTripped = TodoItem.fromMap(t.toMap());
      expect(roundTripped.id, 7);
      expect(roundTripped.entryId, 3);
      expect(roundTripped.content, 'buy milk');
      expect(roundTripped.status, TodoStatus.completed);
      expect(roundTripped.sortOrder, 2);
      expect(roundTripped.createdAt, t.createdAt);
    });
  });

  group('DiaryEntry.fromMap', () {
    test('parses required fields', () {
      final e = DiaryEntry.fromMap({
        'id': 1,
        'date': '2025-06-15',
        'text_content': 'hello',
        'created_at': '2025-06-15T10:00:00.000',
        'updated_at': '2025-06-15T11:00:00.000',
      });
      expect(e.id, 1);
      expect(e.date, '2025-06-15');
      expect(e.textContent, 'hello');
    });

    test('tolerates null text_content', () {
      final e = DiaryEntry.fromMap({
        'id': 1,
        'date': '2025-06-15',
        'text_content': null,
        'created_at': '2025-06-15T10:00:00.000',
        'updated_at': '2025-06-15T11:00:00.000',
      });
      expect(e.textContent, '');
    });
  });
}

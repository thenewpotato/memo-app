import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';
import '../models/todo_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('diary_app.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diary_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        text_content TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE todo_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entry_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (entry_id) REFERENCES diary_entries(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_diary_date ON diary_entries(date)');
    await db.execute(
        'CREATE INDEX idx_todo_entry ON todo_items(entry_id)');
  }

  // --- Diary Entry CRUD ---

  Future<DiaryEntry> getOrCreateEntry(String date) async {
    final db = await database;
    final results = await db.query(
      'diary_entries',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (results.isNotEmpty) {
      return DiaryEntry.fromMap(results.first);
    }
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('diary_entries', {
      'date': date,
      'text_content': '',
      'created_at': now,
      'updated_at': now,
    });
    return DiaryEntry(
      id: id,
      date: date,
      textContent: '',
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
    );
  }

  Future<DiaryEntry?> getEntry(String date) async {
    final db = await database;
    final results = await db.query(
      'diary_entries',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (results.isEmpty) return null;
    return DiaryEntry.fromMap(results.first);
  }

  Future<DiaryEntry?> getEntryById(int id) async {
    final db = await database;
    final results = await db.query(
      'diary_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return DiaryEntry.fromMap(results.first);
  }

  Future<void> updateEntryText(int entryId, String text) async {
    final db = await database;
    await db.update(
      'diary_entries',
      {
        'text_content': text,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<List<DiaryEntry>> getAllEntries() async {
    final db = await database;
    final results = await db.query(
      'diary_entries',
      orderBy: 'date DESC',
    );
    return results.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  Future<void> deleteEntry(int entryId) async {
    final db = await database;
    await db.delete('todo_items', where: 'entry_id = ?', whereArgs: [entryId]);
    await db.delete('diary_entries', where: 'id = ?', whereArgs: [entryId]);
  }

  // --- Todo CRUD ---

  Future<List<TodoItem>> getTodosForEntry(int entryId) async {
    final db = await database;
    final results = await db.query(
      'todo_items',
      where: 'entry_id = ?',
      whereArgs: [entryId],
      orderBy: 'sort_order ASC, id ASC',
    );
    return results.map((m) => TodoItem.fromMap(m)).toList();
  }

  Future<TodoItem> insertTodo(TodoItem todo) async {
    final db = await database;
    final id = await db.insert('todo_items', {
      'entry_id': todo.entryId,
      'content': todo.content,
      'status': todo.status.value,
      'sort_order': todo.sortOrder,
      'created_at': todo.createdAt.toIso8601String(),
    });
    // Update entry's updated_at
    await db.update(
      'diary_entries',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [todo.entryId],
    );
    return todo.copyWith(id: id);
  }

  Future<void> updateTodoStatus(int todoId, TodoStatus status) async {
    final db = await database;
    await db.update(
      'todo_items',
      {'status': status.value},
      where: 'id = ?',
      whereArgs: [todoId],
    );
  }

  Future<void> updateTodoContent(int todoId, String content) async {
    final db = await database;
    await db.update(
      'todo_items',
      {'content': content},
      where: 'id = ?',
      whereArgs: [todoId],
    );
  }

  Future<void> deleteTodo(int todoId) async {
    final db = await database;
    await db.delete('todo_items', where: 'id = ?', whereArgs: [todoId]);
  }

  // --- Dates with incomplete todos ---

  Future<Set<String>> getDatesWithIncompleteTodos() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT DISTINCT e.date FROM diary_entries e
      INNER JOIN todo_items t ON t.entry_id = e.id
      WHERE t.status = 0
    ''');
    return results.map((r) => r['date'] as String).toSet();
  }

  // --- Dates that have any content ---

  Future<Set<String>> getDatesWithEntries() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT date FROM diary_entries
      WHERE text_content != '' OR id IN (SELECT DISTINCT entry_id FROM todo_items)
    ''');
    return results.map((r) => r['date'] as String).toSet();
  }

  // --- Search ---

  Future<List<DiaryEntry>> searchEntries(String keyword) async {
    final db = await database;
    final kw = '%$keyword%';
    final results = await db.rawQuery('''
      SELECT DISTINCT e.* FROM diary_entries e
      LEFT JOIN todo_items t ON t.entry_id = e.id
      WHERE e.text_content LIKE ? OR t.content LIKE ?
      ORDER BY e.date DESC
    ''', [kw, kw]);
    return results.map((m) => DiaryEntry.fromMap(m)).toList();
  }

  // --- Filter incomplete todos by month/year ---

  Future<List<Map<String, dynamic>>> getIncompleteTodos({
    int? year,
    int? month,
  }) async {
    final db = await database;
    String dateFilter = '';
    List<dynamic> args = [];
    if (year != null && month != null) {
      final m = month.toString().padLeft(2, '0');
      dateFilter = "AND e.date LIKE ?";
      args.add('$year-$m%');
    } else if (year != null) {
      dateFilter = "AND e.date LIKE ?";
      args.add('$year%');
    }
    final results = await db.rawQuery('''
      SELECT t.*, e.date as entry_date FROM todo_items t
      INNER JOIN diary_entries e ON e.id = t.entry_id
      WHERE t.status = 0 $dateFilter
      ORDER BY e.date DESC, t.sort_order ASC
    ''', args);
    return results;
  }

  // --- Export / Import ---

  Future<String> exportToJson() async {
    final db = await database;
    final entries = await db.query('diary_entries', orderBy: 'date ASC');
    final List<Map<String, dynamic>> exportData = [];

    for (final entry in entries) {
      final todos = await db.query(
        'todo_items',
        where: 'entry_id = ?',
        whereArgs: [entry['id']],
        orderBy: 'sort_order ASC',
      );
      exportData.add({
        'date': entry['date'],
        'text_content': entry['text_content'],
        'created_at': entry['created_at'],
        'updated_at': entry['updated_at'],
        'todos': todos
            .map((t) => {
                  'content': t['content'],
                  'status': t['status'],
                  'sort_order': t['sort_order'],
                  'created_at': t['created_at'],
                })
            .toList(),
      });
    }

    return const JsonEncoder.withIndent('  ').convert({
      'app': 'diary_app',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'entries': exportData,
    });
  }

  Future<File> exportToFile() async {
    final json = await exportToJson();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(p.join(dir.path, 'diary_backup_$timestamp.json'));
    await file.writeAsString(json);
    return file;
  }

  Future<int> importFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (data['app'] != 'diary_app') {
      throw Exception('Invalid backup file');
    }
    final entries = data['entries'] as List<dynamic>;
    final db = await database;
    int count = 0;

    for (final entryData in entries) {
      final date = entryData['date'] as String;
      // Check if entry already exists
      final existing = await db.query(
        'diary_entries',
        where: 'date = ?',
        whereArgs: [date],
      );

      int entryId;
      if (existing.isNotEmpty) {
        entryId = existing.first['id'] as int;
        await db.update(
          'diary_entries',
          {
            'text_content': entryData['text_content'] ?? '',
            'updated_at': entryData['updated_at'] ??
                DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [entryId],
        );
        // Delete old todos for this entry
        await db.delete('todo_items',
            where: 'entry_id = ?', whereArgs: [entryId]);
      } else {
        entryId = await db.insert('diary_entries', {
          'date': date,
          'text_content': entryData['text_content'] ?? '',
          'created_at': entryData['created_at'] ??
              DateTime.now().toIso8601String(),
          'updated_at': entryData['updated_at'] ??
              DateTime.now().toIso8601String(),
        });
      }

      final todos = entryData['todos'] as List<dynamic>? ?? [];
      for (final todoData in todos) {
        await db.insert('todo_items', {
          'entry_id': entryId,
          'content': todoData['content'] ?? '',
          'status': todoData['status'] ?? 0,
          'sort_order': todoData['sort_order'] ?? 0,
          'created_at': todoData['created_at'] ??
              DateTime.now().toIso8601String(),
        });
      }
      count++;
    }
    return count;
  }

  Future<int> importFromFile(File file) async {
    final json = await file.readAsString();
    return importFromJson(json);
  }
}

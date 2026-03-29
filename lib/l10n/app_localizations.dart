import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appName': 'Memo',
      'calendar': 'Calendar',
      'taskList': 'Tasks',
      'today': 'Today',
      'search': 'Search',
      'searchHint': 'Search notes and todos...',
      'noResults': 'No results found',
      'addNote': 'Add note',
      'addTodo': 'Add todo',
      'notes': 'Notes',
      'todos': 'Todos',
      'tapToEdit': 'Tap to start writing...',
      'newTodoHint': 'New todo item...',
      'incomplete': 'Incomplete',
      'completed': 'Completed',
      'excellent': 'Excellent!',
      'cancelled': 'Cancelled',
      'delete': 'Delete',
      'edit': 'Edit',
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'export': 'Export Data',
      'import': 'Import Data',
      'exportSuccess': 'Data exported successfully!',
      'importSuccess': 'Imported {count} entries successfully!',
      'importError': 'Import failed: Invalid file format',
      'settings': 'Settings',
      'backup': 'Backup & Restore',
      'filterIncompleteTodos': 'Incomplete Todos',
      'filterByMonth': 'Filter by Month',
      'filterByYear': 'Filter by Year',
      'allTime': 'All Time',
      'noEntries': 'No diary entries yet.\nTap + to start today\'s entry!',
      'noTodos': 'No incomplete todos found',
      'deleteEntry': 'Delete Entry',
      'deleteEntryConfirm':
          'Are you sure you want to delete this entry and all its todos?',
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
      'months':
          'January,February,March,April,May,June,July,August,September,October,November,December',
      'exportShareTitle': 'Diary Backup',
      'chooseFile': 'Choose JSON file to import',
      'noEntriesForDate': 'No entry for this date',
      'statusMenu': 'Set Status',
      'editTodo': 'Edit Todo',
      'deleteTodo': 'Delete Todo',
      'todoDeleted': 'Todo deleted',
      'entryDeleted': 'Entry deleted',
      'undo': 'Undo',
      'year': 'Year',
      'month': 'Month',
    },
    'zh': {
      'appName': '记事薄',
      'calendar': '日历',
      'taskList': '任务',
      'today': '今天',
      'search': '搜索',
      'searchHint': '搜索笔记和待办事项...',
      'noResults': '未找到结果',
      'addNote': '添加笔记',
      'addTodo': '添加待办',
      'notes': '笔记',
      'todos': '待办事项',
      'tapToEdit': '点击开始记录...',
      'newTodoHint': '新的待办事项...',
      'incomplete': '未完成',
      'completed': '已完成',
      'excellent': '完成出色！',
      'cancelled': '已取消',
      'delete': '删除',
      'edit': '编辑',
      'save': '保存',
      'cancel': '取消',
      'confirm': '确认',
      'export': '导出数据',
      'import': '导入数据',
      'exportSuccess': '数据导出成功！',
      'importSuccess': '成功导入 {count} 条记录！',
      'importError': '导入失败：文件格式无效',
      'settings': '设置',
      'backup': '备份与恢复',
      'filterIncompleteTodos': '未完成待办',
      'filterByMonth': '按月筛选',
      'filterByYear': '按年筛选',
      'allTime': '全部时间',
      'noEntries': '还没有日记条目。\n点击 + 开始今天的记录！',
      'noTodos': '没有未完成的待办事项',
      'deleteEntry': '删除条目',
      'deleteEntryConfirm': '确定要删除这个条目及其所有待办事项吗？',
      'mon': '一',
      'tue': '二',
      'wed': '三',
      'thu': '四',
      'fri': '五',
      'sat': '六',
      'sun': '日',
      'months': '一月,二月,三月,四月,五月,六月,七月,八月,九月,十月,十一月,十二月',
      'exportShareTitle': '日记备份',
      'chooseFile': '选择要导入的JSON文件',
      'noEntriesForDate': '该日期暂无记录',
      'statusMenu': '设置状态',
      'editTodo': '编辑待办',
      'deleteTodo': '删除待办',
      'todoDeleted': '待办已删除',
      'entryDeleted': '条目已删除',
      'undo': '撤销',
      'year': '年',
      'month': '月',
    },
  };

  String get(String key) {
    final langCode = locale.languageCode;
    final map = _localizedValues[langCode] ?? _localizedValues['en']!;
    return map[key] ?? _localizedValues['en']![key] ?? key;
  }

  String getWithArgs(String key, Map<String, String> args) {
    var result = get(key);
    args.forEach((k, v) {
      result = result.replaceAll('{$k}', v);
    });
    return result;
  }

  List<String> get monthNames => get('months').split(',');

  String get appName => get('appName');
  String get calendar => get('calendar');
  String get taskList => get('taskList');
  String get today => get('today');
  String get search => get('search');
  String get searchHint => get('searchHint');
  String get noResults => get('noResults');
  String get addNote => get('addNote');
  String get addTodo => get('addTodo');
  String get notes => get('notes');
  String get todos => get('todos');
  String get tapToEdit => get('tapToEdit');
  String get newTodoHint => get('newTodoHint');
  String get incomplete => get('incomplete');
  String get completed => get('completed');
  String get excellent => get('excellent');
  String get cancelled => get('cancelled');
  String get delete => get('delete');
  String get edit => get('edit');
  String get save => get('save');
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get exportData => get('export');
  String get importData => get('import');
  String get exportSuccess => get('exportSuccess');
  String get importError => get('importError');
  String get settings => get('settings');
  String get backup => get('backup');
  String get filterIncompleteTodos => get('filterIncompleteTodos');
  String get filterByMonth => get('filterByMonth');
  String get filterByYear => get('filterByYear');
  String get allTime => get('allTime');
  String get noEntries => get('noEntries');
  String get noTodos => get('noTodos');
  String get deleteEntry => get('deleteEntry');
  String get deleteEntryConfirm => get('deleteEntryConfirm');
  String get exportShareTitle => get('exportShareTitle');
  String get chooseFile => get('chooseFile');
  String get noEntriesForDate => get('noEntriesForDate');
  String get statusMenu => get('statusMenu');
  String get editTodo => get('editTodo');
  String get deleteTodo => get('deleteTodo');
  String get todoDeleted => get('todoDeleted');
  String get entryDeleted => get('entryDeleted');
  String get undo => get('undo');
  String get year => get('year');
  String get month => get('month');

  String importSuccess(int count) =>
      getWithArgs('importSuccess', {'count': count.toString()});
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

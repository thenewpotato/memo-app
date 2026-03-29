/// Todo status: 0=incomplete, 1=completed, 2=completed+excellent, 3=cancelled
enum TodoStatus {
  incomplete(0),
  completed(1),
  excellent(2),
  cancelled(3);

  final int value;
  const TodoStatus(this.value);

  static TodoStatus fromValue(int v) {
    return TodoStatus.values.firstWhere((e) => e.value == v,
        orElse: () => TodoStatus.incomplete);
  }

  TodoStatus next() {
    switch (this) {
      case TodoStatus.incomplete:
        return TodoStatus.completed;
      case TodoStatus.completed:
        return TodoStatus.excellent;
      case TodoStatus.excellent:
        return TodoStatus.cancelled;
      case TodoStatus.cancelled:
        return TodoStatus.incomplete;
    }
  }
}

class TodoItem {
  final int? id;
  final int entryId;
  final String content;
  final TodoStatus status;
  final int sortOrder;
  final DateTime createdAt;

  TodoItem({
    this.id,
    required this.entryId,
    required this.content,
    this.status = TodoStatus.incomplete,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TodoItem copyWith({
    int? id,
    int? entryId,
    String? content,
    TodoStatus? status,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      content: content ?? this.content,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_id': entryId,
      'content': content,
      'status': status.value,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as int?,
      entryId: map['entry_id'] as int,
      content: map['content'] as String,
      status: TodoStatus.fromValue(map['status'] as int),
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'content': content,
        'status': status.value,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  factory TodoItem.fromJson(Map<String, dynamic> json, int entryId) {
    return TodoItem(
      entryId: entryId,
      content: json['content'] as String,
      status: TodoStatus.fromValue(json['status'] as int),
      sortOrder: (json['sort_order'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isIncomplete =>
      status == TodoStatus.incomplete;
}

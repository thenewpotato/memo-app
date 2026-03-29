class DiaryEntry {
  final int? id;
  final String date; // yyyy-MM-dd
  final String textContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry({
    this.id,
    required this.date,
    this.textContent = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DiaryEntry copyWith({
    int? id,
    String? date,
    String? textContent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      textContent: textContent ?? this.textContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'text_content': textContent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as int?,
      date: map['date'] as String,
      textContent: (map['text_content'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'text_content': textContent,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      date: json['date'] as String,
      textContent: (json['text_content'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class Dedication {
  final int? id;
  final String title;
  final String content;
  final int? chantingId; // 关联的佛号或经文ID
  final DateTime createdAt;
  final DateTime? updatedAt;

  Dedication({
    this.id,
    required this.title,
    required this.content,
    this.chantingId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'chanting_id': chantingId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Dedication.fromMap(Map<String, dynamic> map) {
    return Dedication(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      chantingId: map['chanting_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Dedication copyWith({
    int? id,
    String? title,
    String? content,
    int? chantingId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dedication(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      chantingId: chantingId ?? this.chantingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
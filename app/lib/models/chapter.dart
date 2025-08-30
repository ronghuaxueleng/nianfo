class Chapter {
  final int? id;
  final int chantingId;
  final int chapterNumber;
  final String title;
  final String content;
  final String? pronunciation; // 注音（可选）
  final bool isDeleted; // 逻辑删除标记
  final DateTime createdAt;
  final DateTime? updatedAt;

  Chapter({
    this.id,
    required this.chantingId,
    required this.chapterNumber,
    required this.title,
    required this.content,
    this.pronunciation,
    this.isDeleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chanting_id': chantingId,
      'chapter_number': chapterNumber,
      'title': title,
      'content': content,
      'pronunciation': pronunciation,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'],
      chantingId: map['chanting_id'],
      chapterNumber: map['chapter_number'],
      title: map['title'],
      content: map['content'],
      pronunciation: map['pronunciation'],
      isDeleted: (map['is_deleted'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  factory Chapter.fromApi(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      chantingId: json['chanting_id'],
      chapterNumber: json['chapter_number'],
      title: json['title'],
      content: json['content'],
      pronunciation: json['pronunciation'],
      isDeleted: json['is_deleted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toApi() {
    return {
      'chapter_number': chapterNumber,
      'title': title,
      'content': content,
      'pronunciation': pronunciation,
    };
  }

  Chapter copyWith({
    int? id,
    int? chantingId,
    int? chapterNumber,
    String? title,
    String? content,
    String? pronunciation,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chapter(
      id: id ?? this.id,
      chantingId: chantingId ?? this.chantingId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      content: content ?? this.content,
      pronunciation: pronunciation ?? this.pronunciation,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Chapter{id: $id, chantingId: $chantingId, chapterNumber: $chapterNumber, title: $title}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          chantingId == other.chantingId &&
          chapterNumber == other.chapterNumber;

  @override
  int get hashCode => id.hashCode ^ chantingId.hashCode ^ chapterNumber.hashCode;
}
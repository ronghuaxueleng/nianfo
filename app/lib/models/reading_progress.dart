class ReadingProgress {
  final int? id;
  final int userId;
  final int chantingId;
  final int? chapterId; // 空表示整部经文的进度
  final bool isCompleted;
  final DateTime lastReadAt;
  final int readingPosition; // 阅读位置（如字符位置）
  final String? notes; // 阅读笔记
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReadingProgress({
    this.id,
    required this.userId,
    required this.chantingId,
    this.chapterId,
    this.isCompleted = false,
    required this.lastReadAt,
    this.readingPosition = 0,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'chanting_id': chantingId,
      'chapter_id': chapterId,
      'is_completed': isCompleted ? 1 : 0,
      'last_read_at': lastReadAt.toIso8601String(),
      'reading_position': readingPosition,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ReadingProgress.fromMap(Map<String, dynamic> map) {
    return ReadingProgress(
      id: map['id'],
      userId: map['user_id'],
      chantingId: map['chanting_id'],
      chapterId: map['chapter_id'],
      isCompleted: (map['is_completed'] ?? 0) == 1,
      lastReadAt: DateTime.parse(map['last_read_at']),
      readingPosition: map['reading_position'] ?? 0,
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  factory ReadingProgress.fromApi(Map<String, dynamic> json) {
    return ReadingProgress(
      id: json['id'],
      userId: json['user_id'],
      chantingId: json['chanting_id'],
      chapterId: json['chapter_id'],
      isCompleted: json['is_completed'] ?? false,
      lastReadAt: DateTime.parse(json['last_read_at']),
      readingPosition: json['reading_position'] ?? 0,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toApi() {
    return {
      'chanting_id': chantingId,
      'chapter_id': chapterId,
      'is_completed': isCompleted,
      'reading_position': readingPosition,
      'notes': notes,
    };
  }

  ReadingProgress copyWith({
    int? id,
    int? userId,
    int? chantingId,
    int? chapterId,
    bool? isCompleted,
    DateTime? lastReadAt,
    int? readingPosition,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      chantingId: chantingId ?? this.chantingId,
      chapterId: chapterId ?? this.chapterId,
      isCompleted: isCompleted ?? this.isCompleted,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      readingPosition: readingPosition ?? this.readingPosition,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ReadingProgress{id: $id, userId: $userId, chantingId: $chantingId, chapterId: $chapterId, isCompleted: $isCompleted}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingProgress &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          chantingId == other.chantingId &&
          chapterId == other.chapterId;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ chantingId.hashCode ^ chapterId.hashCode;
}

// 阅读进度摘要类
class ReadingProgressSummary {
  final int chantingId;
  final String chantingTitle;
  final int totalChapters;
  final int completedChapters;
  final double progressPercentage;

  ReadingProgressSummary({
    required this.chantingId,
    required this.chantingTitle,
    required this.totalChapters,
    required this.completedChapters,
    required this.progressPercentage,
  });

  factory ReadingProgressSummary.fromApi(Map<String, dynamic> json) {
    return ReadingProgressSummary(
      chantingId: json['chanting_id'],
      chantingTitle: json['chanting_title'],
      totalChapters: json['total_chapters'],
      completedChapters: json['completed_chapters'],
      progressPercentage: (json['progress_percentage'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() {
    return 'ReadingProgressSummary{chantingId: $chantingId, title: $chantingTitle, progress: $completedChapters/$totalChapters ($progressPercentage%)}';
  }
}
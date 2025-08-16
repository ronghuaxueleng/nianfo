class DailyStats {
  final int? id;
  final int chantingId; // 关联的佛号或经文ID
  final int count; // 今日念诵次数
  final DateTime date; // 统计日期（只记录日期，不包含时间）
  final DateTime createdAt;
  final DateTime? updatedAt;

  DailyStats({
    this.id,
    required this.chantingId,
    required this.count,
    required this.date,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chanting_id': chantingId,
      'count': count,
      'date': _dateOnly(date).toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory DailyStats.fromMap(Map<String, dynamic> map) {
    return DailyStats(
      id: map['id'],
      chantingId: map['chanting_id'],
      count: map['count'],
      date: DateTime.parse(map['date']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  DailyStats copyWith({
    int? id,
    int? chantingId,
    int? count,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyStats(
      id: id ?? this.id,
      chantingId: chantingId ?? this.chantingId,
      count: count ?? this.count,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // 工具方法：获取不包含时间的日期
  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 获取今日日期（不包含时间）
  static DateTime get today => _dateOnly(DateTime.now());

  // 检查是否为今日统计
  bool get isToday => _dateOnly(date) == today;
}
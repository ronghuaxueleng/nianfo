import 'chanting.dart';

class ChantingRecord {
  final int? id;
  final int chantingId; // 关联的佛号经文ID
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChantingRecord({
    this.id,
    required this.chantingId,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chanting_id': chantingId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ChantingRecord.fromMap(Map<String, dynamic> map) {
    return ChantingRecord(
      id: map['id'],
      chantingId: map['chanting_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  ChantingRecord copyWith({
    int? id,
    int? chantingId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChantingRecord(
      id: id ?? this.id,
      chantingId: chantingId ?? this.chantingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 包含完整佛号经文信息的念诵记录
class ChantingRecordWithDetails {
  final ChantingRecord record;
  final Chanting chanting;

  ChantingRecordWithDetails({
    required this.record,
    required this.chanting,
  });

  factory ChantingRecordWithDetails.fromMap(Map<String, dynamic> map) {
    return ChantingRecordWithDetails(
      record: ChantingRecord(
        id: map['id'],
        chantingId: map['chanting_id'],
        createdAt: DateTime.parse(map['created_at']),
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      ),
      chanting: Chanting(
        id: map['chanting_id'],
        title: map['title'],
        content: map['content'],
        pronunciation: map['pronunciation'],
        type: ChantingType.values.firstWhere(
          (e) => e.toString().split('.').last == map['type'],
        ),
        isBuiltIn: (map['is_built_in'] ?? 0) == 1,
        createdAt: DateTime.parse(map['chanting_created_at']),
      ),
    );
  }
}
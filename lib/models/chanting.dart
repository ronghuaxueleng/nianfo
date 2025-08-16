class Chanting {
  final int? id;
  final String title;
  final String content;
  final ChantingType type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Chanting({
    this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Chanting.fromMap(Map<String, dynamic> map) {
    return Chanting(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      type: ChantingType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }
}

enum ChantingType {
  buddhaNam, // 佛号
  sutra,     // 经文
}
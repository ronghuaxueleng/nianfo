class DedicationTemplate {
  final int? id;
  final String title;
  final String content;
  final bool isBuiltIn; // 是否为内置模板
  final DateTime createdAt;
  final DateTime? updatedAt;

  DedicationTemplate({
    this.id,
    required this.title,
    required this.content,
    this.isBuiltIn = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_built_in': isBuiltIn ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory DedicationTemplate.fromMap(Map<String, dynamic> map) {
    return DedicationTemplate(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      isBuiltIn: map['is_built_in'] == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  DedicationTemplate copyWith({
    int? id,
    String? title,
    String? content,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DedicationTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// 内置回向文模板数据
class BuiltInTemplates {
  static List<DedicationTemplate> get defaultTemplates => [
    DedicationTemplate(
      title: "通用回向文",
      content: "愿以此功德，庄严佛净土。上报四重恩，下济三途苦。若有见闻者，悉发菩提心。尽此一报身，同生极乐国。",
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
    DedicationTemplate(
      title: "往生回向文",
      content: "愿生西方净土中，九品莲花为父母。花开见佛悟无生，不退菩萨为伴侣。",
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
    DedicationTemplate(
      title: "消业回向文",
      content: "愿消三障诸烦恼，愿得智慧真明了。普愿罪障悉消除，世世常行菩萨道。",
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
    DedicationTemplate(
      title: "众生回向文",
      content: "愿以此功德，普及于一切。我等与众生，皆共成佛道。",
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
    DedicationTemplate(
      title: "家庭回向文", 
      content: "愿以此功德，回向给我的家人朋友，愿他们身体健康，平安吉祥，福慧增长，早日得闻佛法，发菩提心，同证菩提。",
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
    DedicationTemplate(
      title: "法界回向文",
      content: "愿以此功德，回向法界一切众生，愿众生离苦得乐，究竟解脱。愿正法久住，佛光普照，法轮常转。",
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
  ];
}
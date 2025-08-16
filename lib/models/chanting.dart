class Chanting {
  final int? id;
  final String title;
  final String content;
  final String? pronunciation; // 注音（可选）
  final ChantingType type;
  final bool isBuiltIn; // 是否为内置经文
  final DateTime createdAt;
  final DateTime? updatedAt;

  Chanting({
    this.id,
    required this.title,
    required this.content,
    this.pronunciation,
    required this.type,
    this.isBuiltIn = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'pronunciation': pronunciation,
      'type': type.toString().split('.').last,
      'is_built_in': isBuiltIn ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Chanting.fromMap(Map<String, dynamic> map) {
    return Chanting(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      pronunciation: map['pronunciation'],
      type: ChantingType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
      ),
      isBuiltIn: (map['is_built_in'] ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Chanting copyWith({
    int? id,
    String? title,
    String? content,
    String? pronunciation,
    ChantingType? type,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chanting(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      pronunciation: pronunciation ?? this.pronunciation,
      type: type ?? this.type,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ChantingType {
  buddhaNam, // 佛号
  sutra,     // 经文
}

// 内置经文和佛号
class BuiltInChantings {
  static List<Chanting> get defaultChantings => [
    // 地藏经（节选）
    Chanting(
      title: '地藏菩萨本愿经（节选）',
      content: '''南无本师释迦牟尼佛！
南无大愿地藏王菩萨！

尔时世尊举身放大光明，遍照百千万亿恒河沙等诸佛世界。出大音声，普告诸佛世界一切诸菩萨摩诃萨，及天龙八部、人非人等：听吾今日称扬赞叹地藏菩萨摩诃萨，于十方世界，现大不可思议威神慈悲之力，救护一切罪苦众生。

地藏！地藏！汝之神力不可思议，汝之慈悲不可思议，汝之智慧不可思议，汝之辩才不可思议！正使十方诸佛，赞叹宣说汝之不思议事，千万劫中，不能得尽。''',
      pronunciation: '''nán wú běn shī shì jiā móu ní fó ！
nán wú dà yuàn dì zàng wáng pú sà ！

ěr shí shì zūn jǔ shēn fàng dà guāng míng ， biàn zhào bǎi qiān wàn yì héng hé shā děng zhū fó shì jiè 。 chū dà yīn shēng ， pǔ gào zhū fó shì jiè yī qiè zhū pú sà mó hē sà ， jí tiān lóng bā bù 、 rén fēi rén děng ： tīng wú jīn rì chēng yáng zàn tàn dì zàng pú sà mó hē sà ， yú shí fāng shì jiè ， xiàn dà bù kě sī yì wēi shén cí bēi zhī lì ， jiù hù yī qiè zuì kǔ zhòng shēng 。

dì zàng ！ dì zàng ！ rǔ zhī shén lì bù kě sī yì ， rǔ zhī cí bēi bù kě sī yì ， rǔ zhī zhì huì bù kě sī yì ， rǔ zhī biàn cái bù kě sī yì ！ zhèng shǐ shí fāng zhū fó ， zàn tàn xuān shuō rǔ zhī bù sī yì shì ， qiān wàn jié zhōng ， bù néng dé jìn 。''',
      type: ChantingType.sutra,
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
    
    // 文殊菩萨心咒
    Chanting(
      title: '文殊菩萨心咒',
      content: '''嗡啊喇巴札那谛''',
      pronunciation: '''ōng ā rā bā zhā nà dì''',
      type: ChantingType.sutra,
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
    
    // 常见佛号
    Chanting(
      title: '南无阿弥陀佛',
      content: '''南无阿弥陀佛''',
      pronunciation: '''nán wú ā mí tuó fó''',
      type: ChantingType.buddhaNam,
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
    
    Chanting(
      title: '南无观世音菩萨',
      content: '''南无观世音菩萨''',
      pronunciation: '''nán wú guān shì yīn pú sà''',
      type: ChantingType.buddhaNam,
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
    
    Chanting(
      title: '南无地藏王菩萨',
      content: '''南无地藏王菩萨''',
      pronunciation: '''nán wú dì zàng wáng pú sà''',
      type: ChantingType.buddhaNam,
      isBuiltIn: true,
      createdAt: DateTime.now(),
    ),
  ];
}
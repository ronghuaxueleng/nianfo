import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/dedication.dart';
import '../models/chanting.dart';
import '../models/chanting_record.dart';
import '../models/dedication_template.dart';
import '../models/daily_stats.dart';
import '../models/chapter.dart';
import '../models/reading_progress.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nianfo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 10,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        avatar TEXT,
        avatar_type TEXT DEFAULT 'emoji',
        nickname TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE dedications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        chanting_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (chanting_id) REFERENCES chantings (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE chantings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        pronunciation TEXT,
        type TEXT NOT NULL,
        is_built_in INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE dedication_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        is_built_in INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chanting_id INTEGER NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        UNIQUE(chanting_id, date),
        FOREIGN KEY (chanting_id) REFERENCES chantings (id)
      )
    ''');

    // 创建修行记录表
    await db.execute('''
      CREATE TABLE chanting_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chanting_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (chanting_id) REFERENCES chantings (id) ON DELETE CASCADE
      )
    ''');

    // 创建章节表
    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chanting_id INTEGER NOT NULL,
        chapter_number INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        pronunciation TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (chanting_id) REFERENCES chantings (id) ON DELETE CASCADE
      )
    ''');

    // 创建阅读进度表
    await db.execute('''
      CREATE TABLE reading_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        chanting_id INTEGER NOT NULL,
        chapter_id INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        last_read_at TEXT NOT NULL,
        reading_position INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        UNIQUE(user_id, chanting_id, chapter_id),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (chanting_id) REFERENCES chantings (id) ON DELETE CASCADE,
        FOREIGN KEY (chapter_id) REFERENCES chapters (id) ON DELETE CASCADE
      )
    ''');

    // 初始化内置模板和内置经文
    await _initializeBuiltInTemplates(db);
    await _initializeBuiltInChantings(db);
    await _initializeBuiltInChapters(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 添加模板表
      await db.execute('''
        CREATE TABLE dedication_templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          is_built_in INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');

      // 初始化内置模板
      await _initializeBuiltInTemplates(db);
    }
    
    if (oldVersion < 3) {
      // 添加用户头像字段
      await db.execute('''
        ALTER TABLE users ADD COLUMN avatar TEXT
      ''');
    }
    
    if (oldVersion < 4) {
      // 添加头像类型字段
      await db.execute('''
        ALTER TABLE users ADD COLUMN avatar_type TEXT DEFAULT 'emoji'
      ''');
    }
    
    if (oldVersion < 5) {
      // 添加回向文关联字段
      await db.execute('''
        ALTER TABLE dedications ADD COLUMN chanting_id INTEGER
      ''');
      
      // 添加佛号经文新字段
      await db.execute('''
        ALTER TABLE chantings ADD COLUMN pronunciation TEXT
      ''');
      
      await db.execute('''
        ALTER TABLE chantings ADD COLUMN is_built_in INTEGER NOT NULL DEFAULT 0
      ''');
      
      // 创建每日统计表
      await db.execute('''
        CREATE TABLE daily_stats (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chanting_id INTEGER NOT NULL,
          count INTEGER NOT NULL DEFAULT 0,
          date TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          UNIQUE(chanting_id, date),
          FOREIGN KEY (chanting_id) REFERENCES chantings (id)
        )
      ''');
      
      // 初始化内置经文
      await _initializeBuiltInChantings(db);
    }
    
    if (oldVersion < 6) {
      // 添加逻辑删除字段
      await db.execute('''
        ALTER TABLE chantings ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0
      ''');
    }
    
    if (oldVersion < 7) {
      // 创建修行记录表
      await db.execute('''
        CREATE TABLE chanting_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chanting_id INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (chanting_id) REFERENCES chantings (id) ON DELETE CASCADE
        )
      ''');
    }
    
    if (oldVersion < 8) {
      // 添加昵称字段
      await db.execute('''
        ALTER TABLE users ADD COLUMN nickname TEXT
      ''');
    }
    
    if (oldVersion < 9) {
      // 创建章节表
      await db.execute('''
        CREATE TABLE chapters (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          chanting_id INTEGER NOT NULL,
          chapter_number INTEGER NOT NULL,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          pronunciation TEXT,
          is_deleted INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (chanting_id) REFERENCES chantings (id) ON DELETE CASCADE
        )
      ''');
    }
    
    if (oldVersion < 10) {
      // 创建阅读进度表
      await db.execute('''
        CREATE TABLE reading_progress (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          chanting_id INTEGER NOT NULL,
          chapter_id INTEGER,
          is_completed INTEGER NOT NULL DEFAULT 0,
          last_read_at TEXT NOT NULL,
          reading_position INTEGER NOT NULL DEFAULT 0,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          UNIQUE(user_id, chanting_id, chapter_id),
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (chanting_id) REFERENCES chantings (id) ON DELETE CASCADE,
          FOREIGN KEY (chapter_id) REFERENCES chapters (id) ON DELETE CASCADE
        )
      ''');
      
      // 初始化内置章节
      await _initializeBuiltInChapters(db);
    }
  }

  Future<void> _initializeBuiltInTemplates(Database db) async {
    final templates = BuiltInTemplates.defaultTemplates;
    for (final template in templates) {
      await db.insert('dedication_templates', template.toMap());
    }
  }

  Future<void> _initializeBuiltInChantings(Database db) async {
    final chantings = BuiltInChantings.defaultChantings;
    for (final chanting in chantings) {
      await db.insert('chantings', chanting.toMap());
    }
  }

  Future<void> _initializeBuiltInChapters(Database db) async {
    // 获取地藏经的ID
    final chantingResult = await db.query(
      'chantings',
      where: 'title = ? AND is_built_in = 1',
      whereArgs: ['地藏菩萨本愿经（节选）'],
    );
    
    if (chantingResult.isNotEmpty) {
      final chantingId = chantingResult.first['id'] as int;
      
      final chapters = [
        Chapter(
          chantingId: chantingId,
          chapterNumber: 1,
          title: '序分',
          content: '''南无本师释迦牟尼佛！
南无大愿地藏王菩萨！

尔时世尊举身放大光明，遍照百千万亿恒河沙等诸佛世界。出大音声，普告诸佛世界一切诸菩萨摩诃萨，及天龙八部、人非人等：听吾今日称扬赞叹地藏菩萨摩诃萨，于十方世界，现大不可思议威神慈悲之力，救护一切罪苦众生。''',
          pronunciation: '''nán wú běn shī shì jiā móu ní fó ！
nán wú dà yuàn dì zàng wáng pú sà ！

ěr shí shì zūn jǔ shēn fàng dà guāng míng ， biàn zhào bǎi qiān wàn yì héng hé shā děng zhū fó shì jiè 。 chū dà yīn shēng ， pǔ gào zhū fó shì jiè yī qiè zhū pú sà mó hē sà ， jí tiān lóng bā bù 、 rén fēi rén děng ： tīng wú jīn rì chēng yáng zàn tàn dì zàng pú sà mó hē sà ， yú shí fāng shì jiè ， xiàn dà bù kě sī yì wēi shén cí bēi zhī lì ， jiù hù yī qiè zuì kǔ zhòng shēng 。''',
          createdAt: DateTime.now(),
        ),
        Chapter(
          chantingId: chantingId,
          chapterNumber: 2,
          title: '赞叹地藏菩萨',
          content: '''地藏！地藏！汝之神力不可思议，汝之慈悲不可思议，汝之智慧不可思议，汝之辩才不可思议！正使十方诸佛，赞叹宣说汝之不思议事，千万劫中，不能得尽。''',
          pronunciation: '''dì zàng ！ dì zàng ！ rǔ zhī shén lì bù kě sī yì ， rǔ zhī cí bēi bù kě sī yì ， rǔ zhī zhì huì bù kě sī yì ， rǔ zhī biàn cái bù kě sī yì ！ zhèng shǐ shí fāng zhū fó ， zàn tàn xuān shuō rǔ zhī bù sī yì shì ， qiān wàn jié zhōng ， bù néng dé jìn 。''',
          createdAt: DateTime.now(),
        ),
      ];
      
      for (final chapter in chapters) {
        await db.insert('chapters', chapter.toMap());
      }
    }
  }

  // User operations
  Future<User> createUser(User user) async {
    final db = await instance.database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<User?> getUser(String username, String password) async {
    try {
      final db = await instance.database;
      final maps = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('获取用户失败: $e');
      rethrow;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    try {
      final db = await instance.database;
      final maps = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (maps.isNotEmpty) {
        return User.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('根据用户名获取用户失败: $e');
      rethrow;
    }
  }

  Future<void> updateUser(User user) async {
    final db = await instance.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Dedication operations
  Future<Dedication> createDedication(Dedication dedication) async {
    final db = await instance.database;
    final id = await db.insert('dedications', dedication.toMap());
    return dedication.copyWith(id: id);
  }

  Future<List<Dedication>> getAllDedications() async {
    final db = await instance.database;
    final maps = await db.query('dedications', orderBy: 'created_at DESC');
    return maps.map((map) => Dedication.fromMap(map)).toList();
  }

  Future<void> updateDedication(Dedication dedication) async {
    final db = await instance.database;
    await db.update(
      'dedications',
      dedication.toMap(),
      where: 'id = ?',
      whereArgs: [dedication.id],
    );
  }

  Future<void> deleteDedication(int id) async {
    final db = await instance.database;
    await db.delete('dedications', where: 'id = ?', whereArgs: [id]);
  }

  // Dedication Template operations
  Future<DedicationTemplate> createDedicationTemplate(DedicationTemplate template) async {
    final db = await instance.database;
    final id = await db.insert('dedication_templates', template.toMap());
    return template.copyWith(id: id);
  }

  Future<List<DedicationTemplate>> getAllDedicationTemplates() async {
    final db = await instance.database;
    final maps = await db.query('dedication_templates', orderBy: 'is_built_in DESC, created_at DESC');
    return maps.map((map) => DedicationTemplate.fromMap(map)).toList();
  }

  Future<List<DedicationTemplate>> getBuiltInTemplates() async {
    final db = await instance.database;
    final maps = await db.query(
      'dedication_templates',
      where: 'is_built_in = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => DedicationTemplate.fromMap(map)).toList();
  }

  Future<List<DedicationTemplate>> getUserTemplates() async {
    final db = await instance.database;
    final maps = await db.query(
      'dedication_templates',
      where: 'is_built_in = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => DedicationTemplate.fromMap(map)).toList();
  }

  Future<void> updateDedicationTemplate(DedicationTemplate template) async {
    final db = await instance.database;
    // 只允许更新非内置的回向模板
    await db.update(
      'dedication_templates',
      template.toMap(),
      where: 'id = ? AND is_built_in = 0',
      whereArgs: [template.id],
    );
  }

  Future<void> deleteDedicationTemplate(int id) async {
    final db = await instance.database;
    await db.delete('dedication_templates', where: 'id = ? AND is_built_in = 0', whereArgs: [id]);
  }

  // Chanting operations
  Future<Chanting> createChanting(Chanting chanting) async {
    final db = await instance.database;
    final id = await db.insert('chantings', chanting.toMap());
    return chanting.copyWith(id: id);
  }

  Future<List<Chanting>> getAllChantings() async {
    final db = await instance.database;
    final maps = await db.query(
      'chantings', 
      where: 'is_deleted = 0',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Chanting.fromMap(map)).toList();
  }

  Future<List<Chanting>> getChantingsByType(ChantingType type) async {
    final db = await instance.database;
    final maps = await db.query(
      'chantings',
      where: 'type = ? AND is_deleted = 0',
      whereArgs: [type.toString().split('.').last],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Chanting.fromMap(map)).toList();
  }

  Future<void> updateChanting(Chanting chanting) async {
    final db = await instance.database;
    // 只允许更新非内置的佛号经文
    await db.update(
      'chantings',
      chanting.toMap(),
      where: 'id = ? AND is_built_in = 0',
      whereArgs: [chanting.id],
    );
  }

  Future<void> deleteChanting(int id) async {
    final db = await instance.database;
    // 只允许删除非内置的佛号经文
    await db.delete('chantings', where: 'id = ? AND is_built_in = 0', whereArgs: [id]);
  }

  // 逻辑删除经文（用于内置经文）
  Future<void> logicalDeleteChanting(int id) async {
    final db = await instance.database;
    await db.update(
      'chantings',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ? AND is_built_in = 1',
      whereArgs: [id],
    );
  }

  // 重置内置经文
  Future<void> resetBuiltInChantings() async {
    final db = await instance.database;
    
    // 删除所有内置经文（包括逻辑删除的）
    await db.delete('chantings', where: 'is_built_in = 1');
    
    // 重新初始化内置经文
    await _initializeBuiltInChantings(db);
  }

  // 获取已删除的内置经文数量
  Future<int> getDeletedBuiltInChantingsCount() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM chantings WHERE is_built_in = 1 AND is_deleted = 1'
    );
    return result.first['count'] as int;
  }

  // ChantingRecord operations
  Future<ChantingRecord> createChantingRecord(int chantingId) async {
    final db = await instance.database;
    final record = ChantingRecord(
      chantingId: chantingId,
      createdAt: DateTime.now(),
    );
    final id = await db.insert('chanting_records', record.toMap());
    return record.copyWith(id: id);
  }

  Future<List<ChantingRecordWithDetails>> getChantingRecordsWithDetails() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT cr.*, c.title, c.content, c.pronunciation, c.type, c.is_built_in, c.created_at as chanting_created_at
      FROM chanting_records cr
      INNER JOIN chantings c ON cr.chanting_id = c.id
      WHERE c.is_deleted = 0
      ORDER BY cr.created_at DESC
    ''');
    return result.map((map) => ChantingRecordWithDetails.fromMap(map)).toList();
  }

  Future<List<ChantingRecordWithDetails>> getChantingRecordsByType(ChantingType type) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT cr.*, c.title, c.content, c.pronunciation, c.type, c.is_built_in, c.created_at as chanting_created_at
      FROM chanting_records cr
      INNER JOIN chantings c ON cr.chanting_id = c.id
      WHERE c.type = ? AND c.is_deleted = 0
      ORDER BY cr.created_at DESC
    ''', [type.toString().split('.').last]);
    return result.map((map) => ChantingRecordWithDetails.fromMap(map)).toList();
  }

  Future<void> deleteChantingRecord(int recordId) async {
    final db = await instance.database;
    
    // 首先获取记录信息，获取对应的chanting_id
    final recordQuery = await db.query(
      'chanting_records',
      where: 'id = ?',
      whereArgs: [recordId],
    );
    
    if (recordQuery.isNotEmpty) {
      final chantingId = recordQuery.first['chanting_id'] as int;
      
      // 删除修行记录
      await db.delete('chanting_records', where: 'id = ?', whereArgs: [recordId]);
      
      // 删除对应的每日统计数据
      await db.delete('daily_stats', where: 'chanting_id = ?', whereArgs: [chantingId]);
    }
  }

  // Daily Stats operations
  Future<DailyStats> createOrUpdateDailyStats(int chantingId, int count) async {
    final db = await instance.database;
    final today = DailyStats.today.toIso8601String();
    
    // 检查今日是否已有记录
    final existing = await db.query(
      'daily_stats',
      where: 'chanting_id = ? AND date = ?',
      whereArgs: [chantingId, today],
    );
    
    if (existing.isNotEmpty) {
      // 更新现有记录
      final existingStats = DailyStats.fromMap(existing.first);
      final updatedStats = existingStats.copyWith(
        count: count,
        updatedAt: DateTime.now(),
      );
      
      await db.update(
        'daily_stats',
        updatedStats.toMap(),
        where: 'id = ?',
        whereArgs: [updatedStats.id],
      );
      
      return updatedStats;
    } else {
      // 创建新记录
      final newStats = DailyStats(
        chantingId: chantingId,
        count: count,
        date: DailyStats.today,
        createdAt: DateTime.now(),
      );
      
      final id = await db.insert('daily_stats', newStats.toMap());
      return newStats.copyWith(id: id);
    }
  }

  Future<int> getTodayCount(int chantingId) async {
    final db = await instance.database;
    final today = DailyStats.today.toIso8601String();
    
    final result = await db.query(
      'daily_stats',
      where: 'chanting_id = ? AND date = ?',
      whereArgs: [chantingId, today],
    );
    
    if (result.isNotEmpty) {
      return DailyStats.fromMap(result.first).count;
    }
    return 0;
  }

  Future<List<DailyStats>> getDailyStatsByChanting(int chantingId, {int? limit}) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_stats',
      where: 'chanting_id = ?',
      whereArgs: [chantingId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((map) => DailyStats.fromMap(map)).toList();
  }

  Future<List<DailyStats>> getAllTodayStats() async {
    final db = await instance.database;
    final today = DailyStats.today.toIso8601String();
    
    final maps = await db.query(
      'daily_stats',
      where: 'date = ?',
      whereArgs: [today],
      orderBy: 'count DESC',
    );
    return maps.map((map) => DailyStats.fromMap(map)).toList();
  }

  Future<int> getTotalCountByType(ChantingType type) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT SUM(ds.count) as total_count
      FROM daily_stats ds
      INNER JOIN chantings c ON ds.chanting_id = c.id
      WHERE c.type = ?
    ''', [type.toString().split('.').last]);
    
    return (result.first['total_count'] as int?) ?? 0;
  }

  // 获取特定修行记录的统计数据
  Future<List<DailyStats>> getChantingStatistics(int chantingId) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_stats',
      where: 'chanting_id = ?',
      whereArgs: [chantingId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => DailyStats.fromMap(map)).toList();
  }

  // Chapter operations
  Future<Chapter> createChapter(Chapter chapter) async {
    final db = await instance.database;
    final id = await db.insert('chapters', chapter.toMap());
    return chapter.copyWith(id: id);
  }

  Future<List<Chapter>> getChaptersByChantingId(int chantingId) async {
    final db = await instance.database;
    final maps = await db.query(
      'chapters',
      where: 'chanting_id = ? AND is_deleted = 0',
      whereArgs: [chantingId],
      orderBy: 'chapter_number ASC',
    );
    return maps.map((map) => Chapter.fromMap(map)).toList();
  }

  Future<Chapter?> getChapter(int chapterId) async {
    final db = await instance.database;
    final maps = await db.query(
      'chapters',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [chapterId],
    );
    
    if (maps.isNotEmpty) {
      return Chapter.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateChapter(Chapter chapter) async {
    final db = await instance.database;
    await db.update(
      'chapters',
      chapter.toMap(),
      where: 'id = ?',
      whereArgs: [chapter.id],
    );
  }

  Future<void> deleteChapter(int chapterId) async {
    final db = await instance.database;
    // 逻辑删除
    await db.update(
      'chapters',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [chapterId],
    );
  }

  // Reading Progress operations
  Future<ReadingProgress> createReadingProgress(ReadingProgress progress) async {
    final db = await instance.database;
    final id = await db.insert('reading_progress', progress.toMap());
    return progress.copyWith(id: id);
  }

  Future<ReadingProgress?> getOrCreateReadingProgress(int chantingId, int? chapterId, {int? userId}) async {
    final db = await instance.database;
    
    // 如果没有传用户ID，使用默认用户ID 1（假设存在）
    final actualUserId = userId ?? 1;
    
    // 尝试获取现有进度
    final maps = await db.query(
      'reading_progress',
      where: 'user_id = ? AND chanting_id = ? AND chapter_id ${chapterId != null ? '= ?' : 'IS NULL'}',
      whereArgs: chapterId != null 
        ? [actualUserId, chantingId, chapterId] 
        : [actualUserId, chantingId],
    );
    
    if (maps.isNotEmpty) {
      return ReadingProgress.fromMap(maps.first);
    }
    
    // 创建新的进度记录
    final newProgress = ReadingProgress(
      userId: actualUserId,
      chantingId: chantingId,
      chapterId: chapterId,
      lastReadAt: DateTime.now(),
      createdAt: DateTime.now(),
    );
    
    final id = await db.insert('reading_progress', newProgress.toMap());
    return newProgress.copyWith(id: id);
  }

  Future<List<ReadingProgress>> getReadingProgress(int chantingId, {int? userId}) async {
    final db = await instance.database;
    
    // 如果没有传用户ID，使用默认用户ID 1
    final actualUserId = userId ?? 1;
    
    final maps = await db.query(
      'reading_progress',
      where: 'user_id = ? AND chanting_id = ?',
      whereArgs: [actualUserId, chantingId],
      orderBy: 'chapter_id ASC NULLS FIRST',
    );
    
    return maps.map((map) => ReadingProgress.fromMap(map)).toList();
  }

  Future<ReadingProgress> updateReadingProgress(
    int chantingId,
    int? chapterId, {
    int? userId,
    bool? isCompleted,
    int? readingPosition,
    String? notes,
  }) async {
    final db = await instance.database;
    
    // 如果没有传用户ID，使用默认用户ID 1
    final actualUserId = userId ?? 1;
    
    // 获取现有进度记录
    final existing = await getOrCreateReadingProgress(chantingId, chapterId, userId: actualUserId);
    
    if (existing != null) {
      final updatedProgress = existing.copyWith(
        isCompleted: isCompleted ?? existing.isCompleted,
        readingPosition: readingPosition ?? existing.readingPosition,
        notes: notes ?? existing.notes,
        lastReadAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await db.update(
        'reading_progress',
        updatedProgress.toMap(),
        where: 'id = ?',
        whereArgs: [updatedProgress.id],
      );
      
      return updatedProgress;
    }
    
    throw Exception('Failed to update reading progress');
  }

  Future<ReadingProgressSummary?> getReadingProgressSummary(int chantingId, {int? userId}) async {
    final db = await instance.database;
    
    // 获取经文信息
    final chantingMaps = await db.query(
      'chantings',
      where: 'id = ?',
      whereArgs: [chantingId],
    );
    
    if (chantingMaps.isEmpty) return null;
    
    final chantingTitle = chantingMaps.first['title'] as String;
    
    // 获取总章节数
    final totalChaptersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM chapters WHERE chanting_id = ? AND is_deleted = 0',
      [chantingId],
    );
    final totalChapters = totalChaptersResult.first['count'] as int;
    
    if (totalChapters == 0) {
      return ReadingProgressSummary(
        chantingId: chantingId,
        chantingTitle: chantingTitle,
        totalChapters: 0,
        completedChapters: 0,
        progressPercentage: 0,
      );
    }
    
    // 如果没有传用户ID，使用默认用户ID 1
    final actualUserId = userId ?? 1;
    
    // 获取已完成章节数
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reading_progress WHERE user_id = ? AND chanting_id = ? AND chapter_id IS NOT NULL AND is_completed = 1',
      [actualUserId, chantingId],
    );
    final completedChapters = completedResult.first['count'] as int;
    
    final progressPercentage = (completedChapters / totalChapters) * 100;
    
    return ReadingProgressSummary(
      chantingId: chantingId,
      chantingTitle: chantingTitle,
      totalChapters: totalChapters,
      completedChapters: completedChapters,
      progressPercentage: progressPercentage,
    );
  }

  Future<void> deleteReadingProgress(int progressId) async {
    final db = await instance.database;
    await db.delete(
      'reading_progress',
      where: 'id = ?',
      whereArgs: [progressId],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}


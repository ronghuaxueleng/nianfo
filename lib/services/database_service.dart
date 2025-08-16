import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/dedication.dart';
import '../models/chanting.dart';
import '../models/dedication_template.dart';
import '../models/daily_stats.dart';

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
      version: 6,
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

    // 初始化内置模板和内置经文
    await _initializeBuiltInTemplates(db);
    await _initializeBuiltInChantings(db);
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

  // User operations
  Future<User> createUser(User user) async {
    final db = await instance.database;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<User?> getUser(String username, String password) async {
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
    await db.update(
      'dedication_templates',
      template.toMap(),
      where: 'id = ?',
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
    await db.update(
      'chantings',
      chanting.toMap(),
      where: 'id = ?',
      whereArgs: [chanting.id],
    );
  }

  Future<void> deleteChanting(int id) async {
    final db = await instance.database;
    await db.delete('chantings', where: 'id = ?', whereArgs: [id]);
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}


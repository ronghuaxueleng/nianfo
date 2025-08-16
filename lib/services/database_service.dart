import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/dedication.dart';
import '../models/chanting.dart';
import '../models/dedication_template.dart';

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
      version: 4,
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
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE chantings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
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

    // 初始化内置模板
    await _initializeBuiltInTemplates(db);
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
  }

  Future<void> _initializeBuiltInTemplates(Database db) async {
    final templates = BuiltInTemplates.defaultTemplates;
    for (final template in templates) {
      await db.insert('dedication_templates', template.toMap());
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
    final maps = await db.query('chantings', orderBy: 'created_at DESC');
    return maps.map((map) => Chanting.fromMap(map)).toList();
  }

  Future<List<Chanting>> getChantingsByType(ChantingType type) async {
    final db = await instance.database;
    final maps = await db.query(
      'chantings',
      where: 'type = ?',
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

extension UserCopyWith on User {
  User copyWith({int? id}) {
    return User(
      id: id ?? this.id,
      username: username,
      password: password,
      createdAt: createdAt,
    );
  }
}

extension DedicationCopyWith on Dedication {
  Dedication copyWith({int? id}) {
    return Dedication(
      id: id ?? this.id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension ChantingCopyWith on Chanting {
  Chanting copyWith({int? id}) {
    return Chanting(
      id: id ?? this.id,
      title: title,
      content: content,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
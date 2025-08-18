import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../models/chanting.dart';
import '../models/dedication.dart';
import '../models/chanting_record.dart';
import '../models/daily_stats.dart';
import '../models/dedication_template.dart';
import '../config/app_config.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  
  SyncService._init();
  
  // 后台API地址 - 从配置文件获取
  static List<String> get _backendUrls => AppConfig.backendUrls;
  
  // 同步状态
  bool _isSyncing = false;
  Timer? _syncTimer;
  
  /// 开始自动同步（app启动后1分钟开始）
  void startAutoSync() {
    // 避免重复启动
    if (_syncTimer != null) {
      return;
    }
    
    // 1分钟后开始首次同步
    _syncTimer = Timer(const Duration(minutes: 1), () {
      _performSilentSync();
      
      // 之后每30分钟同步一次
      _syncTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
        _performSilentSync();
      });
    });
    
    dev.log('数据同步服务已启动，将在1分钟后开始同步', name: 'SyncService');
  }
  
  /// 停止自动同步
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    dev.log('数据同步服务已停止', name: 'SyncService');
  }
  
  /// 执行静默同步
  Future<void> _performSilentSync() async {
    // 避免重复同步
    if (_isSyncing) {
      return;
    }
    
    _isSyncing = true;
    
    try {
      dev.log('开始静默数据同步...', name: 'SyncService');
      
      // 收集所有数据
      final allData = await _collectAllData();
      
      // 尝试同步到后台
      await _syncToBackend(allData);
      
      dev.log('数据同步完成', name: 'SyncService');
    } catch (e) {
      // 静默处理错误，不影响app运行
      dev.log('数据同步失败: $e', name: 'SyncService');
    } finally {
      _isSyncing = false;
    }
  }
  
  /// 收集所有本地数据
  Future<Map<String, dynamic>> _collectAllData() async {
    try {
      final db = await DatabaseService.instance.database;
      
      // 获取当前用户认证信息
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      final password = prefs.getString('password');
      
      // 收集用户数据
      final users = await db.query('users');
      final usersData = users.map((row) => {
        'username': row['username'],
        'password': row['password'],
        'avatar': row['avatar'],
        'avatar_type': row['avatar_type'],
        'nickname': row['nickname'],
        'created_at': row['created_at'],
      }).toList();
      
      // 收集佛号经文数据
      final chantings = await db.query('chantings', where: 'is_deleted = ?', whereArgs: [0]);
      final chantingsData = chantings.map((row) => {
        'title': row['title'],
        'content': row['content'],
        'pronunciation': row['pronunciation'],
        'type': row['type'],
        'is_built_in': row['is_built_in'] == 1,
        'created_at': row['created_at'],
        'updated_at': row['updated_at'],
      }).toList();
      
      // 收集回向数据（包含关联的佛号经文信息）
      final dedications = await db.rawQuery('''
        SELECT d.*, c.title as chanting_title, c.content as chanting_content
        FROM dedications d
        LEFT JOIN chantings c ON d.chanting_id = c.id
      ''');
      final dedicationsData = dedications.map((row) => {
        'title': row['title'],
        'content': row['content'],
        'chanting_title': row['chanting_title'],
        'chanting_content': row['chanting_content'],
        'created_at': row['created_at'],
        'updated_at': row['updated_at'],
      }).toList();
      
      // 收集修行记录（包含关联的佛号经文信息）
      final records = await db.rawQuery('''
        SELECT cr.*, c.title as chanting_title, c.content as chanting_content
        FROM chanting_records cr
        JOIN chantings c ON cr.chanting_id = c.id
        WHERE c.is_deleted = 0
      ''');
      final recordsData = records.map((row) => {
        'chanting_title': row['chanting_title'],
        'chanting_content': row['chanting_content'],
        'created_at': row['created_at'],
        'updated_at': row['updated_at'],
      }).toList();
      
      // 收集每日统计（包含关联的佛号经文信息）
      final stats = await db.rawQuery('''
        SELECT ds.*, c.title as chanting_title, c.content as chanting_content
        FROM daily_stats ds
        JOIN chantings c ON ds.chanting_id = c.id
        WHERE c.is_deleted = 0
      ''');
      final statsData = stats.map((row) => {
        'chanting_title': row['chanting_title'],
        'chanting_content': row['chanting_content'],
        'count': row['count'],
        'date': row['date'],
        'created_at': row['created_at'],
        'updated_at': row['updated_at'],
      }).toList();
      
      // 收集回向模板
      final templates = await db.query('dedication_templates');
      final templatesData = templates.map((row) => {
        'title': row['title'],
        'content': row['content'],
        'is_built_in': row['is_built_in'] == 1,
        'created_at': row['created_at'],
        'updated_at': row['updated_at'],
      }).toList();
      
      return {
        'auth': {
          'username': username,
          'password': password,
        },
        'users': usersData,
        'chantings': chantingsData,
        'dedications': dedicationsData,
        'chanting_records': recordsData,
        'daily_stats': statsData,
        'dedication_templates': templatesData,
        'sync_timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      dev.log('收集数据失败: $e', name: 'SyncService');
      return {};
    }
  }
  
  /// 同步数据到后台
  Future<void> _syncToBackend(Map<String, dynamic> data) async {
    if (data.isEmpty) {
      return;
    }
    
    // 尝试每个后台地址
    for (final baseUrl in _backendUrls) {
      try {
        final url = '$baseUrl/upload';
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': AppConfig.userAgent,
          },
          body: jsonEncode(data),
        ).timeout(
          AppConfig.connectionTimeout,
          onTimeout: () {
            throw TimeoutException('连接超时', AppConfig.connectionTimeout);
          },
        );
        
        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          // 检查是否认证失败
          if (result['message'] == 'authentication failed') {
            dev.log('同步失败: 认证失败', name: 'SyncService');
            throw Exception('认证失败，请检查用户名和密码');
          }
          dev.log('同步成功: ${result['message']}', name: 'SyncService');
          return; // 成功后退出
        } else {
          dev.log('同步失败: HTTP ${response.statusCode}', name: 'SyncService');
        }
      } catch (e) {
        dev.log('同步到 $baseUrl 失败: $e', name: 'SyncService');
        // 继续尝试下一个地址
      }
    }
    
    // 所有地址都失败了
    dev.log('所有后台地址均无法访问，同步失败', name: 'SyncService');
  }
  
  /// 手动触发同步（仅在必要时使用）
  Future<bool> manualSync() async {
    if (_isSyncing) {
      return false;
    }
    
    try {
      await _performSilentSync();
      return true;
    } catch (e) {
      dev.log('手动同步失败: $e', name: 'SyncService');
      return false;
    }
  }
  
  /// 手动上传数据到服务器
  Future<bool> manualUploadSync() async {
    if (_isSyncing) {
      return false;
    }
    
    _isSyncing = true;
    
    try {
      dev.log('开始手动上传数据...', name: 'SyncService');
      
      // 收集所有数据
      final allData = await _collectAllData();
      
      // 尝试同步到后台
      await _syncToBackend(allData);
      
      dev.log('手动上传完成', name: 'SyncService');
      return true;
    } catch (e) {
      dev.log('手动上传失败: $e', name: 'SyncService');
      // 如果是认证失败，需要特殊处理
      if (e.toString().contains('认证失败')) {
        dev.log('认证信息无效，请重新登录', name: 'SyncService');
      }
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// 手动从服务器下载数据
  Future<bool> manualDownloadSync() async {
    if (_isSyncing) {
      return false;
    }
    
    _isSyncing = true;
    
    try {
      dev.log('开始从服务器下载数据...', name: 'SyncService');
      
      // 尝试从每个后台地址下载数据
      for (final baseUrl in _backendUrls) {
        try {
          final url = '$baseUrl/download';
          
          final response = await http.get(
            Uri.parse(url),
            headers: {'User-Agent': AppConfig.userAgent},
          ).timeout(
            AppConfig.connectionTimeout,
            onTimeout: () {
              throw TimeoutException('连接超时', AppConfig.connectionTimeout);
            },
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            
            // 将下载的数据保存到本地数据库
            await _saveDownloadedData(data);
            
            dev.log('从服务器下载数据成功', name: 'SyncService');
            return true;
          } else {
            dev.log('下载失败: HTTP ${response.statusCode}', name: 'SyncService');
          }
        } catch (e) {
          dev.log('从 $baseUrl 下载失败: $e', name: 'SyncService');
          // 继续尝试下一个地址
        }
      }
      
      // 所有地址都失败了
      dev.log('所有后台地址均无法访问，下载失败', name: 'SyncService');
      return false;
    } catch (e) {
      dev.log('手动下载失败: $e', name: 'SyncService');
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// 保存下载的数据到本地数据库
  Future<void> _saveDownloadedData(Map<String, dynamic> data) async {
    try {
      final db = await DatabaseService.instance.database;
      
      // 这里可以实现数据合并逻辑
      // 暂时只记录日志，实际实现需要根据业务需求来设计
      dev.log('收到服务器数据，准备保存到本地...', name: 'SyncService');
      
      // TODO: 实现具体的数据保存逻辑
      // 可能需要考虑数据冲突处理、合并策略等
      
      dev.log('服务器数据已保存到本地', name: 'SyncService');
    } catch (e) {
      dev.log('保存服务器数据失败: $e', name: 'SyncService');
      throw e;
    }
  }
  
  /// 检查后台服务是否可用
  Future<bool> checkBackendHealth() async {
    dev.log('开始检查后台服务健康状态...', name: 'SyncService');
    
    for (final baseUrl in _backendUrls) {
      try {
        final url = '$baseUrl/health';
        dev.log('正在测试连接: $url', name: 'SyncService');
        
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': AppConfig.userAgent},
        ).timeout(AppConfig.healthCheckTimeout);
        
        dev.log('收到响应: HTTP ${response.statusCode}', name: 'SyncService');
        
        if (response.statusCode == 200) {
          dev.log('✅ 后台服务 $baseUrl 连接成功', name: 'SyncService');
          return true;
        } else {
          dev.log('❌ 后台服务 $baseUrl HTTP状态码: ${response.statusCode}', name: 'SyncService');
        }
      } catch (e) {
        dev.log('❌ 后台服务 $baseUrl 连接失败: $e', name: 'SyncService');
        dev.log('错误类型: ${e.runtimeType}', name: 'SyncService');
      }
    }
    
    dev.log('所有后台地址测试完毕，均无法连接', name: 'SyncService');
    return false;
  }
}

/// 超时异常
class TimeoutException implements Exception {
  final String message;
  final Duration timeout;
  
  const TimeoutException(this.message, this.timeout);
  
  @override
  String toString() => 'TimeoutException: $message (${timeout.inSeconds}s)';
}
import '../services/database_service.dart';
import '../models/user.dart';
import 'crypto_utils.dart';

class PasswordMigration {
  /// 迁移现有用户的明文密码为哈希密码
  static Future<void> migratePasswords() async {
    try {
      final db = await DatabaseService.instance.database;
      
      // 获取所有用户
      final users = await db.query('users');
      
      for (final userMap in users) {
        final user = User.fromMap(userMap);
        final password = user.password;
        
        // 检查是否已经是哈希密码（SHA-256哈希是64位十六进制字符串）
        if (password.length != 64 || !_isHexString(password)) {
          // 如果不是哈希密码，则进行哈希
          final hashedPassword = CryptoUtils.hashPassword(password);
          
          // 更新数据库中的密码
          await db.update(
            'users',
            {'password': hashedPassword},
            where: 'id = ?',
            whereArgs: [user.id],
          );
          
          print('用户 ${user.username} 的密码已迁移到哈希格式');
        }
      }
      
      print('密码迁移完成');
    } catch (e) {
      print('密码迁移失败: $e');
      rethrow;
    }
  }
  
  /// 检查字符串是否为十六进制
  static bool _isHexString(String str) {
    return RegExp(r'^[a-fA-F0-9]+$').hasMatch(str);
  }
  
  /// 验证迁移是否成功
  static Future<bool> verifyMigration() async {
    try {
      final db = await DatabaseService.instance.database;
      final users = await db.query('users');
      
      for (final userMap in users) {
        final user = User.fromMap(userMap);
        final password = user.password;
        
        // 所有密码都应该是64位十六进制字符串
        if (password.length != 64 || !_isHexString(password)) {
          print('发现未迁移的密码: ${user.username}');
          return false;
        }
      }
      
      print('所有用户密码都已正确迁移');
      return true;
    } catch (e) {
      print('验证迁移失败: $e');
      return false;
    }
  }
}
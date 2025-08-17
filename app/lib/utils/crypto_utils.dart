import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  /// 使用SHA-256加密密码
  static String hashPassword(String password) {
    // 添加固定盐值以增强安全性
    const salt = 'nianfo_app_salt_2024';
    final saltedPassword = password + salt;
    
    // 使用SHA-256哈希
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }
  
  /// 验证密码
  static bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }
  
  /// 生成随机盐值（如果需要更高安全性）
  static String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return hashPassword(random).substring(0, 16);
  }
}
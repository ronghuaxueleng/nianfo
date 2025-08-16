import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  AuthService() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    if (username != null && password != null) {
      try {
        final user = await DatabaseService.instance.getUser(username, password);
        if (user != null) {
          _currentUser = user;
          _isLoggedIn = true;
          notifyListeners();
        }
      } catch (e) {
        // 如果加载失败，清除存储的信息
        await prefs.remove('username');
        await prefs.remove('password');
      }
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final user = await DatabaseService.instance.getUser(username, password);
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('password', password);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String username, String password) async {
    try {
      final user = User(
        username: username,
        password: password,
        createdAt: DateTime.now(),
      );
      
      final createdUser = await DatabaseService.instance.createUser(user);
      _currentUser = createdUser;
      _isLoggedIn = true;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password);
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isLoggedIn = false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
    
    notifyListeners();
  }

  Future<bool> updateUserProfile(String newUsername, String? newAvatar, AvatarType? avatarType) async {
    if (_currentUser == null) return false;
    
    try {
      final updatedUser = _currentUser!.copyWith(
        username: newUsername,
        avatar: newAvatar,
        avatarType: avatarType,
      );
      
      await DatabaseService.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      
      // 更新SharedPreferences中的用户名
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', newUsername);
      
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
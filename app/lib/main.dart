import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';
import 'utils/password_migration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.database;
  
  // 执行密码迁移（将明文密码转换为哈希密码）
  try {
    await PasswordMigration.migratePasswords();
  } catch (e) {
    debugPrint('密码迁移失败: $e');
  }
  
  runApp(const NianfoApp());
}

class NianfoApp extends StatefulWidget {
  const NianfoApp({super.key});

  @override
  State<NianfoApp> createState() => _NianfoAppState();
}

class _NianfoAppState extends State<NianfoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 启动静默数据同步服务
    _initSyncService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 停止同步服务
    SyncService.instance.stopAutoSync();
    super.dispose();
  }

  /// 初始化同步服务
  void _initSyncService() {
    try {
      // 启动自动同步（1分钟后开始）
      SyncService.instance.startAutoSync();
    } catch (e) {
      // 静默处理初始化错误，不影响app启动
      debugPrint('同步服务初始化失败: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 当app重新激活时，可以考虑手动触发一次同步
    if (state == AppLifecycleState.resumed) {
      // 静默尝试同步，不影响用户体验
      Future.delayed(const Duration(seconds: 5), () {
        try {
          SyncService.instance.manualSync();
        } catch (e) {
          // 静默处理错误
          debugPrint('App恢复时同步失败: $e');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: '修行记录',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Consumer<AuthService>(
          builder: (context, auth, _) {
            return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
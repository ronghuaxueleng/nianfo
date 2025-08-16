import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../models/chanting.dart';
import 'template_management_screen.dart';
import 'chanting_management_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  bool _isMenuVisible = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  int _todayBuddhaNamCount = 0;
  int _todaySutraCount = 0;
  int _totalDedicationCount = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _statsLoading = true;
    });

    try {
      final buddhaNameCount = await DatabaseService.instance.getTotalCountByType(ChantingType.buddhaNam);
      final sutraCount = await DatabaseService.instance.getTotalCountByType(ChantingType.sutra);
      final dedications = await DatabaseService.instance.getAllDedications();

      setState(() {
        _todayBuddhaNamCount = buddhaNameCount;
        _todaySutraCount = sutraCount;
        _totalDedicationCount = dedications.length;
        _statsLoading = false;
      });
    } catch (e) {
      setState(() {
        _statsLoading = false;
      });
    }
  }

  void _showMenu() {
    setState(() {
      _isMenuVisible = true;
    });
    _animationController.forward();
  }

  void _hideMenu() {
    _animationController.reverse().then((_) {
      setState(() {
        _isMenuVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 主要内容区域（全屏）
          GestureDetector(
            onPanStart: (details) {
              // 检测从左边缘开始的滑动
              if (details.globalPosition.dx < 20) {
                _showMenu();
              }
            },
            child: _buildMainContent(),
          ),
          
          // 左侧菜单（叠加层）
          if (_isMenuVisible)
            Stack(
              children: [
                // 半透明遮罩
                GestureDetector(
                  onTap: _hideMenu,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
                
                // 滑动菜单
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildSideMenu(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSideMenu() {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头部区域
          _buildMenuHeader(),
          
          // 菜单项
          _buildMenuItems(),
          
          // 底部退出按钮
          _buildMenuFooter(),
        ],
      ),
    );
  }

  Widget _buildMenuHeader() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            border: Border(
              bottom: BorderSide(
                color: Colors.orange.shade200,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // 菜单标题和关闭按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '个人中心',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  IconButton(
                    onPressed: _hideMenu,
                    icon: Icon(
                      Icons.close,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 用户头像和信息
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: _buildAvatarContent(user),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    Text(
                      user?.nickname?.isNotEmpty == true ? user!.nickname! : (user?.username ?? '游客'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '点击编辑资料',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItems() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _buildSideMenuItem(
              icon: Icons.library_books,
              title: '回向文模板',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TemplateManagementScreen(),
                  ),
                );
              },
            ),
            _buildSideMenuItem(
              icon: Icons.self_improvement,
              title: '佛号经文管理',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChantingManagementScreen(),
                  ),
                );
              },
            ),
            _buildSideMenuItem(
              icon: Icons.settings,
              title: '设置',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('设置功能即将上线')),
                );
              },
            ),
            _buildSideMenuItem(
              icon: Icons.info_outline,
              title: '关于应用',
              onTap: () {
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16, 
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuFooter() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.orange.shade200,
                width: 1,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLogoutDialog(context, authService),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12, 
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '退出登录',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        
        return Column(
          children: [
            // 顶部应用栏
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _showMenu,
                    icon: Icon(
                      Icons.menu,
                      color: Colors.orange.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '个人中心',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
            
            // 主要内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 欢迎区域
                    _buildWelcomeSection(user),
                    
                    const SizedBox(height: 32),
                    
                    // 统计信息卡片
                    _buildStatsSection(),
                    
                    const SizedBox(height: 32),
                    
                    // 底部祝福
                    _buildBlessingSection(),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeSection(User? user) {
    final hour = DateTime.now().hour;
    String greeting = '';
    if (hour < 6) {
      greeting = '深夜了，注意休息';
    } else if (hour < 12) {
      greeting = '早上好';
    } else if (hour < 18) {
      greeting = '下午好';
    } else {
      greeting = '晚上好';
    }

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade400,
              Colors.orange.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting，${user?.nickname?.isNotEmpty == true ? user!.nickname! : (user?.username ?? '游客')}！',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '愿您在修行路上精进不懈，功德日增',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange.shade100,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '今日：${_formatDate(DateTime.now())}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '功德统计',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
        const SizedBox(height: 16),
        if (_statsLoading)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.self_improvement,
                      title: '念佛总数',
                      value: _todayBuddhaNamCount.toString(),
                      subtitle: '次念诵',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.book,
                      title: '读经总数',
                      value: _todaySutraCount.toString(),
                      subtitle: '次读诵',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.favorite,
                      title: '回向记录',
                      value: _totalDedicationCount.toString(),
                      subtitle: '篇回向文',
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.today,
                      title: '修行天数',
                      value: '1',
                      subtitle: '天坚持',
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBlessingSection() {
    return Card(
      elevation: 3,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.orange.shade50,
        ),
        child: Column(
          children: [
            Icon(
              Icons.favorite,
              color: Colors.orange.shade600,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              '南无阿弥陀佛',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '愿以此功德，回向法界众生\n愿众生离苦得乐，究竟解脱',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于修行记录'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本：1.0.0'),
            SizedBox(height: 8),
            Text('修行记录是一款帮助修行者记录和管理念经、回向的应用。'),
            SizedBox(height: 8),
            Text('愿此应用能够帮助您更好地修行，积累功德。'),
            SizedBox(height: 16),
            Text(
              '南无阿弥陀佛 🙏',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              authService.logout();
              Navigator.of(context).pop();
              // 移除手动跳转，让Consumer自动处理状态变化
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(User? user) {
    if (user == null) {
      return Icon(
        Icons.person,
        size: 50,
        color: Colors.orange.shade700,
      );
    }

    if (user.avatarType == AvatarType.image && user.avatar != null) {
      final file = File(user.avatar!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: 80,
          height: 80,
          errorBuilder: (context, error, stackTrace) {
            // 如果图片加载失败，显示默认emoji
            return Center(
              child: Text(
                '🧘',
                style: const TextStyle(fontSize: 32),
              ),
            );
          },
        );
      }
    }

    // 显示emoji头像或默认图标
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      return Center(
        child: Text(
          user.avatar!,
          style: const TextStyle(fontSize: 32),
        ),
      );
    }

    return Icon(
      Icons.person,
      size: 50,
      color: Colors.orange.shade700,
    );
  }
}
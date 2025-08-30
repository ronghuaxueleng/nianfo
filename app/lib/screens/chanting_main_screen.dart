import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/daily_stats.dart';
import '../services/database_service.dart';
import 'buddha_nam_management_screen.dart';
import 'sutra_management_screen.dart';
import 'chanting_statistics_screen.dart';

class ChantingMainScreen extends StatefulWidget {
  const ChantingMainScreen({super.key});

  @override
  State<ChantingMainScreen> createState() => _ChantingMainScreenState();
}

class _ChantingMainScreenState extends State<ChantingMainScreen> {
  bool _isLoading = true;
  int _totalBuddhaNames = 0;
  int _totalSutras = 0;
  int _todayBuddhaCount = 0;
  int _todaySutraCount = 0;
  List<DailyStats> _todayStats = [];

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final buddhaNames = await DatabaseService.instance.getChantingsByType(ChantingType.buddhaNam);
      final sutras = await DatabaseService.instance.getChantingsByType(ChantingType.sutra);
      final todayStats = await DatabaseService.instance.getAllTodayStats();
      
      int todayBuddhaCount = 0;
      int todaySutraCount = 0;
      
      // 计算今日各类型的念诵总数
      for (final stat in todayStats) {
        // 根据chanting_id查找对应的经文类型
        final buddha = buddhaNames.firstWhere((b) => b.id == stat.chantingId, orElse: () => 
          Chanting(title: '', content: '', type: ChantingType.sutra, createdAt: DateTime.now()));
        final sutra = sutras.firstWhere((s) => s.id == stat.chantingId, orElse: () => 
          Chanting(title: '', content: '', type: ChantingType.buddhaNam, createdAt: DateTime.now()));
        
        if (buddha.title.isNotEmpty && buddha.type == ChantingType.buddhaNam) {
          todayBuddhaCount += stat.count;
        } else if (sutra.title.isNotEmpty && sutra.type == ChantingType.sutra) {
          todaySutraCount += stat.count;
        }
      }

      setState(() {
        _totalBuddhaNames = buddhaNames.length;
        _totalSutras = sutras.length;
        _todayBuddhaCount = todayBuddhaCount;
        _todaySutraCount = todaySutraCount;
        _todayStats = todayStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('修行记录'),
        backgroundColor: Colors.orange.shade100,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 今日统计卡片
                    _buildTodayStatsCard(),
                    
                    const SizedBox(height: 20),
                    
                    // 功能入口卡片
                    Text(
                      '功能入口',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            '佛号管理',
                            '管理和念诵佛号',
                            Icons.self_improvement,
                            Colors.blue,
                            '$_totalBuddhaNames 个佛号',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const BuddhaNamManagementScreen()),
                            ).then((_) => _loadStatistics()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            '经文管理',
                            '阅读和学习经文',
                            Icons.book,
                            Colors.green,
                            '$_totalSutras 部经文',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SutraManagementScreen()),
                            ).then((_) => _loadStatistics()),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 今日详细记录
                    if (_todayStats.isNotEmpty) ...[
                      Text(
                        '今日修行详情',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTodayDetailsList(),
                    ] else ...[
                      _buildEmptyTodayState(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTodayStatsCard() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.amber.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  '今日修行统计',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTodayStatItem(
                    '佛号',
                    _todayBuddhaCount,
                    Colors.blue,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildTodayStatItem(
                    '经文',
                    _todaySutraCount,
                    Colors.green,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildTodayStatItem(
                    '总计',
                    _todayBuddhaCount + _todaySutraCount,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color is MaterialColor ? color.shade700 : color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color is MaterialColor ? color.shade600 : color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String badge,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color is MaterialColor ? color.shade100 : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon,
                  color: color is MaterialColor ? color.shade600 : color.withOpacity(0.7),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color is MaterialColor ? color.shade100 : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    color: color is MaterialColor ? color.shade700 : color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayDetailsList() {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _todayStats.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final stat = _todayStats[index];
          return FutureBuilder<Chanting?>(
            future: _getChantingById(stat.chantingId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('加载中...'),
                );
              }
              
              final chanting = snapshot.data!;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: chanting.type == ChantingType.buddhaNam 
                      ? Colors.blue.shade100 
                      : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    chanting.type == ChantingType.buddhaNam 
                      ? Icons.self_improvement 
                      : Icons.book,
                    color: chanting.type == ChantingType.buddhaNam 
                      ? Colors.blue.shade600 
                      : Colors.green.shade600,
                    size: 20,
                  ),
                ),
                title: Text(chanting.title),
                subtitle: Text(
                  chanting.type == ChantingType.buddhaNam ? '佛号' : '经文',
                  style: TextStyle(
                    color: chanting.type == ChantingType.buddhaNam 
                      ? Colors.blue.shade600 
                      : Colors.green.shade600,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${stat.count} 次',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChantingStatisticsScreen(chanting: chanting),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyTodayState() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.sentiment_neutral,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              '今日还没有修行记录',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '开始您的修行之旅吧！',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Chanting?> _getChantingById(int id) async {
    try {
      final buddhaNames = await DatabaseService.instance.getChantingsByType(ChantingType.buddhaNam);
      final sutras = await DatabaseService.instance.getChantingsByType(ChantingType.sutra);
      
      final allChantings = [...buddhaNames, ...sutras];
      return allChantings.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
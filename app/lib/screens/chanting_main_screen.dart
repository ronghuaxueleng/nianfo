import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/daily_stats.dart';
import '../models/chanting_record.dart';
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
  List<ChantingRecordWithDetails> _chantingRecords = [];

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
      final chantingRecords = await DatabaseService.instance.getChantingRecordsWithDetails();
      
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
        _chantingRecords = chantingRecords;
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
                    
                    // 添加修行项目按钮
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _showAddChantingDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('添加修行项目', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 修行记录
                    if (_chantingRecords.isNotEmpty) ...[
                      Row(
                        children: [
                          Text(
                            '我的修行记录',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '← 滑动删除',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildChantingRecordsList(),
                    ] else ...[
                      _buildEmptyRecordsState(),
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

  Widget _buildChantingRecordsList() {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _chantingRecords.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final record = _chantingRecords[index];
          final chanting = record.chanting;
          
          // 获取今日该项目的统计数据
          final todayStat = _todayStats.firstWhere(
            (stat) => stat.chantingId == chanting.id,
            orElse: () => DailyStats(
              chantingId: chanting.id!,
              count: 0,
              date: DateTime.now(),
              createdAt: DateTime.now(),
            ),
          );
          
          return Dismissible(
            key: Key('record_${record.record.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 24,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('确认删除'),
                    content: Text('确定要从修行记录中移除 "${chanting.title}" 吗？\n\n注意：这将删除所有相关的修行统计数据。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) async {
              await _deleteChantingRecord(record.record.id!);
            },
            child: ListTile(
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
              title: Text(
                chanting.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                chanting.type == ChantingType.buddhaNam ? '佛号' : '经文',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '今日 ${todayStat.count} 次',
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyRecordsState() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有添加修行项目',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击上方 "+" 按钮添加佛号或经文',
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

  Future<void> _deleteChantingRecord(int recordId) async {
    try {
      await DatabaseService.instance.deleteChantingRecord(recordId);
      await _loadStatistics(); // 重新加载数据
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已从修行记录中删除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddChantingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择修行项目'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.self_improvement, color: Colors.blue),
                title: const Text('佛号'),
                subtitle: const Text('选择佛号添加到修行记录'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BuddhaNamManagementScreen()),
                  ).then((_) => _loadStatistics());
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.book, color: Colors.green),
                title: const Text('经文'),
                subtitle: const Text('选择经文添加到修行记录'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SutraManagementScreen()),
                  ).then((_) => _loadStatistics());
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }
}
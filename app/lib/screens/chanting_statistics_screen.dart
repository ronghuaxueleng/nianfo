import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/daily_stats.dart';
import '../services/database_service.dart';

class ChantingStatisticsScreen extends StatefulWidget {
  final Chanting chanting;

  const ChantingStatisticsScreen({
    super.key,
    required this.chanting,
  });

  @override
  State<ChantingStatisticsScreen> createState() => _ChantingStatisticsScreenState();
}

class _ChantingStatisticsScreenState extends State<ChantingStatisticsScreen> {
  List<DailyStats> _stats = [];
  bool _isLoading = true;
  int _totalCount = 0;
  int _totalDays = 0;
  double _averagePerDay = 0.0;
  int _maxDayCount = 0;
  String _maxDayDate = '';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.chanting.id != null) {
        final stats = await DatabaseService.instance.getChantingStatistics(widget.chanting.id!);
        
        // 计算统计数据
        int totalCount = 0;
        int maxCount = 0;
        String maxDate = '';
        
        for (final stat in stats) {
          totalCount += stat.count;
          if (stat.count > maxCount) {
            maxCount = stat.count;
            maxDate = _formatDate(stat.date);
          }
        }
        
        setState(() {
          _stats = stats;
          _totalCount = totalCount;
          _totalDays = stats.length;
          _averagePerDay = _totalDays > 0 ? totalCount / _totalDays : 0.0;
          _maxDayCount = maxCount;
          _maxDayDate = maxDate;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }

  String _formatFullDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.chanting.title} - 统计'),
        backgroundColor: Colors.orange.shade100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本信息卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (widget.chanting.type == ChantingType.buddhaNam 
                                      ? Colors.blue 
                                      : Colors.green).shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.chanting.type == ChantingType.buddhaNam ? '佛号' : '经文',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: (widget.chanting.type == ChantingType.buddhaNam 
                                        ? Colors.blue 
                                        : Colors.green).shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (widget.chanting.isBuiltIn) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '内置',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.chanting.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 统计概览卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 统计概览',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  '总计次数',
                                  '$_totalCount',
                                  '次',
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  '修行天数',
                                  '$_totalDays',
                                  '天',
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  '日均次数',
                                  _averagePerDay.toStringAsFixed(1),
                                  '次/天',
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  '单日最高',
                                  '$_maxDayCount',
                                  _maxDayDate.isNotEmpty ? _maxDayDate : '次',
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 详细记录卡片
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📈 每日记录',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_stats.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.bar_chart,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      '还没有修行记录',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _stats.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final stat = _stats[index];
                                final isMaxDay = stat.count == _maxDayCount;
                                
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: isMaxDay 
                                        ? Colors.orange.shade100 
                                        : Colors.grey.shade100,
                                    child: Icon(
                                      isMaxDay ? Icons.star : Icons.calendar_today,
                                      color: isMaxDay 
                                          ? Colors.orange.shade700 
                                          : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    _formatFullDate(stat.date),
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMaxDay 
                                          ? Colors.orange.shade600 
                                          : Colors.blue.shade600,
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
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _getColorShade(color, 700),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _getColorShade(color, 800),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: _getColorShade(color, 600),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorShade(Color color, int shade) {
    // 处理 MaterialColor 类型
    if (color is MaterialColor) {
      switch (shade) {
        case 600:
          return color.shade600;
        case 700:
          return color.shade700;
        case 800:
          return color.shade800;
        default:
          return color;
      }
    }
    
    // 对于非 MaterialColor，返回原色或适当的变体
    switch (shade) {
      case 600:
        return color.withOpacity(0.8);
      case 700:
        return color.withOpacity(0.9);
      case 800:
        return color;
      default:
        return color;
    }
  }
}
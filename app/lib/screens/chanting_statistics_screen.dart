import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/daily_stats.dart';
import '../models/reading_progress.dart';
import '../models/chapter.dart';
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
  
  // 阅读进度相关
  ReadingProgressSummary? _progressSummary;
  List<Chapter> _chapters = [];
  List<ReadingProgress> _readingProgress = [];

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
        // 加载传统统计数据
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
        
        // 加载阅读进度数据
        ReadingProgressSummary? progressSummary;
        List<Chapter> chapters = [];
        List<ReadingProgress> readingProgress = [];
        
        try {
          progressSummary = await DatabaseService.instance.getReadingProgressSummary(widget.chanting.id!);
          chapters = await DatabaseService.instance.getChaptersByChantingId(widget.chanting.id!);
          readingProgress = await DatabaseService.instance.getReadingProgress(widget.chanting.id!);
        } catch (e) {
          // 阅读进度数据加载失败，继续显示其他统计信息
          print('阅读进度数据加载失败: $e');
        }
        
        setState(() {
          _stats = stats;
          _totalCount = totalCount;
          _totalDays = stats.length;
          _averagePerDay = _totalDays > 0 ? totalCount / _totalDays : 0.0;
          _maxDayCount = maxCount;
          _maxDayDate = maxDate;
          
          _progressSummary = progressSummary;
          _chapters = chapters;
          _readingProgress = readingProgress;
          
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

                  // 阅读进度卡片（仅对有章节的经文显示）
                  if (_chapters.isNotEmpty) ...[
                    _buildReadingProgressCard(),
                    const SizedBox(height: 16),
                  ],

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

  Widget _buildReadingProgressCard() {
    final summary = _progressSummary;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📖 阅读进度',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (summary != null) ...[
              // 整体进度显示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.green.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '整体进度',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          '${summary.progressPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: summary.progressPercentage / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        summary.progressPercentage > 80 
                          ? Colors.green 
                          : summary.progressPercentage > 50 
                            ? Colors.orange 
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '已完成 ${summary.completedChapters} / ${summary.totalChapters} 章',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 章节详情
              if (_chapters.isNotEmpty) ...[
                Text(
                  '章节详情',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    final progress = _readingProgress.firstWhere(
                      (p) => p.chapterId == chapter.id,
                      orElse: () => ReadingProgress(
                        userId: 1,
                        chantingId: widget.chanting.id!,
                        chapterId: chapter.id,
                        lastReadAt: DateTime.now(),
                        createdAt: DateTime.now(),
                      ),
                    );
                    
                    final isCompleted = progress.isCompleted;
                    final hasProgress = _readingProgress.any((p) => p.chapterId == chapter.id);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCompleted 
                          ? Colors.green.shade50 
                          : hasProgress 
                            ? Colors.blue.shade50 
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted 
                            ? Colors.green.shade200 
                            : hasProgress 
                              ? Colors.blue.shade200 
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isCompleted 
                                ? Colors.green.shade600 
                                : hasProgress 
                                  ? Colors.blue.shade600 
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: isCompleted 
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : hasProgress 
                                  ? Icon(Icons.bookmark, color: Colors.white, size: 16)
                                  : Text(
                                      '${chapter.chapterNumber}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chapter.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isCompleted ? Colors.green.shade800 : Colors.black87,
                                  ),
                                ),
                                if (hasProgress && progress.lastReadAt != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '最后阅读: ${_formatLastReadTime(progress.lastReadAt)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (progress.notes?.isNotEmpty == true)
                            Icon(
                              Icons.note,
                              size: 16,
                              color: Colors.orange.shade600,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '还没有阅读进度记录',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatLastReadTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }
}
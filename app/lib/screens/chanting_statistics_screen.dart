import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/daily_stats.dart';
import '../models/reading_progress.dart';
import '../models/chapter.dart';
import '../models/dedication.dart';
import '../models/dedication_template.dart';
import '../services/database_service.dart';
import 'chanting_detail_screen.dart';

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
  
  // 今日次数相关
  int _todayCount = 0;
  
  // 阅读进度相关
  ReadingProgressSummary? _progressSummary;
  List<Chapter> _chapters = [];
  List<ReadingProgress> _readingProgress = [];
  
  // 回向文相关
  List<Dedication> _dedications = [];

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
        
        // 加载回向文数据
        List<Dedication> dedications = [];
        try {
          final allDedications = await DatabaseService.instance.getAllDedications();
          dedications = allDedications.where((d) => d.chantingId == widget.chanting.id).toList();
        } catch (e) {
          print('回向文数据加载失败: $e');
        }
        
        // 加载今日次数
        int todayCount = 0;
        try {
          final today = DateTime.now();
          final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          
          // 查找今日的统计记录
          final todayStats = stats.where((stat) {
            final statDate = '${stat.date.year}-${stat.date.month.toString().padLeft(2, '0')}-${stat.date.day.toString().padLeft(2, '0')}';
            return statDate == todayStr;
          });
          
          if (todayStats.isNotEmpty) {
            todayCount = todayStats.first.count;
          }
        } catch (e) {
          print('今日次数加载失败: $e');
        }
        
        setState(() {
          _stats = stats;
          _totalCount = totalCount;
          _totalDays = stats.length;
          _averagePerDay = _totalDays > 0 ? totalCount / _totalDays : 0.0;
          _maxDayCount = maxCount;
          _maxDayDate = maxDate;
          _todayCount = todayCount;
          
          _progressSummary = progressSummary;
          _chapters = chapters;
          _readingProgress = readingProgress;
          _dedications = dedications;
          
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
        actions: [
          IconButton(
            onPressed: _showDedicationDialog,
            icon: const Icon(Icons.favorite),
            tooltip: '回向',
          ),
        ],
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
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChantingDetailScreen(
                                    chanting: widget.chanting,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.blue.shade50,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.menu_book,
                                    color: Colors.blue.shade700,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.chanting.title,
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '点击查看完整正文',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.blue.shade700,
                                    size: 16,
                                  ),
                                ],
                              ),
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
                          
                          // 今日次数特殊显示区域
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.purple.shade50, Colors.purple.shade100],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.today,
                                          color: Colors.purple.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '今日阅读次数',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.purple.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      onPressed: _showEditTodayCountDialog,
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.purple.shade600,
                                        size: 18,
                                      ),
                                      tooltip: '编辑今日次数',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_todayCount',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple.shade800,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '次',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.purple.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.shade200,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${DateTime.now().month}/${DateTime.now().day}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.purple.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
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

                  // 回向文卡片
                  _buildDedicationCard(),
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

  Widget _buildDedicationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  '回向文',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_dedications.length} 篇',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_dedications.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '还没有回向文',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击右上角的❤️按钮添加回向',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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
                itemCount: _dedications.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final dedication = _dedications[index];
                  return InkWell(
                    onTap: () => _editDedication(dedication),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                color: Colors.orange.shade600,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dedication.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.orange.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatDedicationDate(dedication.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                color: Colors.grey.shade500,
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dedication.content,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDedicationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return '今天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}周前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  Future<void> _showEditTodayCountDialog() async {
    final TextEditingController controller = TextEditingController(text: _todayCount.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.purple.shade600),
            const SizedBox(width: 8),
            const Text('编辑今日次数'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前次数：$_todayCount 次',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '新的次数',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
                suffixText: '次',
              ),
              autofocus: true,
              onTap: () => controller.selection = TextSelection(
                baseOffset: 0,
                extentOffset: controller.text.length,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final newCount = int.tryParse(controller.text);
              if (newCount != null && newCount >= 0) {
                Navigator.of(context).pop(newCount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入有效的数字（≥0）'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result != null) {
      _updateTodayCount(result);
    }
  }

  Future<void> _updateTodayCount(int newCount) async {
    try {
      if (widget.chanting.id == null) return;
      
      // 使用现有的 createOrUpdateDailyStats 方法（它使用今日日期）
      await DatabaseService.instance.createOrUpdateDailyStats(
        widget.chanting.id!,
        newCount,
      );
      
      // 刷新统计数据
      await _loadStatistics();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('今日次数已更新为 $newCount 次'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editDedication(Dedication dedication) async {
    try {
      // 加载回向模板
      final templates = await DatabaseService.instance.getAllDedicationTemplates();
      
      if (!mounted) return;
      
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => EditDedicationDialogContent(
          chanting: widget.chanting,
          dedication: dedication,
          templates: templates,
        ),
      );
      
      // 如果成功编辑了回向文，刷新数据
      if (result == true) {
        _loadStatistics();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载回向模板失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showDedicationDialog() async {
    try {
      // 加载回向模板
      final templates = await DatabaseService.instance.getAllDedicationTemplates();
      
      if (!mounted) return;
      
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DedicationDialogContent(
          chanting: widget.chanting,
          templates: templates,
        ),
      );
      
      // 如果成功添加了回向文，刷新数据
      if (result == true) {
        _loadStatistics();
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载回向模板失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class DedicationDialogContent extends StatefulWidget {
  final Chanting chanting;
  final List<DedicationTemplate> templates;

  const DedicationDialogContent({
    super.key,
    required this.chanting,
    required this.templates,
  });

  @override
  State<DedicationDialogContent> createState() => _DedicationDialogContentState();
}

class _DedicationDialogContentState extends State<DedicationDialogContent> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  DedicationTemplate? _selectedTemplate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '为《${widget.chanting.title}》添加回向',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Templates section
                  if (widget.templates.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.bookmarks, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '选择回向模板',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // 模板下拉框
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DedicationTemplate>(
                          value: _selectedTemplate,
                          hint: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  '请选择回向模板（可选）',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          isExpanded: true,
                          items: [
                            // 添加一个"无模板"选项
                            const DropdownMenuItem<DedicationTemplate>(
                              value: null,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.clear, color: Colors.grey, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      '不使用模板',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 模板选项
                            ...widget.templates.map((template) {
                              return DropdownMenuItem<DedicationTemplate>(
                                value: template,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        template.isBuiltIn ? Icons.star : Icons.person,
                                        size: 16,
                                        color: template.isBuiltIn 
                                            ? Colors.orange.shade600
                                            : Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              template.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (template.content.length > 20)
                                              Text(
                                                template.content.length > 50 
                                                    ? '${template.content.substring(0, 50)}...'
                                                    : template.content,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (DedicationTemplate? template) {
                            _selectTemplate(template);
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),
                  ],
                  
                  // Form section
                  Row(
                    children: [
                      Icon(Icons.edit, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedTemplate != null ? '编辑回向内容' : '自定义回向',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_selectedTemplate != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedTemplate!.isBuiltIn ? Icons.star : Icons.person,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '基于: ${_selectedTemplate!.title}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '回向标题',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.title),
                      suffixIcon: _titleController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _titleController.clear();
                                });
                              },
                              icon: const Icon(Icons.clear, size: 18),
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _contentController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: '回向内容',
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 80),
                        child: Icon(Icons.text_fields),
                      ),
                      suffixIcon: _contentController.text.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 80),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _contentController.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 18),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('取消'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveDedication,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('保存回向'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _selectTemplate(DedicationTemplate? template) {
    setState(() {
      _selectedTemplate = template;
      if (template != null) {
        _titleController.text = template.title;
        _contentController.text = template.content;
      } else {
        // 如果选择"不使用模板"，清空输入框
        _titleController.clear();
        _contentController.clear();
      }
    });
  }

  Future<void> _saveDedication() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写回向标题和内容'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dedication = Dedication(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        chantingId: widget.chanting.id,
        createdAt: DateTime.now(),
      );

      await DatabaseService.instance.createDedication(dedication);

      if (mounted) {
        Navigator.of(context).pop(true); // 返回true表示成功保存
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('已为《${widget.chanting.title}》添加回向'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('保存回向失败: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

class EditDedicationDialogContent extends StatefulWidget {
  final Chanting chanting;
  final Dedication dedication;
  final List<DedicationTemplate> templates;

  const EditDedicationDialogContent({
    super.key,
    required this.chanting,
    required this.dedication,
    required this.templates,
  });

  @override
  State<EditDedicationDialogContent> createState() => _EditDedicationDialogContentState();
}

class _EditDedicationDialogContentState extends State<EditDedicationDialogContent> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  DedicationTemplate? _selectedTemplate;
  
  // 存储原始内容，用于"恢复原内容"功能
  late String _originalTitle;
  late String _originalContent;

  @override
  void initState() {
    super.initState();
    // 预填充现有回向文内容
    _originalTitle = widget.dedication.title;
    _originalContent = widget.dedication.content;
    _titleController.text = _originalTitle;
    _contentController.text = _originalContent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '编辑回向文',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '《${widget.chanting.title}》',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // 删除按钮
                IconButton(
                  onPressed: _confirmDelete,
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  tooltip: '删除回向',
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Templates section
                  if (widget.templates.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.bookmarks, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '使用模板重新填写',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // 模板下拉框
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DedicationTemplate>(
                          value: _selectedTemplate,
                          hint: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  '选择模板替换当前内容（可选）',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          isExpanded: true,
                          items: [
                            // 添加一个"恢复原内容"选项
                            const DropdownMenuItem<DedicationTemplate>(
                              value: null,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.restore, color: Colors.grey, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      '恢复原内容',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 模板选项
                            ...widget.templates.map((template) {
                              return DropdownMenuItem<DedicationTemplate>(
                                value: template,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        template.isBuiltIn ? Icons.star : Icons.person,
                                        size: 16,
                                        color: template.isBuiltIn 
                                            ? Colors.orange.shade600
                                            : Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              template.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (template.content.length > 20)
                                              Text(
                                                template.content.length > 50 
                                                    ? '${template.content.substring(0, 50)}...'
                                                    : template.content,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (DedicationTemplate? template) {
                            _selectTemplate(template);
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),
                  ],
                  
                  // Form section
                  Row(
                    children: [
                      Icon(Icons.edit, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedTemplate != null ? '基于模板编辑' : '编辑回向内容',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_selectedTemplate != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedTemplate!.isBuiltIn ? Icons.star : Icons.person,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '基于: ${_selectedTemplate!.title}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '回向标题',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.title),
                      suffixIcon: _titleController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                setState(() {
                                  _titleController.clear();
                                });
                              },
                              icon: const Icon(Icons.clear, size: 18),
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _contentController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: '回向内容',
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 80),
                        child: Icon(Icons.text_fields),
                      ),
                      suffixIcon: _contentController.text.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 80),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _contentController.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 18),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('取消'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateDedication,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('保存修改'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _selectTemplate(DedicationTemplate? template) {
    setState(() {
      _selectedTemplate = template;
      if (template != null) {
        _titleController.text = template.title;
        _contentController.text = template.content;
      } else {
        // 如果选择"恢复原内容"，恢复到原始内容
        _titleController.text = _originalTitle;
        _contentController.text = _originalContent;
      }
    });
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('确认删除'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('确定要删除这个回向文吗？'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.dedication.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.dedication.content,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteDedication();
    }
  }

  Future<void> _deleteDedication() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DatabaseService.instance.deleteDedication(widget.dedication.id!);

      if (mounted) {
        Navigator.of(context).pop(true); // 返回true表示需要刷新
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('回向文已删除'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('删除回向文失败: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateDedication() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写回向标题和内容'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedDedication = widget.dedication.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await DatabaseService.instance.updateDedication(updatedDedication);

      if (mounted) {
        Navigator.of(context).pop(true); // 返回true表示成功更新
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('回向文已更新'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('更新回向文失败: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
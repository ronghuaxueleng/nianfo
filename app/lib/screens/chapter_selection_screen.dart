import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/chapter.dart';
import '../models/reading_progress.dart';
import '../services/database_service.dart';
import 'chapter_reading_screen.dart';

class ChapterSelectionScreen extends StatefulWidget {
  final Chanting chanting;

  const ChapterSelectionScreen({
    super.key,
    required this.chanting,
  });

  @override
  State<ChapterSelectionScreen> createState() => _ChapterSelectionScreenState();
}

class _ChapterSelectionScreenState extends State<ChapterSelectionScreen> {
  List<Chapter> _chapters = [];
  Map<int, ReadingProgress> _progressMap = {};
  bool _isLoading = true;
  ReadingProgressSummary? _progressSummary;

  @override
  void initState() {
    super.initState();
    _loadChaptersAndProgress();
  }

  Future<void> _loadChaptersAndProgress() async {
    setState(() => _isLoading = true);
    
    try {
      if (widget.chanting.id != null) {
        // 加载章节列表
        final chapters = await DatabaseService.instance.getChaptersByChantingId(widget.chanting.id!);
        
        // 加载阅读进度
        final progressList = await DatabaseService.instance.getReadingProgress(widget.chanting.id!);
        final progressMap = <int, ReadingProgress>{};
        for (var progress in progressList) {
          if (progress.chapterId != null) {
            progressMap[progress.chapterId!] = progress;
          }
        }
        
        // 加载进度摘要
        final summary = await DatabaseService.instance.getReadingProgressSummary(widget.chanting.id!);
        
        setState(() {
          _chapters = chapters;
          _progressMap = progressMap;
          _progressSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载章节失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openChapter(Chapter chapter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterReadingScreen(
          chanting: widget.chanting,
          chapter: chapter,
        ),
      ),
    ).then((_) {
      // 返回时刷新进度
      _loadChaptersAndProgress();
    });
  }

  void _openFullChanting() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChapterReadingScreen(
          chanting: widget.chanting,
          chapter: null, // 不传chapter表示阅读整部经文
        ),
      ),
    ).then((_) {
      // 返回时刷新进度
      _loadChaptersAndProgress();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              widget.chanting.type == ChantingType.buddhaNam
                  ? Icons.self_improvement
                  : Icons.book,
              color: widget.chanting.type == ChantingType.buddhaNam
                  ? Colors.blue.shade600
                  : Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.chanting.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade100,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    '正在加载章节...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // 进度摘要卡片
                if (_progressSummary != null) _buildProgressSummaryCard(),

                // 阅读选项
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 整本经文选项
                      _buildFullChantingCard(),

                      const SizedBox(height: 16),

                      // 章节列表
                      if (_chapters.isNotEmpty) ...[
                        const Text(
                          '选择章节',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._chapters.map((chapter) => _buildChapterCard(chapter)),
                      ] else
                        _buildNoChaptersCard(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressSummaryCard() {
    final summary = _progressSummary!;
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.green.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.timeline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    '阅读进度',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '已完成 ${summary.completedChapters} / ${summary.totalChapters} 章',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  Text(
                    '${summary.progressPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullChantingCard() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _openFullChanting,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.orange.shade50, Colors.amber.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '阅读完整经文',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '连续阅读所有章节内容',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.orange,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterCard(Chapter chapter) {
    final progress = _progressMap[chapter.id];
    final isCompleted = progress?.isCompleted ?? false;
    final hasProgress = progress != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 1,
        child: InkWell(
          onTap: () => _openChapter(chapter),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 章节序号
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green.shade100 
                        : hasProgress 
                            ? Colors.blue.shade100 
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: isCompleted 
                        ? const Icon(Icons.check, color: Colors.green, size: 20)
                        : hasProgress 
                            ? Icon(Icons.bookmark, color: Colors.blue.shade600, size: 20)
                            : Text(
                                '${chapter.chapterNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 章节信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green.shade700 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '第${chapter.chapterNumber}章',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      if (hasProgress && progress!.lastReadAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '最后阅读: ${_formatDate(progress.lastReadAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 状态指示器
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoChaptersCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: const Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '此经文尚未分章节',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '请选择"阅读完整经文"来阅读全部内容',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return '今天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      final difference = today.difference(targetDate).inDays;
      if (difference == 1) {
        return '昨天 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference < 7) {
        return '$difference天前';
      } else {
        return '${date.month}-${date.day}';
      }
    }
  }
}
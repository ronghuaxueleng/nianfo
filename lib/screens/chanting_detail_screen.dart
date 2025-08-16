import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../services/database_service.dart';

class ChantingDetailScreen extends StatefulWidget {
  final Chanting chanting;
  final bool showChantingButton;

  const ChantingDetailScreen({
    super.key, 
    required this.chanting,
    this.showChantingButton = false,
  });

  @override
  State<ChantingDetailScreen> createState() => _ChantingDetailScreenState();
}

class _ChantingDetailScreenState extends State<ChantingDetailScreen> {
  int _todayCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayCount();
  }

  Future<void> _loadTodayCount() async {
    if (widget.chanting.id != null) {
      try {
        final count = await DatabaseService.instance.getTodayCount(widget.chanting.id!);
        setState(() {
          _todayCount = count;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _incrementCount() async {
    if (widget.chanting.id == null) return;
    
    final newCount = _todayCount + 1;
    
    try {
      await DatabaseService.instance.createOrUpdateDailyStats(widget.chanting.id!, newCount);
      setState(() {
        _todayCount = newCount;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.chanting.title} +1，今日已念 $newCount 次'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('更新计数失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        actions: [
          if (widget.showChantingButton && widget.chanting.id != null)
            IconButton(
              onPressed: _incrementCount,
              icon: const Icon(Icons.add_circle),
              tooltip: '念诵 +1',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题信息卡片
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
                    const SizedBox(height: 8),
                    Text(
                      '创建时间: ${_formatDate(widget.chanting.createdAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 今日计数卡片
            if (!_isLoading && widget.chanting.id != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '今日已念',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_todayCount 次',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.showChantingButton)
                        ElevatedButton.icon(
                          onPressed: _incrementCount,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('念诵 +1'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 内容显示卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '内容',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailContentWithPronunciation(),
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

  Widget _buildDetailContentWithPronunciation() {
    final contentLines = widget.chanting.content.split('\n');
    final pronunciationLines = widget.chanting.pronunciation?.split('\n') ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < contentLines.length; i++) ...[
          if (contentLines[i].trim().isNotEmpty) ...[
            _buildSelectableCharacterWithPronunciation(
              contentLines[i].trim(),
              i < pronunciationLines.length ? pronunciationLines[i].trim() : '',
              18, // 汉字字体大小 - 阅读页面用更大字体
              15, // 注音字体大小
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }

  // 构建字符级别对应的可选择文本显示
  Widget _buildSelectableCharacterWithPronunciation(
    String content, 
    String pronunciation, 
    double contentFontSize, 
    double pronunciationFontSize
  ) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    // 分离汉字和注音
    final contentChars = content.split('');
    final pronunciationChars = pronunciation.split(' ');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 汉字行 - 使用固定宽度的容器来确保对齐
        Wrap(
          children: contentChars.asMap().entries.map((entry) {
            final char = entry.value;
            return Container(
              width: 28, // 阅读页面使用更大的宽度
              child: SelectableText(
                char,
                style: TextStyle(
                  fontSize: contentFontSize,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // 注音行
        if (pronunciation.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            children: contentChars.asMap().entries.map((entry) {
              final index = entry.key;
              
              // 获取对应的注音
              String pinyin = '';
              if (index < pronunciationChars.length) {
                pinyin = pronunciationChars[index];
              }
              
              return Container(
                width: 28, // 与汉字相同的宽度
                child: SelectableText(
                  pinyin,
                  style: TextStyle(
                    fontSize: pronunciationFontSize,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
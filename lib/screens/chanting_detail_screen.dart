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
  double _fontSize = 18.0; // 默认字体大小
  double _pronunciationFontSize = 15.0; // 默认注音字体大小

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

  void _adjustFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(12.0, 28.0);
      _pronunciationFontSize = (_fontSize * 0.83).clamp(10.0, 24.0);
    });
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('调整字体大小'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('当前字体大小: ${_fontSize.toInt()}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _adjustFontSize(-2),
                  child: const Text('A-'),
                ),
                ElevatedButton(
                  onPressed: () => _adjustFontSize(2),
                  child: const Text('A+'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _fontSize = 18.0;
                  _pronunciationFontSize = 15.0;
                });
              },
              child: const Text('重置'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('完成'),
          ),
        ],
      ),
    );
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
          IconButton(
            onPressed: _showFontSizeDialog,
            icon: const Icon(Icons.text_fields),
            tooltip: '调整字体',
          ),
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
              _fontSize, // 使用可调整的字体大小
              _pronunciationFontSize, // 使用可调整的注音字体大小
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }

  // 使用表格布局显示汉字和注音的对应关系（正确的分行表格实现）
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
    
    // 动态分行，根据注音长度计算每行字符数
    List<Widget> tableRows = [];
    
    int currentIndex = 0;
    
    while (currentIndex < contentChars.length) {
      // 动态计算这一行能放多少个字符
      int lineLength = _calculateDynamicLineLength(
        contentChars, 
        pronunciationChars, 
        currentIndex, 
        contentFontSize, 
        pronunciationFontSize
      );
      
      int lineEnd = (currentIndex + lineLength).clamp(0, contentChars.length);
      
      // 当前行的字符
      List<String> lineChars = contentChars.sublist(currentIndex, lineEnd);
      
      // 构建当前行的表格（包含汉字行和注音行）
      List<TableRow> rows = [];
      
      // 汉字行
      rows.add(
        TableRow(
          children: lineChars.map((char) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
              child: SelectableText(
                char,
                style: TextStyle(
                  fontSize: contentFontSize,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                // 强制单行显示
              ),
            );
          }).toList(),
        ),
      );
      
      // 注音行（如果有注音）
      if (pronunciation.isNotEmpty) {
        rows.add(
          TableRow(
            children: lineChars.asMap().entries.map((entry) {
              final globalIndex = currentIndex + entry.key;
              
              // 获取对应的注音
              String pinyin = '';
              if (globalIndex < pronunciationChars.length) {
                pinyin = pronunciationChars[globalIndex];
              }
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
                child: SelectableText(
                  pinyin,
                  style: TextStyle(
                    fontSize: pronunciationFontSize,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  // 强制单行显示，溢出用省略号
                ),
              );
            }).toList(),
          ),
        );
      }
      
      // 创建当前行的表格
      Widget lineTable = Table(
        columnWidths: Map.fromIterable(
          List.generate(lineChars.length, (index) => index),
          key: (index) => index,
          value: (index) => const IntrinsicColumnWidth(), // 使用内容自适应宽度
        ),
        border: null,
        children: rows,
      );
      
      tableRows.add(lineTable);
      
      // 行间距
      if (lineEnd < contentChars.length) {
        tableRows.add(const SizedBox(height: 12));
      }
      
      currentIndex = lineEnd;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tableRows,
    );
  }

  // 动态计算每行能放多少个字符（根据注音长度）
  int _calculateDynamicLineLength(
    List<String> contentChars,
    List<String> pronunciationChars,
    int startIndex,
    double contentFontSize,
    double pronunciationFontSize
  ) {
    double screenWidth = MediaQuery.of(context).size.width;
    double availableWidth = screenWidth - 80; // 边距预留
    
    double currentWidth = 0;
    int charCount = 0;
    
    for (int i = startIndex; i < contentChars.length; i++) {
      // 估算汉字宽度
      double charWidth = contentFontSize + 2; // 汉字 + padding
      
      // 估算对应注音宽度
      double pinyinWidth = 0;
      if (i < pronunciationChars.length && pronunciationChars[i].isNotEmpty) {
        // 每个拼音字符约为字体大小的0.6倍宽度
        pinyinWidth = pronunciationChars[i].length * pronunciationFontSize * 0.6 + 2;
      }
      
      // 取汉字和注音宽度的最大值
      double columnWidth = charWidth > pinyinWidth ? charWidth : pinyinWidth;
      
      // 检查是否还能放下
      if (currentWidth + columnWidth > availableWidth && charCount > 0) {
        break;
      }
      
      currentWidth += columnWidth;
      charCount++;
      
      // 安全限制，避免行过长
      if (charCount >= 15) break;
    }
    
    // 确保至少有一个字符
    return charCount > 0 ? charCount : 1;
  }
  
  // 保留原有计算方法作为后备
  int _calculateMaxCharsPerLine(double fontSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    double availableWidth = screenWidth - 80;
    double charWidth = fontSize + 6;
    int maxChars = (availableWidth / charWidth).floor();
    return maxChars.clamp(6, 20);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
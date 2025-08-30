import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../services/database_service.dart';
import 'chapter_selection_screen.dart';

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
  bool _isContentLoading = true;
  bool _hasChapters = false;
  double _fontSize = 18.0; // 默认字体大小
  double _pronunciationFontSize = 15.0; // 默认注音字体大小

  @override
  void initState() {
    super.initState();
    _loadTodayCount();
    _loadContent();
    _checkChapters();
  }

  Future<void> _loadContent() async {
    // 模拟内容加载过程，根据经文长度调整加载时间
    final contentLength = widget.chanting.content.length;
    int loadingTime = 200; // 基础加载时间200ms
    
    // 根据内容长度增加加载时间，每1000字符增加100ms
    if (contentLength > 1000) {
      loadingTime += ((contentLength / 1000) * 100).round();
    }
    
    // 最大加载时间1.5秒
    loadingTime = loadingTime.clamp(200, 1500);
    
    await Future.delayed(Duration(milliseconds: loadingTime));
    
    if (mounted) {
      setState(() {
        _isContentLoading = false;
      });
    }
  }

  Future<void> _checkChapters() async {
    if (widget.chanting.id != null && widget.chanting.type == ChantingType.sutra) {
      try {
        final chapters = await DatabaseService.instance.getChaptersByChantingId(widget.chanting.id!);
        setState(() {
          _hasChapters = chapters.isNotEmpty;
        });
      } catch (e) {
        // 如果加载失败，假设没有章节
        setState(() {
          _hasChapters = false;
        });
      }
    }
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
      
      // 移除了弹出提示框，计数已更新到数据库
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
          if (_hasChapters)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChapterSelectionScreen(chanting: widget.chanting),
                  ),
                );
              },
              icon: const Icon(Icons.list),
              tooltip: '选择章节',
            ),
          if (widget.showChantingButton && widget.chanting.id != null)
            IconButton(
              onPressed: _incrementCount,
              icon: const Icon(Icons.add_circle),
              tooltip: '念诵 +1',
            ),
        ],
      ),
      body: Column(
        children: [
          // 章节信息卡片
          if (_hasChapters) _buildChapterInfoCard(),

          // 可滚动的内容区域
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _isContentLoading 
                        ? _buildLoadingWidget()
                        : _buildLazyContentList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          Text(
            '正在加载经文内容...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLazyContentList() {
    final allContentLines = widget.chanting.content.split('\n');
    final pronunciationLines = widget.chanting.pronunciation?.split('\n') ?? [];
    
    // 保持原始索引对应关系，只过滤显示时的空行
    final nonEmptyItems = <MapEntry<int, String>>[];
    for (int i = 0; i < allContentLines.length; i++) {
      if (allContentLines[i].trim().isNotEmpty) {
        nonEmptyItems.add(MapEntry(i, allContentLines[i].trim()));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: nonEmptyItems.length,
      itemBuilder: (context, index) {
        final item = nonEmptyItems[index];
        final originalIndex = item.key;
        final content = item.value;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSelectableCharacterWithPronunciation(
            content,
            originalIndex < pronunciationLines.length ? pronunciationLines[originalIndex].trim() : '',
            _fontSize,
            _pronunciationFontSize,
          ),
        );
      },
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

  // 优化的字符渲染方法 - 使用简化的固定分行
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
    
    // 使用固定的字符数分行以提高性能
    final charsPerLine = _getFixedCharsPerLine();
    List<Widget> lineWidgets = [];
    
    for (int startIndex = 0; startIndex < contentChars.length; startIndex += charsPerLine) {
      final endIndex = (startIndex + charsPerLine).clamp(0, contentChars.length);
      final lineChars = contentChars.sublist(startIndex, endIndex);
      
      // 构建当前行
      lineWidgets.add(_buildLineWidget(
        lineChars, 
        pronunciationChars, 
        startIndex, 
        contentFontSize, 
        pronunciationFontSize,
        pronunciation.isNotEmpty,
      ));
      
      if (endIndex < contentChars.length) {
        lineWidgets.add(const SizedBox(height: 12));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lineWidgets,
    );
  }

  // 构建单行内容
  Widget _buildLineWidget(
    List<String> lineChars,
    List<String> pronunciationChars,
    int startIndex,
    double contentFontSize,
    double pronunciationFontSize,
    bool hasPronunciation,
  ) {
    List<TableRow> rows = [];
    
    // 注音行（放在汉字上方）
    if (hasPronunciation) {
      rows.add(
        TableRow(
          children: lineChars.asMap().entries.map((entry) {
            final globalIndex = startIndex + entry.key;
            final pinyin = globalIndex < pronunciationChars.length 
                ? pronunciationChars[globalIndex] 
                : '';
            
            return Container(
              padding: const EdgeInsets.fromLTRB(1, 2, 1, 7),
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
              ),
            );
          }).toList(),
        ),
      );
    }
    
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
            ),
          );
        }).toList(),
      ),
    );
    
    return Table(
      columnWidths: Map.fromIterable(
        List.generate(lineChars.length, (index) => index),
        key: (index) => index,
        value: (index) => const IntrinsicColumnWidth(),
      ),
      border: null,
      children: rows,
    );
  }

  // 获取固定的每行字符数（考虑注音宽度）
  int _getFixedCharsPerLine() {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 80;
    
    // 考虑汉字和注音的宽度，注音通常比汉字更宽
    final estimatedCharWidth = _fontSize + 10; // 增加宽度预留，确保注音显示完全
    final maxChars = (availableWidth / estimatedCharWidth).floor();
    
    // 调整字符数范围，减少每行字符数以确保注音显示完全
    return maxChars.clamp(6, 12);
  }


  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildChapterInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChapterSelectionScreen(chanting: widget.chanting),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: Colors.purple.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '此经文有章节分割',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '点击选择章节阅读，追踪学习进度',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        '选择章节',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
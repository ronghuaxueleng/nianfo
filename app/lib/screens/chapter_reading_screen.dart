import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/chapter.dart';
import '../models/reading_progress.dart';
import '../services/database_service.dart';

class ChapterReadingScreen extends StatefulWidget {
  final Chanting chanting;
  final Chapter? chapter; // null表示阅读整部经文

  const ChapterReadingScreen({
    super.key,
    required this.chanting,
    this.chapter,
  });

  @override
  State<ChapterReadingScreen> createState() => _ChapterReadingScreenState();
}

class _ChapterReadingScreenState extends State<ChapterReadingScreen> {
  ReadingProgress? _progress;
  bool _isLoading = true;
  bool _isContentLoading = true;
  double _fontSize = 18.0;
  double _pronunciationFontSize = 15.0;
  final ScrollController _scrollController = ScrollController();
  String _notes = '';
  bool _isCompleted = false;

  // 阅读内容相关
  String get _content => widget.chapter?.content ?? widget.chanting.content;
  String get _pronunciation => widget.chapter?.pronunciation ?? widget.chanting.pronunciation ?? '';
  String get _title => widget.chapter?.title ?? widget.chanting.title;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final contentLength = _content.length;
    int loadingTime = 200;
    
    if (contentLength > 1000) {
      loadingTime += ((contentLength / 1000) * 100).round();
    }
    
    loadingTime = loadingTime.clamp(200, 1500);
    
    await Future.delayed(Duration(milliseconds: loadingTime));
    
    if (mounted) {
      setState(() {
        _isContentLoading = false;
      });
    }
  }

  Future<void> _loadProgress() async {
    if (widget.chanting.id == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final progress = await DatabaseService.instance.getOrCreateReadingProgress(
        widget.chanting.id!,
        widget.chapter?.id,
      );
      
      setState(() {
        _progress = progress;
        _isCompleted = progress?.isCompleted ?? false;
        _notes = progress?.notes ?? '';
        _isLoading = false;
      });
      
      // 恢复阅读位置
      if (progress != null && progress.readingPosition > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToPosition(progress.readingPosition.toDouble());
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_progress != null && _scrollController.hasClients) {
      final position = _scrollController.offset;
      _updateReadingProgress(position: position.toInt());
    }
  }

  void _scrollToPosition(double position) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _updateReadingProgress({
    bool? isCompleted,
    int? position,
    String? notes,
    bool showMessage = false,
  }) async {
    if (_progress == null || widget.chanting.id == null) return;

    try {
      final updatedProgress = await DatabaseService.instance.updateReadingProgress(
        widget.chanting.id!,
        widget.chapter?.id,
        isCompleted: isCompleted ?? _progress!.isCompleted,
        readingPosition: position ?? _progress!.readingPosition,
        notes: notes ?? _progress!.notes,
      );

      setState(() {
        _progress = updatedProgress;
        if (isCompleted != null) _isCompleted = isCompleted;
        if (notes != null) _notes = notes;
      });

      if (showMessage && isCompleted == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已标记为完成！'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新进度失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _showNotesDialog() {
    final notesController = TextEditingController(text: _notes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('阅读笔记'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: '在这里记录您的感想...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _updateReadingProgress(notes: notesController.text);
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _toggleCompletion() {
    final newCompleted = !_isCompleted;
    _updateReadingProgress(isCompleted: newCompleted, showMessage: newCompleted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              widget.chapter != null ? Icons.bookmark : Icons.menu_book,
              color: _isCompleted ? Colors.green.shade600 : Colors.blue.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _title,
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
          IconButton(
            onPressed: _showNotesDialog,
            icon: Icon(
              Icons.note_add,
              color: _notes.isNotEmpty ? Colors.orange : null,
            ),
            tooltip: '添加笔记',
          ),
          IconButton(
            onPressed: _toggleCompletion,
            icon: Icon(
              _isCompleted ? Icons.check_circle : Icons.check_circle_outline,
              color: _isCompleted ? Colors.green : null,
            ),
            tooltip: _isCompleted ? '标记未完成' : '标记完成',
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度指示器
          if (_progress != null && widget.chapter != null) _buildProgressIndicator(),

          // 可滚动内容区域
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: _isLoading
                  ? _buildLoadingWidget()
                  : _isContentLoading
                      ? _buildContentLoadingWidget()
                      : _buildContentArea(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: _isCompleted ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            _isCompleted ? '已完成' : '进行中',
            style: TextStyle(
              color: _isCompleted ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_notes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note, size: 14, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    '有笔记',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
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
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text(
            '正在加载阅读进度...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContentLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text(
            '正在加载内容...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildLazyContentList()),
      ],
    );
  }

  Widget _buildLazyContentList() {
    final allContentLines = _content.split('\n');
    final pronunciationLines = _pronunciation.split('\n');
    
    final nonEmptyItems = <MapEntry<int, String>>[];
    for (int i = 0; i < allContentLines.length; i++) {
      if (allContentLines[i].trim().isNotEmpty) {
        nonEmptyItems.add(MapEntry(i, allContentLines[i].trim()));
      }
    }

    return ListView.builder(
      controller: _scrollController,
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
            originalIndex < pronunciationLines.length 
                ? pronunciationLines[originalIndex].trim() 
                : '',
            _fontSize,
            _pronunciationFontSize,
          ),
        );
      },
    );
  }

  Widget _buildSelectableCharacterWithPronunciation(
    String content,
    String pronunciation,
    double contentFontSize,
    double pronunciationFontSize,
  ) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    final contentChars = content.split('');
    final pronunciationChars = pronunciation.split(' ');
    
    final charsPerLine = _getFixedCharsPerLine();
    List<Widget> lineWidgets = [];
    
    for (int startIndex = 0; startIndex < contentChars.length; startIndex += charsPerLine) {
      final endIndex = (startIndex + charsPerLine).clamp(0, contentChars.length);
      final lineChars = contentChars.sublist(startIndex, endIndex);
      
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

  Widget _buildLineWidget(
    List<String> lineChars,
    List<String> pronunciationChars,
    int startIndex,
    double contentFontSize,
    double pronunciationFontSize,
    bool hasPronunciation,
  ) {
    List<TableRow> rows = [];
    
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

  int _getFixedCharsPerLine() {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 80;
    final estimatedCharWidth = _fontSize + 10;
    final maxChars = (availableWidth / estimatedCharWidth).floor();
    return maxChars.clamp(6, 12);
  }
}
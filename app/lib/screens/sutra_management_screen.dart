import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/chanting_record.dart';
import '../models/chapter.dart';
import '../services/database_service.dart';
import 'chanting_detail_screen.dart';
import 'chanting_statistics_screen.dart';
import 'chapter_selection_screen.dart';

class SutraManagementScreen extends StatefulWidget {
  const SutraManagementScreen({super.key});

  @override
  State<SutraManagementScreen> createState() => _SutraManagementScreenState();
}

class _SutraManagementScreenState extends State<SutraManagementScreen> {
  List<Chanting> _sutras = [];
  List<ChantingRecordWithDetails> _allRecords = [];
  Map<int, List<Chapter>> _chaptersMap = {};
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showBuiltInOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sutras = await DatabaseService.instance.getChantingsByType(ChantingType.sutra);
      final allRecords = await DatabaseService.instance.getChantingRecordsWithDetails();
      
      // 加载每部经文的章节信息
      final chaptersMap = <int, List<Chapter>>{};
      for (final sutra in sutras) {
        if (sutra.id != null) {
          final chapters = await DatabaseService.instance.getChaptersByChantingId(sutra.id!);
          if (chapters.isNotEmpty) {
            chaptersMap[sutra.id!] = chapters;
          }
        }
      }
      
      setState(() {
        _sutras = sutras;
        _allRecords = allRecords.where((record) => record.chanting.type == ChantingType.sutra).toList();
        _chaptersMap = chaptersMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Chanting> get _filteredSutras {
    var filtered = _sutras;
    
    if (_showBuiltInOnly) {
      filtered = filtered.where((chanting) => chanting.isBuiltIn).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((chanting) => 
        chanting.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        chanting.content.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }

  Future<void> _addToRecords(Chanting sutra) async {
    if (sutra.id == null) return;

    try {
      await DatabaseService.instance.createChantingRecord(sutra.id!);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已将 "${sutra.title}" 添加到修行记录'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '查看',
              textColor: Colors.white,
              onPressed: () {
                _openSutra(sutra);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openSutra(Chanting sutra) {
    final hasChapters = _chaptersMap.containsKey(sutra.id);
    
    if (hasChapters) {
      // 有章节，打开章节选择界面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChapterSelectionScreen(chanting: sutra),
        ),
      );
    } else {
      // 无章节，直接打开经文详情
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChantingDetailScreen(
            chanting: sutra,
            showChantingButton: _allRecords.any((record) => record.chanting.id == sutra.id),
          ),
        ),
      );
    }
  }

  void _showAddSutraDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final pronunciationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自定义经文'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '经文名称',
                  hintText: '如：般若波罗蜜多心经',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '经文内容',
                  hintText: '完整的经文内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pronunciationController,
                decoration: const InputDecoration(
                  labelText: '注音（可选）',
                  hintText: '拼音注音',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty || 
                  contentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('经文名称和内容不能为空'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final newSutra = Chanting(
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  pronunciation: pronunciationController.text.trim().isNotEmpty 
                    ? pronunciationController.text.trim() 
                    : null,
                  type: ChantingType.sutra,
                  isBuiltIn: false,
                  createdAt: DateTime.now(),
                );

                await DatabaseService.instance.createChanting(newSutra);
                await _loadData();
                
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('经文添加成功'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('添加失败: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('经文管理'),
        backgroundColor: Colors.green.shade100,
        actions: [
          IconButton(
            onPressed: _showAddSutraDialog,
            icon: const Icon(Icons.add),
            tooltip: '添加自定义经文',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索和筛选栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: '搜索经文...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('仅显示内置'),
                      selected: _showBuiltInOnly,
                      onSelected: (selected) {
                        setState(() {
                          _showBuiltInOnly = selected;
                        });
                      },
                      selectedColor: Colors.green.shade200,
                    ),
                    const Spacer(),
                    Text(
                      '共 ${_filteredSutras.length} 部经文',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 经文列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSutras.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSutras.length,
                        itemBuilder: (context, index) {
                          final sutra = _filteredSutras[index];
                          final isInRecords = _allRecords.any((record) => record.chanting.id == sutra.id);
                          final hasChapters = _chaptersMap.containsKey(sutra.id);
                          
                          return _buildSutraCard(sutra, isInRecords, hasChapters);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 64,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '未找到匹配的经文' : '暂无经文',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ? '尝试调整搜索关键词' : '点击右上角添加自定义经文',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Text('清除搜索'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSutraCard(Chanting sutra, bool isInRecords, bool hasChapters) {
    final chapterCount = _chaptersMap[sutra.id]?.length ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => _openSutra(sutra),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        hasChapters ? Icons.menu_book : Icons.book,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sutra.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (sutra.isBuiltIn) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '内置',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (hasChapters) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$chapterCount章',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (isInRecords) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '已添加',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: () => _openSutra(sutra),
                          child: Row(
                            children: [
                              Icon(hasChapters ? Icons.list : Icons.visibility, size: 18),
                              const SizedBox(width: 8),
                              Text(hasChapters ? '选择章节' : '查看详情'),
                            ],
                          ),
                        ),
                        if (!isInRecords)
                          PopupMenuItem(
                            onTap: () => _addToRecords(sutra),
                            child: const Row(
                              children: [
                                Icon(Icons.add_circle, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text('添加到记录'),
                              ],
                            ),
                          ),
                        if (isInRecords) ...[
                          PopupMenuItem(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChantingStatisticsScreen(chanting: sutra),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.bar_chart, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('查看统计'),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  sutra.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: hasChapters ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasChapters) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark, size: 14, color: Colors.purple.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '共$chapterCount章，点击选择章节阅读',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (sutra.pronunciation?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    sutra.pronunciation!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
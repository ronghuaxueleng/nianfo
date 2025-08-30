import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/chanting_record.dart';
import '../services/database_service.dart';
import 'chanting_detail_screen.dart';
import 'chanting_statistics_screen.dart';

class BuddhaNamManagementScreen extends StatefulWidget {
  const BuddhaNamManagementScreen({super.key});

  @override
  State<BuddhaNamManagementScreen> createState() => _BuddhaNamManagementScreenState();
}

class _BuddhaNamManagementScreenState extends State<BuddhaNamManagementScreen> {
  List<Chanting> _buddhaNames = [];
  List<ChantingRecordWithDetails> _allRecords = [];
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
      final buddhaNames = await DatabaseService.instance.getChantingsByType(ChantingType.buddhaNam);
      final allRecords = await DatabaseService.instance.getChantingRecordsWithDetails();
      
      setState(() {
        _buddhaNames = buddhaNames;
        _allRecords = allRecords.where((record) => record.chanting.type == ChantingType.buddhaNam).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Chanting> get _filteredBuddhaNames {
    var filtered = _buddhaNames;
    
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

  Future<void> _addToRecords(Chanting chanting) async {
    if (chanting.id == null) return;

    try {
      await DatabaseService.instance.createChantingRecord(chanting.id!);
      await _loadData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已将 "${chanting.title}" 添加到修行记录'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '查看',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChantingDetailScreen(
                      chanting: chanting,
                      showChantingButton: true,
                    ),
                  ),
                );
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

  void _showAddBuddhaNamDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final pronunciationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自定义佛号'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '佛号名称',
                  hintText: '如：南无药师琉璃光如来',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '佛号内容',
                  hintText: '完整的佛号内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pronunciationController,
                decoration: const InputDecoration(
                  labelText: '注音（可选）',
                  hintText: '拼音注音',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
                    content: Text('佛号名称和内容不能为空'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final newBuddhaNam = Chanting(
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  pronunciation: pronunciationController.text.trim().isNotEmpty 
                    ? pronunciationController.text.trim() 
                    : null,
                  type: ChantingType.buddhaNam,
                  isBuiltIn: false,
                  createdAt: DateTime.now(),
                );

                await DatabaseService.instance.createChanting(newBuddhaNam);
                await _loadData();
                
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('佛号添加成功'),
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
        title: const Text('佛号管理'),
        backgroundColor: Colors.blue.shade100,
        actions: [
          IconButton(
            onPressed: _showAddBuddhaNamDialog,
            icon: const Icon(Icons.add),
            tooltip: '添加自定义佛号',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索和筛选栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: '搜索佛号...',
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
                      selectedColor: Colors.blue.shade200,
                    ),
                    const Spacer(),
                    Text(
                      '共 ${_filteredBuddhaNames.length} 个佛号',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 佛号列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBuddhaNames.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredBuddhaNames.length,
                        itemBuilder: (context, index) {
                          final buddhaNam = _filteredBuddhaNames[index];
                          final isInRecords = _allRecords.any((record) => record.chanting.id == buddhaNam.id);
                          
                          return _buildBuddhaNamCard(buddhaNam, isInRecords);
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
            Icons.self_improvement,
            size: 64,
            color: Colors.blue.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '未找到匹配的佛号' : '暂无佛号',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ? '尝试调整搜索关键词' : '点击右上角添加自定义佛号',
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

  Widget _buildBuddhaNamCard(Chanting buddhaNam, bool isInRecords) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChantingDetailScreen(
                  chanting: buddhaNam,
                  showChantingButton: isInRecords,
                ),
              ),
            );
          },
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
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.self_improvement,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buddhaNam.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (buddhaNam.isBuiltIn) ...[
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChantingDetailScreen(
                                  chanting: buddhaNam,
                                  showChantingButton: isInRecords,
                                ),
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.visibility, size: 18),
                              SizedBox(width: 8),
                              Text('查看详情'),
                            ],
                          ),
                        ),
                        if (!isInRecords)
                          PopupMenuItem(
                            onTap: () => _addToRecords(buddhaNam),
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
                                  builder: (context) => ChantingStatisticsScreen(chanting: buddhaNam),
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
                  buddhaNam.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (buddhaNam.pronunciation?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    buddhaNam.pronunciation!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
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
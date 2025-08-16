import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/daily_stats.dart';
import '../services/database_service.dart';
import '../widgets/chanting_form.dart';

class ChantingScreen extends StatefulWidget {
  const ChantingScreen({super.key});

  @override
  State<ChantingScreen> createState() => _ChantingScreenState();
}

class _ChantingScreenState extends State<ChantingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Chanting> _buddhaNams = [];
  List<Chanting> _sutras = [];
  Map<int, int> _todayCounts = {}; // 今日计数缓存
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadChantings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChantings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final buddhaNams = await DatabaseService.instance
          .getChantingsByType(ChantingType.buddhaNam);
      final sutras = await DatabaseService.instance
          .getChantingsByType(ChantingType.sutra);

      // 加载今日计数
      final Map<int, int> todayCounts = {};
      for (final chanting in [...buddhaNams, ...sutras]) {
        if (chanting.id != null) {
          final count = await DatabaseService.instance.getTodayCount(chanting.id!);
          todayCounts[chanting.id!] = count;
        }
      }

      setState(() {
        _buddhaNams = buddhaNams;
        _sutras = sutras;
        _todayCounts = todayCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showChantingForm({Chanting? chanting, ChantingType? type}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ChantingForm(
        chanting: chanting,
        defaultType: type ?? ChantingType.buddhaNam,
      ),
    );

    if (result == true) {
      _loadChantings();
    }
  }

  Future<void> _deleteChanting(Chanting chanting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${chanting.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true && chanting.id != null) {
      // 内置经文不能删除
      if (chanting.isBuiltIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('内置经文不能删除'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      await DatabaseService.instance.deleteChanting(chanting.id!);
      _loadChantings();
    }
  }

  Future<void> _incrementCount(Chanting chanting) async {
    if (chanting.id == null) return;
    
    final currentCount = _todayCounts[chanting.id!] ?? 0;
    final newCount = currentCount + 1;
    
    try {
      await DatabaseService.instance.createOrUpdateDailyStats(chanting.id!, newCount);
      setState(() {
        _todayCounts[chanting.id!] = newCount;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${chanting.title} +1，今日已念 $newCount 次'),
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

  Future<void> _showCountDialog(Chanting chanting) async {
    if (chanting.id == null) return;
    
    final controller = TextEditingController(
      text: (_todayCounts[chanting.id!] ?? 0).toString(),
    );
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('设置今日${chanting.title}次数'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '念诵次数',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final count = int.tryParse(controller.text) ?? 0;
              Navigator.of(context).pop(count);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (result != null && result >= 0) {
      try {
        await DatabaseService.instance.createOrUpdateDailyStats(chanting.id!, result);
        setState(() {
          _todayCounts[chanting.id!] = result;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新计数失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('佛号经文'),
        backgroundColor: Colors.orange.shade100,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '佛号'),
            Tab(text: '经文'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChantingList(_buddhaNams, ChantingType.buddhaNam),
                _buildChantingList(_sutras, ChantingType.sutra),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final currentType = _tabController.index == 0
              ? ChantingType.buddhaNam
              : ChantingType.sutra;
          _showChantingForm(type: currentType);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChantingList(List<Chanting> chantings, ChantingType type) {
    if (chantings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == ChantingType.buddhaNam
                  ? Icons.self_improvement
                  : Icons.book,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              type == ChantingType.buddhaNam ? '还没有佛号' : '还没有经文',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击右下角按钮添加',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chantings.length,
      itemBuilder: (context, index) {
        final chanting = chantings[index];
        final todayCount = _todayCounts[chanting.id] ?? 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              ListTile(
                leading: Stack(
                  children: [
                    Icon(
                      chanting.type == ChantingType.buddhaNam
                          ? Icons.self_improvement
                          : Icons.book,
                      color: Colors.orange,
                      size: 32,
                    ),
                    if (chanting.isBuiltIn)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        chanting.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '今日 $todayCount 次',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      chanting.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (chanting.pronunciation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '注音: ${chanting.pronunciation}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (chanting.isBuiltIn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '内置',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (chanting.isBuiltIn) const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '创建时间: ${_formatDate(chanting.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showChantingForm(chanting: chanting);
                    } else if (value == 'delete') {
                      _deleteChanting(chanting);
                    } else if (value == 'count') {
                      _showCountDialog(chanting);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'count',
                      child: Text('设置次数'),
                    ),
                    if (!chanting.isBuiltIn) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('编辑'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('删除'),
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  _showChantingDetails(chanting);
                },
              ),
              // 计数按钮区域
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _incrementCount(chanting),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('念诵 +1'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => _showCountDialog(chanting),
                      child: Text('设置: $todayCount'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showChantingDetails(Chanting chanting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Stack(
              children: [
                Icon(
                  chanting.type == ChantingType.buddhaNam
                      ? Icons.self_improvement
                      : Icons.book,
                  color: Colors.orange,
                ),
                if (chanting.isBuiltIn)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(chanting.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 内容
              Text(
                '内容：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                chanting.content,
                style: const TextStyle(fontSize: 16),
              ),
              
              // 注音
              if (chanting.pronunciation != null) ...[
                const SizedBox(height: 16),
                Text(
                  '注音：',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  chanting.pronunciation!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              // 今日计数
              if (chanting.id != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '今日已念',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_todayCounts[chanting.id!] ?? 0} 次',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (chanting.id != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _incrementCount(chanting);
              },
              icon: const Icon(Icons.add),
              label: const Text('念诵 +1'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
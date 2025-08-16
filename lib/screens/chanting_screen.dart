import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/daily_stats.dart';
import '../services/database_service.dart';

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

  Future<void> _showQuickSelectDialog() async {
    // 获取所有佛号经文（包括内置和用户创建的）
    final allChantings = await DatabaseService.instance.getAllChantings();
    final currentType = _tabController.index == 0 
        ? ChantingType.buddhaNam 
        : ChantingType.sutra;
    
    // 过滤出当前类型的经文
    final filteredChantings = allChantings
        .where((c) => c.type == currentType)
        .toList();
    
    if (filteredChantings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('还没有${currentType == ChantingType.buddhaNam ? '佛号' : '经文'}，请先在个人中心添加'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  currentType == ChantingType.buddhaNam 
                      ? Icons.self_improvement 
                      : Icons.book,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '选择${currentType == ChantingType.buddhaNam ? '佛号' : '经文'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredChantings.length,
                itemBuilder: (context, index) {
                  final chanting = filteredChantings[index];
                  final todayCount = _todayCounts[chanting.id] ?? 0;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          Icon(
                            currentType == ChantingType.buddhaNam 
                                ? Icons.self_improvement 
                                : Icons.book,
                            color: chanting.isBuiltIn 
                                ? Colors.orange.shade600 
                                : Colors.blue.shade600,
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
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              chanting.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '今日 $todayCount',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chanting.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (chanting.pronunciation != null)
                            Text(
                              '注音: ${chanting.pronunciation}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (chanting.isBuiltIn)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '内置',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(Icons.add_circle_outline, color: Colors.orange.shade600),
                        ],
                      ),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _incrementCount(chanting);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('念诵记录'),
        backgroundColor: Colors.orange.shade100,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '佛号'),
            Tab(text: '经文'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('功能说明'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('💙 快速选择念诵'),
                      SizedBox(height: 8),
                      Text('  从所有佛号经文中快速选择并念诵+1'),
                      SizedBox(height: 12),
                      Text('💡 使用说明：'),
                      SizedBox(height: 4),
                      Text('  • 点击右下角蓝色按钮快速选择念诵'),
                      Text('  • 在个人中心"佛号经文管理"添加新内容'),
                      Text('  • 点击列表中的"念诵+1"按钮记录'),
                      Text('  • 点击标题查看详细内容和注音'),
                      Text('  • 支持设置每日念诵次数'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.help_outline),
            tooltip: '功能说明',
          ),
        ],
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
      floatingActionButton: Tooltip(
        message: '快速选择念诵',
        child: FloatingActionButton(
          onPressed: _showQuickSelectDialog,
          backgroundColor: Colors.blue.shade600,
          child: const Icon(Icons.library_add, color: Colors.white),
        ),
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
                    if (value == 'count') {
                      _showCountDialog(chanting);
                    } else if (value == 'manage') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请到个人中心 > 佛号经文管理进行编辑和删除操作'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'count',
                      child: Text('设置次数'),
                    ),
                    const PopupMenuItem(
                      value: 'manage',
                      child: Text('管理内容'),
                    ),
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
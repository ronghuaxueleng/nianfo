import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/daily_stats.dart';
import '../services/database_service.dart';
import 'chanting_detail_screen.dart';

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
                      title: Text(
                        chanting.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: _buildQuickSelectContent(chanting),
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
                title: Text(
                  chanting.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _buildContentWithPronunciation(chanting),
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
                      child: const Text('设置次数'),
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

  Widget _buildContentWithPronunciation(Chanting chanting) {
    // 将内容和注音按行分割
    final contentLines = chanting.content.split('\n');
    final pronunciationLines = chanting.pronunciation?.split('\n') ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示内容，最多3行
        for (int i = 0; i < contentLines.length && i < 3; i++) ...[
          if (contentLines[i].trim().isNotEmpty) ...[
            _buildCharacterWithPronunciation(
              contentLines[i].trim(),
              i < pronunciationLines.length ? pronunciationLines[i].trim() : '',
              14, // 汉字字体大小
              12, // 注音字体大小
            ),
            const SizedBox(height: 4),
          ],
        ],
        // 如果内容被截断，显示省略号
        if (contentLines.length > 3)
          Text(
            '...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
      ],
    );
  }


  Widget _buildQuickSelectContent(Chanting chanting) {
    // 将内容按行分割，只显示第一行
    final contentLines = chanting.content.split('\n');
    final pronunciationLines = chanting.pronunciation?.split('\n') ?? [];
    
    if (contentLines.isEmpty) return const SizedBox.shrink();
    
    final firstContentLine = contentLines[0].trim();
    final firstPronunciationLine = pronunciationLines.isNotEmpty 
        ? pronunciationLines[0].trim() 
        : '';
    
    return _buildCharacterWithPronunciation(
      firstContentLine,
      firstPronunciationLine,
      13, // 汉字字体大小
      11, // 注音字体大小
    );
  }

  // 构建字符级别对应的普通文本显示（使用正确的表格布局）
  Widget _buildCharacterWithPronunciation(
    String content, 
    String pronunciation, 
    double contentFontSize, 
    double pronunciationFontSize,
    {int? maxLength}
  ) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    // 分离汉字和注音
    final contentChars = content.split('');
    final pronunciationChars = pronunciation.split(' ');
    
    // 计算显示长度，列表视图需要限制显示长度
    int displayLength = maxLength ?? _calculateMaxCharsForListDisplay(contentFontSize);
    
    // 如果内容过长，截取
    List<String> displayChars = contentChars.take(displayLength).toList();
    
    // 如果被截取了，添加省略号
    if (contentChars.length > displayLength) {
      displayChars.add('...');
    }
    
    // 创建表格
    List<TableRow> rows = [];
    
    // 汉字行
    rows.add(
      TableRow(
        children: displayChars.map((char) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            child: Text(
              char,
              style: TextStyle(fontSize: contentFontSize),
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
    
    // 注音行（如果有注音）
    if (pronunciation.isNotEmpty) {
      rows.add(
        TableRow(
          children: displayChars.asMap().entries.map((entry) {
            final index = entry.key;
            final char = entry.value;
            
            // 省略号不显示注音
            if (char == '...') {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: const Text('', textAlign: TextAlign.center),
              );
            }
            
            // 获取对应的注音
            String pinyin = '';
            if (index < pronunciationChars.length) {
              pinyin = pronunciationChars[index];
            }
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              child: Text(
                pinyin,
                style: TextStyle(
                  fontSize: pronunciationFontSize,
                  color: Colors.blue.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      );
    }
    
    return Table(
      columnWidths: Map.fromIterable(
        List.generate(displayChars.length, (index) => index),
        key: (index) => index,
        value: (index) => const FlexColumnWidth(1.0), // 使用等宽列避免溢出
      ),
      border: null,
      children: rows,
    );
  }

  // 计算列表视图中最大显示字符数
  int _calculateMaxCharsForListDisplay(double fontSize) {
    // 获取屏幕宽度
    double screenWidth = MediaQuery.of(context).size.width;
    // 减去各种padding和margin（列表卡片有更多的间距）
    double availableWidth = screenWidth - 160; // 增加边距预留
    // 估算每个字符的宽度
    double charWidth = fontSize + 6; // 更准确的字符宽度估算
    // 计算最大字符数
    int maxChars = (availableWidth / charWidth).floor();
    // 列表视图限制更严格，避免过宽
    return maxChars.clamp(3, 8);
  }


  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showChantingDetails(Chanting chanting) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChantingDetailScreen(
          chanting: chanting,
          showChantingButton: true,
        ),
      ),
    ).then((_) {
      // 从详情页面返回后重新加载计数，以防在详情页面有更新
      _loadChantings();
    });
  }
}
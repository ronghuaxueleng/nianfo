import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../models/chanting_record.dart';
import '../models/daily_stats.dart';
import '../services/database_service.dart';
import 'chanting_detail_screen.dart';
import 'chanting_statistics_screen.dart';

class ChantingScreen extends StatefulWidget {
  const ChantingScreen({super.key});

  @override
  State<ChantingScreen> createState() => _ChantingScreenState();
}

class _ChantingScreenState extends State<ChantingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChantingRecordWithDetails> _buddhaNameRecords = [];
  List<ChantingRecordWithDetails> _sutraRecords = [];
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
      final buddhaNameRecords = await DatabaseService.instance
          .getChantingRecordsByType(ChantingType.buddhaNam);
      final sutraRecords = await DatabaseService.instance
          .getChantingRecordsByType(ChantingType.sutra);

      // 加载今日计数
      final Map<int, int> todayCounts = {};
      for (final record in [...buddhaNameRecords, ...sutraRecords]) {
        final chantingId = record.chanting.id!;
        final count = await DatabaseService.instance.getTodayCount(chantingId);
        todayCounts[chantingId] = count;
      }

      setState(() {
        _buddhaNameRecords = buddhaNameRecords;
        _sutraRecords = sutraRecords;
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
      
      // 移除了弹出提示框，直接更新右上角数字
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
                    '添加${currentType == ChantingType.buddhaNam ? '佛号' : '经文'}到修行记录',
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
                        await _addChantingRecord(chanting);
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

  Future<void> _addChantingRecord(Chanting chanting) async {
    try {
      await DatabaseService.instance.createChantingRecord(chanting.id!);
      _loadChantings();
      
      // 移除了成功提示
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('添加失败，请重试'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('修行记录'),
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
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                      Text('📿 修行记录说明'),
                      SizedBox(height: 8),
                      Text('  从个人中心选择佛号经文，添加到修行记录进行日常修行'),
                      SizedBox(height: 12),
                      Text('💡 使用方法：'),
                      SizedBox(height: 4),
                      Text('  • 点击右下角➕按钮，从个人中心选择添加'),
                      Text('  • 右上角数字显示今日念诵次数'),
                      Text('  • 点击"设置今日念诵次数"手动调整'),
                      Text('  • 点击标题查看详细内容和注音'),
                      Text('  • 菜单中可查看统计报表或删除记录'),
                      SizedBox(height: 8),
                      Text('📊 统计功能：'),
                      SizedBox(height: 4),
                      Text('  • 在详情页面点击"查看统计报表"按钮'),
                      Text('  • 或通过右上角菜单选择"统计报表"'),
                      Text('  • 查看总次数、修行天数、日均次数等数据'),
                      Text('  • 按日期查看详细修行记录'),
                      SizedBox(height: 8),
                      Text('🔗 数据关联：'),
                      SizedBox(height: 4),
                      Text('  • 修行记录关联个人中心的佛号经文'),
                      Text('  • 删除记录不影响个人中心的原始数据'),
                          Text('  • 删除原始经文会同时删除相关记录'),
                        ],
                      ),
                    ),
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
                _buildChantingRecordList(_buddhaNameRecords, ChantingType.buddhaNam),
                _buildChantingRecordList(_sutraRecords, ChantingType.sutra),
              ],
            ),
      floatingActionButton: Tooltip(
        message: '添加修行记录',
        child: FloatingActionButton(
          onPressed: _showQuickSelectDialog,
          backgroundColor: Colors.blue.shade600,
          child: const Icon(Icons.library_add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildChantingRecordList(List<ChantingRecordWithDetails> records, ChantingType type) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == ChantingType.buddhaNam 
                  ? Icons.self_improvement 
                  : Icons.book,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有${type == ChantingType.buddhaNam ? '佛号' : '经文'}修行记录',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右下角的 + 号从个人中心添加',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final chanting = record.chanting;
        final todayCount = _todayCounts[chanting.id] ?? 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              // 主要内容
              Column(
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
                                '添加时间: ${_formatDate(record.record.createdAt)}',
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
                        if (value == 'statistics') {
                          _showStatistics(chanting);
                        } else if (value == 'delete') {
                          _deleteRecordDialog(record);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'statistics',
                          child: Row(
                            children: [
                              Icon(Icons.bar_chart, size: 20),
                              SizedBox(width: 8),
                              Text('统计报表'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('删除记录', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _showChantingDetails(chanting);
                    },
                  ),
                  // 设置次数按钮区域
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showCountDialog(chanting),
                        child: const Text('设置今日念诵次数'),
                      ),
                    ),
                  ),
                ],
              ),
              // 右上角今日次数（仅显示）
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    '$todayCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteRecordDialog(ChantingRecordWithDetails record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除修行记录"${record.chanting.title}"吗？\n\n将同时删除：\n• 修行记录\n• 相关的念诵次数统计\n\n这不会删除个人中心的原始经文。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && record.record.id != null) {
      try {
        await DatabaseService.instance.deleteChantingRecord(record.record.id!);
        
        // 清除本地计数缓存
        _todayCounts.remove(record.chanting.id);
        
        // 重新加载数据
        _loadChantings();
        
        // 移除了成功提示
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    
    // 注音行（放在汉字上方，如果有注音）
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
              padding: const EdgeInsets.fromLTRB(1, 1, 1, 5),
              child: Text(
                pinyin,
                style: TextStyle(
                  fontSize: pronunciationFontSize,
                  color: Colors.blue.shade600,
                  fontStyle: FontStyle.italic,
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
    
    return Table(
      columnWidths: Map.fromIterable(
        List.generate(displayChars.length, (index) => index),
        key: (index) => index,
        value: (index) => const IntrinsicColumnWidth(),
      ),
      border: null,
      children: rows,
    );
  }

  // 计算列表视图中最大显示字符数（考虑注音宽度）
  int _calculateMaxCharsForListDisplay(double fontSize) {
    // 获取屏幕宽度
    double screenWidth = MediaQuery.of(context).size.width;
    // 减去各种padding和margin（列表卡片有更多的间距）
    double availableWidth = screenWidth - 160; // 增加边距预留
    
    // 考虑汉字和注音的宽度，注音通常比汉字更宽
    double charWidth = fontSize + 12; // 增加宽度预留，确保注音显示完全
    // 计算最大字符数
    int maxChars = (availableWidth / charWidth).floor();
    // 列表视图限制更严格，避免过宽，确保注音能完全显示
    return maxChars.clamp(3, 6);
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

  void _showStatistics(Chanting chanting) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChantingStatisticsScreen(
          chanting: chanting,
        ),
      ),
    ).then((_) {
      // 从统计页面返回后重新加载计数
      _loadChantings();
    });
  }
}
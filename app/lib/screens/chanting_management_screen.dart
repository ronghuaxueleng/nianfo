import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../services/database_service.dart';
import '../widgets/chanting_form.dart';
import 'chanting_detail_screen.dart';

class ChantingManagementScreen extends StatefulWidget {
  const ChantingManagementScreen({super.key});

  @override
  State<ChantingManagementScreen> createState() => _ChantingManagementScreenState();
}

class _ChantingManagementScreenState extends State<ChantingManagementScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Chanting> _builtInChantings = [];
  List<Chanting> _userChantings = [];
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
      final allChantings = await DatabaseService.instance.getAllChantings();
      
      final builtInChantings = allChantings.where((c) => c.isBuiltIn).toList();
      final userChantings = allChantings.where((c) => !c.isBuiltIn).toList();
      
      setState(() {
        _builtInChantings = builtInChantings;
        _userChantings = userChantings;
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
    if (chanting.isBuiltIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('内置经文不能删除'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
      await DatabaseService.instance.deleteChanting(chanting.id!);
      _loadChantings();
    }
  }

  Future<void> _logicalDeleteChanting(Chanting chanting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认隐藏'),
        content: Text('确定要隐藏"${chanting.title}"吗？\n\n隐藏后可以通过"重置内置经文"功能恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('隐藏'),
          ),
        ],
      ),
    );

    if (confirm == true && chanting.id != null) {
      await DatabaseService.instance.logicalDeleteChanting(chanting.id!);
      _loadChantings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已隐藏 "${chanting.title}"'),
            action: SnackBarAction(
              label: '查看重置选项',
              onPressed: _showResetDialog,
            ),
          ),
        );
      }
    }
  }

  Future<void> _showResetDialog() async {
    final deletedCount = await DatabaseService.instance.getDeletedBuiltInChantingsCount();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置内置经文'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前已隐藏 $deletedCount 个内置经文'),
            const SizedBox(height: 16),
            const Text('重置将会：'),
            const Text('• 恢复所有隐藏的内置经文'),
            const Text('• 重置所有内置经文到初始状态'),
            const Text('• 丢失对内置经文的修改'),
            const SizedBox(height: 16),
            const Text(
              '注意：此操作不可撤销！',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetBuiltInChantings();
            },
            child: const Text(
              '重置',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetBuiltInChantings() async {
    try {
      await DatabaseService.instance.resetBuiltInChantings();
      _loadChantings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('内置经文已重置完成'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('重置失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('佛号经文管理'),
        backgroundColor: Colors.orange.shade100,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                _showResetDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('重置内置经文'),
                  ],
                ),
              ),
            ],
            tooltip: '更多选项',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '内置经文'),
            Tab(text: '我的创建'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChantingList(_builtInChantings, true),
                _buildChantingList(_userChantings, false),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showChantingForm();
        },
        backgroundColor: Colors.orange.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildChantingList(List<Chanting> chantings, bool isBuiltIn) {
    if (chantings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isBuiltIn ? Icons.library_books : Icons.add_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isBuiltIn ? '暂无内置经文' : '还没有创建佛号经文',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            if (!isBuiltIn) ...[
              const SizedBox(height: 8),
              const Text(
                '点击右下角按钮添加',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 按类型分组
    final buddhaNames = chantings.where((c) => c.type == ChantingType.buddhaNam).toList();
    final sutras = chantings.where((c) => c.type == ChantingType.sutra).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 佛号部分
          if (buddhaNames.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.self_improvement, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  '佛号',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${buddhaNames.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...buddhaNames.map((chanting) => _buildChantingCard(chanting, isBuiltIn)),
            const SizedBox(height: 24),
          ],

          // 经文部分
          if (sutras.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.book, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  '经文',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${sutras.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sutras.map((chanting) => _buildChantingCard(chanting, isBuiltIn)),
          ],
        ],
      ),
    );
  }

  Widget _buildChantingCard(Chanting chanting, bool isBuiltIn) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            Icon(
              chanting.type == ChantingType.buddhaNam
                  ? Icons.self_improvement
                  : Icons.book,
              color: chanting.type == ChantingType.buddhaNam
                  ? Colors.blue.shade600
                  : Colors.green.shade600,
              size: 28,
            ),
            if (isBuiltIn)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _buildManagementContentWithPronunciation(chanting),
            const SizedBox(height: 4),
            Row(
              children: [
                if (isBuiltIn)
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
                      '内置',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isBuiltIn) const SizedBox(width: 8),
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
        trailing: isBuiltIn 
          ? Icon(Icons.lock, color: Colors.orange.shade300, size: 20) // 内置内容显示锁定图标
          : PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showChantingForm(chanting: chanting);
                } else if (value == 'delete') {
                  _deleteChanting(chanting);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('编辑'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('删除'),
                ),
              ],
            ),
        onTap: () {
          _showChantingDetails(chanting);
        },
      ),
    );
  }

  Widget _buildManagementContentWithPronunciation(Chanting chanting) {
    // 将内容按行分割
    final contentLines = chanting.content.split('\n');
    final pronunciationLines = chanting.pronunciation?.split('\n') ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 显示内容，最多2行
        for (int i = 0; i < contentLines.length && i < 2; i++) ...[
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
        if (contentLines.length > 2)
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
    
    // 计算显示长度，管理页面需要限制显示长度
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
    // 减去各种padding和margin（管理页面有更多元素）
    double availableWidth = screenWidth - 160; // 增加边距预留
    // 估算每个字符的宽度
    double charWidth = fontSize + 6; // 更准确的字符宽度估算
    // 计算最大字符数
    int maxChars = (availableWidth / charWidth).floor();
    // 管理页面限制更严格
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
          showChantingButton: false, // 管理页面不显示念诵按钮
        ),
      ),
    );
  }
}
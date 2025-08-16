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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('佛号经文管理'),
        backgroundColor: Colors.orange.shade100,
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
            ? null 
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
              maxLength: 8, // 限制显示字符数
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


  // 构建字符级别对应的普通文本显示
  Widget _buildCharacterWithPronunciation(
    String content, 
    String pronunciation, 
    double contentFontSize, 
    double pronunciationFontSize,
    {int? maxLength}
  ) {
    if (content.isEmpty) return const SizedBox.shrink();
    
    // 如果有长度限制，截取内容
    String displayContent = content;
    String displayPronunciation = pronunciation;
    
    if (maxLength != null && content.length > maxLength) {
      displayContent = content.substring(0, maxLength) + '...';
      // 对应地截取注音
      if (pronunciation.isNotEmpty) {
        final pronunciationChars = pronunciation.split(' ');
        if (pronunciationChars.length >= maxLength) {
          displayPronunciation = pronunciationChars.take(maxLength).join(' ') + '...';
        }
      }
    }
    
    // 分离汉字和注音
    final contentChars = displayContent.split('');
    final pronunciationChars = displayPronunciation.split(' ');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 汉字行 - 使用Wrap来避免溢出
        Wrap(
          children: contentChars.asMap().entries.map((entry) {
            final char = entry.value;
            final index = entry.key;
            if (char == '.' && index < contentChars.length - 3) {
              // 如果是省略号的一部分，特殊处理
              return Text(char, style: TextStyle(fontSize: contentFontSize));
            }
            return Container(
              width: 24, // 固定宽度确保对齐
              alignment: Alignment.center,
              child: Text(
                char,
                style: TextStyle(fontSize: contentFontSize),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // 注音行
        if (pronunciation.isNotEmpty) ...[
          const SizedBox(height: 2),
          Wrap(
            children: contentChars.asMap().entries.map((entry) {
              final index = entry.key;
              final char = entry.value;
              
              // 如果是省略号，不显示注音
              if (char == '.' && index < contentChars.length - 3) {
                return Container(
                  width: 24,
                  child: Text(
                    '',
                    style: TextStyle(fontSize: pronunciationFontSize),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              // 获取对应的注音
              String pinyin = '';
              if (index < pronunciationChars.length) {
                pinyin = pronunciationChars[index];
              }
              
              return Container(
                width: 24, // 与汉字相同的宽度
                alignment: Alignment.center,
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
        ],
      ],
    );
  }

  // 构建字符级别对应的可选择文本显示
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
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 汉字行 - 使用固定宽度的容器来确保对齐
        Wrap(
          children: contentChars.asMap().entries.map((entry) {
            final char = entry.value;
            return Container(
              width: 24, // 固定宽度确保对齐
              child: SelectableText(
                char,
                style: TextStyle(fontSize: contentFontSize),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // 注音行
        if (pronunciation.isNotEmpty) ...[
          const SizedBox(height: 2),
          Wrap(
            children: contentChars.asMap().entries.map((entry) {
              final index = entry.key;
              
              // 获取对应的注音
              String pinyin = '';
              if (index < pronunciationChars.length) {
                pinyin = pronunciationChars[index];
              }
              
              return Container(
                width: 24, // 与汉字相同的宽度
                child: SelectableText(
                  pinyin,
                  style: TextStyle(
                    fontSize: pronunciationFontSize,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
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
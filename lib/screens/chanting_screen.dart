import 'package:flutter/material.dart';
import '../models/chanting.dart';
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

      setState(() {
        _buddhaNams = buddhaNams;
        _sutras = sutras;
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

    if (confirm == true) {
      await DatabaseService.instance.deleteChanting(chanting.id!);
      _loadChantings();
    }
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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              chanting.type == ChantingType.buddhaNam
                  ? Icons.self_improvement
                  : Icons.book,
              color: Colors.orange,
            ),
            title: Text(
              chanting.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
                const SizedBox(height: 4),
                Text(
                  '创建时间: ${_formatDate(chanting.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
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
            Icon(
              chanting.type == ChantingType.buddhaNam
                  ? Icons.self_improvement
                  : Icons.book,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(chanting.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(chanting.content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/dedication.dart';
import '../models/chanting.dart';
import '../services/database_service.dart';
import '../widgets/dedication_form.dart';

class DedicationScreen extends StatefulWidget {
  const DedicationScreen({super.key});

  @override
  State<DedicationScreen> createState() => _DedicationScreenState();
}

class _DedicationScreenState extends State<DedicationScreen> {
  List<Dedication> _dedications = [];
  Map<int, Chanting> _chantingsMap = {}; // 佛号经文映射
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDedications();
  }

  Future<void> _loadDedications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dedications = await DatabaseService.instance.getAllDedications();
      
      // 加载所有佛号经文，建立映射
      final allChantings = await DatabaseService.instance.getAllChantings();
      final Map<int, Chanting> chantingsMap = {};
      for (final chanting in allChantings) {
        if (chanting.id != null) {
          chantingsMap[chanting.id!] = chanting;
        }
      }
      
      setState(() {
        _dedications = dedications;
        _chantingsMap = chantingsMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDedicationForm({Dedication? dedication}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DedicationForm(dedication: dedication),
    );

    if (result == true) {
      _loadDedications();
    }
  }

  Future<void> _deleteDedication(Dedication dedication) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除回向文"${dedication.title}"吗？'),
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
      await DatabaseService.instance.deleteDedication(dedication.id!);
      _loadDedications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回向文'),
        backgroundColor: Colors.orange.shade100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dedications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '还没有回向文',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '点击右下角按钮添加',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _dedications.length,
                  itemBuilder: (context, index) {
                    final dedication = _dedications[index];
                    final associatedChanting = dedication.chantingId != null 
                        ? _chantingsMap[dedication.chantingId!] 
                        : null;
                        
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          Icons.favorite,
                          color: Colors.pink.shade400,
                        ),
                        title: Text(
                          dedication.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              dedication.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            // 关联的佛号或经文
                            if (associatedChanting != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      associatedChanting.type == ChantingType.buddhaNam
                                          ? Icons.self_improvement
                                          : Icons.book,
                                      size: 14,
                                      color: Colors.blue.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '回向给：${associatedChanting.title}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  '通用回向',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 4),
                            Text(
                              '创建时间: ${_formatDate(dedication.createdAt)}',
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
                              _showDedicationForm(dedication: dedication);
                            } else if (value == 'delete') {
                              _deleteDedication(dedication);
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
                          _showDedicationDetails(dedication);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDedicationForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDedicationDetails(Dedication dedication) {
    final associatedChanting = dedication.chantingId != null 
        ? _chantingsMap[dedication.chantingId!] 
        : null;
        
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.favorite,
              color: Colors.pink.shade400,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(dedication.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 关联信息
              if (associatedChanting != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            associatedChanting.type == ChantingType.buddhaNam
                                ? Icons.self_improvement
                                : Icons.book,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '回向给：',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        associatedChanting.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // 回向文内容
              Text(
                '回向文内容：',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                dedication.content,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
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
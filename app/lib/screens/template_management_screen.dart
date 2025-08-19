import 'package:flutter/material.dart';
import '../models/dedication_template.dart';
import '../services/database_service.dart';
import '../widgets/template_form.dart';

class TemplateManagementScreen extends StatefulWidget {
  const TemplateManagementScreen({super.key});

  @override
  State<TemplateManagementScreen> createState() => _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  List<DedicationTemplate> _builtInTemplates = [];
  List<DedicationTemplate> _userTemplates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final builtInTemplates = await DatabaseService.instance.getBuiltInTemplates();
      final userTemplates = await DatabaseService.instance.getUserTemplates();
      
      setState(() {
        _builtInTemplates = builtInTemplates;
        _userTemplates = userTemplates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showTemplateForm({DedicationTemplate? template}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TemplateForm(template: template),
    );

    if (result == true) {
      _loadTemplates();
    }
  }

  Future<void> _deleteTemplate(DedicationTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模板"${template.title}"吗？'),
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
      await DatabaseService.instance.deleteDedicationTemplate(template.id!);
      _loadTemplates();
    }
  }

  Widget _buildTemplateCard(DedicationTemplate template) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(template.title)),
            if (template.isBuiltIn)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '内置',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
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
              template.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '创建时间: ${_formatDate(template.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: template.isBuiltIn
            ? Icon(Icons.lock, color: Colors.blue.shade300, size: 20) // 内置模板显示锁定图标
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showTemplateForm(template: template);
                  } else if (value == 'delete') {
                    _deleteTemplate(template);
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
          _showTemplateDetails(template);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模板管理'),
        backgroundColor: Colors.orange.shade100,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 内置模板部分
                  Text(
                    '内置模板',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_builtInTemplates.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('暂无内置模板'),
                      ),
                    )
                  else
                    ..._builtInTemplates.map((template) => _buildTemplateCard(template)),
                  
                  const SizedBox(height: 24),
                  
                  // 自定义模板部分
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '自定义模板',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showTemplateForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('添加模板'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_userTemplates.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('暂无自定义模板，点击右上角添加'),
                      ),
                    )
                  else
                    ..._userTemplates.map((template) => _buildTemplateCard(template)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTemplateForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showTemplateDetails(DedicationTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.title),
        content: SingleChildScrollView(
          child: Text(template.content),
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
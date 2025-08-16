import 'package:flutter/material.dart';
import '../models/dedication.dart';
import '../models/dedication_template.dart';
import '../services/database_service.dart';

class DedicationForm extends StatefulWidget {
  final Dedication? dedication;

  const DedicationForm({super.key, this.dedication});

  @override
  State<DedicationForm> createState() => _DedicationFormState();
}

class _DedicationFormState extends State<DedicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  List<DedicationTemplate> _templates = [];
  bool _templatesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    if (widget.dedication != null) {
      _titleController.text = widget.dedication!.title;
      _contentController.text = widget.dedication!.content;
    }
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _templatesLoading = true;
    });

    try {
      final templates = await DatabaseService.instance.getAllDedicationTemplates();
      setState(() {
        _templates = templates;
        _templatesLoading = false;
      });
    } catch (e) {
      setState(() {
        _templatesLoading = false;
      });
    }
  }

  void _selectTemplate(DedicationTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _contentController.text = template.content;
    });
    Navigator.of(context).pop();
  }

  void _showTemplateSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '选择回向文模板',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _templatesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _templates.isEmpty
                      ? const Center(child: Text('暂无模板'))
                      : ListView.builder(
                          itemCount: _templates.length,
                          itemBuilder: (context, index) {
                            final template = _templates[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
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
                                subtitle: Text(
                                  template.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _selectTemplate(template),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.dedication == null) {
        // Create new dedication
        final dedication = Dedication(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: DateTime.now(),
        );
        await DatabaseService.instance.createDedication(dedication);
      } else {
        // Update existing dedication
        final updatedDedication = Dedication(
          id: widget.dedication!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          createdAt: widget.dedication!.createdAt,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.updateDedication(updatedDedication);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.dedication == null ? '添加回向文' : '编辑回向文',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (widget.dedication == null) // 只在添加新回向文时显示模板选择
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showTemplateSelector,
                    icon: const Icon(Icons.library_books),
                    label: const Text('选择模板'),
                  ),
                ),
              if (widget.dedication == null)
                const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '回向文内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入回向文内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('保存'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
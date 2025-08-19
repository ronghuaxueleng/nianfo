import 'package:flutter/material.dart';
import '../models/dedication_template.dart';
import '../services/database_service.dart';

class TemplateForm extends StatefulWidget {
  final DedicationTemplate? template;

  const TemplateForm({super.key, this.template});

  @override
  State<TemplateForm> createState() => _TemplateFormState();
}

class _TemplateFormState extends State<TemplateForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _titleController.text = widget.template!.title;
      _contentController.text = widget.template!.content;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // 防止编辑内置模板
    if (widget.template?.isBuiltIn == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('内置模板无法编辑'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.template == null) {
        // Create new template
        final template = DedicationTemplate(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          isBuiltIn: false,
          createdAt: DateTime.now(),
        );
        await DatabaseService.instance.createDedicationTemplate(template);
      } else {
        // Update existing template
        final updatedTemplate = widget.template!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.updateDedicationTemplate(updatedTemplate);
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
                widget.template == null ? '添加模板' : '编辑模板',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '模板标题',
                  border: OutlineInputBorder(),
                  hintText: '例如：通用回向文、往生回向文等',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入模板标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '模板内容',
                  border: OutlineInputBorder(),
                  hintText: '请输入回向文内容',
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入模板内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '自定义模板可以在添加回向文时选择使用，方便快速录入常用的回向文内容。',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
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
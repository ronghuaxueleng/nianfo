import 'package:flutter/material.dart';
import '../models/chanting.dart';
import '../services/database_service.dart';

class ChantingForm extends StatefulWidget {
  final Chanting? chanting;
  final ChantingType defaultType;

  const ChantingForm({
    super.key,
    this.chanting,
    required this.defaultType,
  });

  @override
  State<ChantingForm> createState() => _ChantingFormState();
}

class _ChantingFormState extends State<ChantingForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _pronunciationController = TextEditingController();
  late ChantingType _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.chanting?.type ?? widget.defaultType;
    if (widget.chanting != null) {
      _titleController.text = widget.chanting!.title;
      _contentController.text = widget.chanting!.content;
      _pronunciationController.text = widget.chanting!.pronunciation ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _pronunciationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.chanting == null) {
        // Create new chanting
        final chanting = Chanting(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          pronunciation: _pronunciationController.text.trim().isEmpty 
              ? null 
              : _pronunciationController.text.trim(),
          type: _selectedType,
          createdAt: DateTime.now(),
        );
        await DatabaseService.instance.createChanting(chanting);
      } else {
        // Update existing chanting
        final updatedChanting = Chanting(
          id: widget.chanting!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          pronunciation: _pronunciationController.text.trim().isEmpty 
              ? null 
              : _pronunciationController.text.trim(),
          type: _selectedType,
          isBuiltIn: widget.chanting!.isBuiltIn,
          createdAt: widget.chanting!.createdAt,
          updatedAt: DateTime.now(),
        );
        await DatabaseService.instance.updateChanting(updatedChanting);
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
                widget.chanting == null ? '添加内容' : '编辑内容',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<ChantingType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: '类型',
                  border: OutlineInputBorder(),
                ),
                items: ChantingType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type == ChantingType.buddhaNam ? '佛号' : '经文'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
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
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: _selectedType == ChantingType.buddhaNam ? '佛号内容' : '经文内容',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pronunciationController,
                decoration: const InputDecoration(
                  labelText: '注音 (可选)',
                  hintText: '为经文或佛号添加拼音注音',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
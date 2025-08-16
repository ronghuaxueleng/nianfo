import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/auth_service.dart';
import '../models/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedAvatar;
  AvatarType _avatarType = AvatarType.emoji;
  File? _selectedImageFile;
  bool _isLoading = false;

  // 预定义的头像选项
  final List<String> _avatarOptions = [
    '🧘', '🙏', '☸️', '🕉️', '📿', '🕯️', 
    '🌸', '🌺', '🌙', '⭐', '💫', '🌅',
    '👤', '👨', '👩', '🧔', '👴', '👵',
  ];

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      _usernameController.text = user.username;
      _avatarType = user.avatarType;
      _selectedAvatar = user.avatar ?? '🧘';
      
      // 如果是图片类型，检查文件是否存在
      if (_avatarType == AvatarType.image && user.avatar != null) {
        final file = File(user.avatar!);
        if (file.existsSync()) {
          _selectedImageFile = file;
        } else {
          // 如果图片文件不存在，切换回emoji
          _avatarType = AvatarType.emoji;
          _selectedAvatar = '🧘';
        }
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        // 获取应用文档目录
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String avatarsDir = path.join(appDir.path, 'avatars');
        
        // 创建头像目录
        await Directory(avatarsDir).create(recursive: true);
        
        // 生成唯一文件名
        final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final String savedPath = path.join(avatarsDir, fileName);
        
        // 复制文件到应用目录
        await File(image.path).copy(savedPath);
        
        setState(() {
          _selectedImageFile = File(savedPath);
          _avatarType = AvatarType.image;
          _selectedAvatar = savedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('选择图片失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        // 获取应用文档目录
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String avatarsDir = path.join(appDir.path, 'avatars');
        
        // 创建头像目录
        await Directory(avatarsDir).create(recursive: true);
        
        // 生成唯一文件名
        final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final String savedPath = path.join(avatarsDir, fileName);
        
        // 复制文件到应用目录
        await File(image.path).copy(savedPath);
        
        setState(() {
          _selectedImageFile = File(savedPath);
          _avatarType = AvatarType.image;
          _selectedAvatar = savedPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('拍照失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('取消'),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.updateUserProfile(
        _usernameController.text.trim(),
        _selectedAvatar,
        _avatarType,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('个人资料更新成功'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新失败，请重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新失败，请重试'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人资料'),
        backgroundColor: Colors.orange.shade100,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(color: Colors.orange),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 头像选择区域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '选择头像',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 当前选中的头像
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.orange.shade300,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(38),
                            child: _avatarType == AvatarType.image && _selectedImageFile != null
                                ? Image.file(
                                    _selectedImageFile!,
                                    fit: BoxFit.cover,
                                    width: 76,
                                    height: 76,
                                  )
                                : Center(
                                    child: Text(
                                      _selectedAvatar ?? '🧘',
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 头像类型选择按钮
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showImagePickerOptions,
                              icon: const Icon(Icons.photo_camera),
                              label: const Text('选择照片'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _avatarType = AvatarType.emoji;
                                  _selectedImageFile = null;
                                  _selectedAvatar = '🧘';
                                });
                              },
                              icon: const Icon(Icons.emoji_emotions),
                              label: const Text('表情头像'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 头像选择网格 (只在emoji模式下显示)
                      if (_avatarType == AvatarType.emoji)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _avatarOptions.length,
                          itemBuilder: (context, index) {
                            final avatar = _avatarOptions[index];
                            final isSelected = _avatarType == AvatarType.emoji && _selectedAvatar == avatar;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _avatarType = AvatarType.emoji;
                                  _selectedAvatar = avatar;
                                  _selectedImageFile = null;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Colors.orange.shade200 
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected 
                                        ? Colors.orange.shade600 
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    avatar,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 用户名编辑区域
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '用户名',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: '用户名',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.person),
                          hintText: '请输入新的用户名',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入用户名';
                          }
                          if (value.trim().length < 2) {
                            return '用户名至少需要2个字符';
                          }
                          if (value.trim().length > 20) {
                            return '用户名不能超过20个字符';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 提示信息
              Container(
                padding: const EdgeInsets.all(16),
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
                        '修改后的个人资料将在所有功能中生效。头像和用户名将显示在个人中心页面。',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 保存按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveProfile,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? '保存中...' : '保存更改'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
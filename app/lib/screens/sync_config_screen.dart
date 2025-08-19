import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sync_service.dart';

class SyncConfigScreen extends StatefulWidget {
  const SyncConfigScreen({super.key});

  @override
  State<SyncConfigScreen> createState() => _SyncConfigScreenState();
}

class _SyncConfigScreenState extends State<SyncConfigScreen> {
  bool _isLoading = true;
  
  // 同步开关设置
  bool _autoSync = true;
  bool _wifiOnly = true;
  bool _backgroundSync = false;
  
  // 数据类型同步开关
  bool _syncUsers = true;
  bool _syncChantings = false;  // 默认关闭，保护内置数据
  bool _syncTemplates = false;  // 默认关闭，保护内置模板
  bool _syncRecords = true;
  bool _syncStats = true;
  bool _syncDedications = true;
  
  // 高级设置
  bool _allowOverwrite = false;  // 是否允许覆盖本地数据
  int _syncInterval = 60;  // 同步间隔（分钟）
  
  @override
  void initState() {
    super.initState();
    _loadSyncSettings();
  }

  Future<void> _loadSyncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _autoSync = prefs.getBool('sync_auto_enabled') ?? true;
        _wifiOnly = prefs.getBool('sync_wifi_only') ?? true;
        _backgroundSync = prefs.getBool('sync_background_enabled') ?? false;
        
        _syncUsers = prefs.getBool('sync_data_users') ?? true;
        _syncChantings = prefs.getBool('sync_data_chantings') ?? false;
        _syncTemplates = prefs.getBool('sync_data_templates') ?? false;
        _syncRecords = prefs.getBool('sync_data_records') ?? true;
        _syncStats = prefs.getBool('sync_data_stats') ?? true;
        _syncDedications = prefs.getBool('sync_data_dedications') ?? true;
        
        _allowOverwrite = prefs.getBool('sync_allow_overwrite') ?? false;
        _syncInterval = prefs.getInt('sync_interval_minutes') ?? 60;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载设置失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
      
      // 通知 SyncService 配置已更改
      SyncService.instance.reconfigureAutoSync();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存设置失败: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showIntervalPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置同步间隔'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择自动同步的时间间隔：'),
            const SizedBox(height: 16),
            ...[ 15, 30, 60, 120, 180, 360 ].map((minutes) => RadioListTile<int>(
              title: Text('${minutes}分钟'),
              value: minutes,
              groupValue: _syncInterval,
              onChanged: (value) {
                setState(() {
                  _syncInterval = value!;
                });
                _saveSetting('sync_interval_minutes', value);
                Navigator.of(context).pop();
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showDataWarning(String dataType, bool newValue, VoidCallback onConfirm) {
    if (!newValue) {
      onConfirm();
      return;
    }
    
    String warningMessage = '';
    switch (dataType) {
      case 'chantings':
        warningMessage = '启用佛号经文同步可能会覆盖内置数据，建议保持关闭状态。';
        break;
      case 'templates':
        warningMessage = '启用回向模板同步可能会覆盖内置模板，建议保持关闭状态。';
        break;
      case 'overwrite':
        warningMessage = '启用数据覆盖后，服务器数据会替换本地数据，此操作不可撤销！';
        break;
    }
    
    if (warningMessage.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('警告'),
            ],
          ),
          content: Text(warningMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('确认开启'),
            ),
          ],
        ),
      );
    } else {
      onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('同步配置'),
          backgroundColor: Colors.orange.shade100,
          foregroundColor: Colors.orange.shade800,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('同步配置'),
        backgroundColor: Colors.orange.shade100,
        foregroundColor: Colors.orange.shade800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基础同步设置
            _buildSectionCard(
              title: '基础设置',
              icon: Icons.settings,
              children: [
                _buildSwitchTile(
                  title: '自动同步',
                  subtitle: '启用后会定期自动同步数据',
                  value: _autoSync,
                  onChanged: (value) {
                    setState(() => _autoSync = value);
                    _saveSetting('sync_auto_enabled', value);
                  },
                ),
                _buildSwitchTile(
                  title: '仅WiFi同步',
                  subtitle: '只在连接WiFi时进行数据同步',
                  value: _wifiOnly,
                  onChanged: (value) {
                    setState(() => _wifiOnly = value);
                    _saveSetting('sync_wifi_only', value);
                  },
                ),
                _buildSwitchTile(
                  title: '后台同步',
                  subtitle: '应用在后台时也可以同步数据',
                  value: _backgroundSync,
                  onChanged: (value) {
                    setState(() => _backgroundSync = value);
                    _saveSetting('sync_background_enabled', value);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.timer, color: Colors.orange.shade700),
                  title: const Text('同步间隔'),
                  subtitle: Text('${_syncInterval}分钟'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showIntervalPicker,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 数据类型设置
            _buildSectionCard(
              title: '同步数据类型',
              icon: Icons.data_usage,
              children: [
                _buildSwitchTile(
                  title: '用户信息',
                  subtitle: '同步用户资料和设置',
                  value: _syncUsers,
                  onChanged: (value) {
                    setState(() => _syncUsers = value);
                    _saveSetting('sync_data_users', value);
                  },
                ),
                _buildSwitchTile(
                  title: '修行记录',
                  subtitle: '同步念经记录和统计',
                  value: _syncRecords,
                  onChanged: (value) {
                    setState(() => _syncRecords = value);
                    _saveSetting('sync_data_records', value);
                  },
                ),
                _buildSwitchTile(
                  title: '每日统计',
                  subtitle: '同步每日修行统计数据',
                  value: _syncStats,
                  onChanged: (value) {
                    setState(() => _syncStats = value);
                    _saveSetting('sync_data_stats', value);
                  },
                ),
                _buildSwitchTile(
                  title: '回向记录',
                  subtitle: '同步回向文本和记录',
                  value: _syncDedications,
                  onChanged: (value) {
                    setState(() => _syncDedications = value);
                    _saveSetting('sync_data_dedications', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 高级设置（危险操作）
            _buildSectionCard(
              title: '高级设置',
              icon: Icons.warning,
              iconColor: Colors.orange,
              children: [
                _buildSwitchTile(
                  title: '佛号经文同步',
                  subtitle: '⚠️ 可能覆盖内置数据，不建议开启',
                  value: _syncChantings,
                  onChanged: (value) {
                    _showDataWarning('chantings', value, () {
                      setState(() => _syncChantings = value);
                      _saveSetting('sync_data_chantings', value);
                    });
                  },
                  dangerMode: true,
                ),
                _buildSwitchTile(
                  title: '回向模板同步',
                  subtitle: '⚠️ 可能覆盖内置模板，不建议开启',
                  value: _syncTemplates,
                  onChanged: (value) {
                    _showDataWarning('templates', value, () {
                      setState(() => _syncTemplates = value);
                      _saveSetting('sync_data_templates', value);
                    });
                  },
                  dangerMode: true,
                ),
                _buildSwitchTile(
                  title: '允许数据覆盖',
                  subtitle: '⚠️ 服务器数据会覆盖本地数据',
                  value: _allowOverwrite,
                  onChanged: (value) {
                    _showDataWarning('overwrite', value, () {
                      setState(() => _allowOverwrite = value);
                      _saveSetting('sync_allow_overwrite', value);
                    });
                  },
                  dangerMode: true,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 说明信息
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color? iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool dangerMode = false,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: dangerMode ? Colors.orange.shade700 : Colors.grey[800],
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: dangerMode ? Colors.orange.shade600 : Colors.grey[600],
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: dangerMode ? Colors.orange : Colors.blue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '设置说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              '• 推荐保持默认设置，确保数据安全',
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              '• 佛号经文和模板建议不要开启同步，避免覆盖内置数据',
              Icons.warning,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              '• 修改设置后立即生效，无需重启应用',
              Icons.settings,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
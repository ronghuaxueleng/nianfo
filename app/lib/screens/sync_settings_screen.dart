import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../config/app_config.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  bool _isUploadSyncing = false;
  bool _isDownloadSyncing = false;
  bool _isTestingConnection = false;
  String? _lastSyncTime;
  String _syncStatus = '未同步';
  String _connectionStatus = '等待检测';

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    // 这里可以从SharedPreferences加载上次同步时间
    setState(() {
      _lastSyncTime = '未同步';
      _syncStatus = '正常';
    });
  }

  Future<void> _uploadToServer() async {
    if (_isUploadSyncing) return;

    setState(() {
      _isUploadSyncing = true;
      _syncStatus = '正在上传到服务器...';
    });

    try {
      final success = await SyncService.instance.manualUploadSync();
      
      setState(() {
        _isUploadSyncing = false;
        if (success) {
          _syncStatus = '上传成功';
          _lastSyncTime = _formatDateTime(DateTime.now());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('数据已成功同步到服务器'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _syncStatus = '上传失败';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('同步失败，请检查网络连接'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isUploadSyncing = false;
        _syncStatus = '上传出错';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('同步出错: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadFromServer() async {
    if (_isDownloadSyncing) return;

    setState(() {
      _isDownloadSyncing = true;
      _syncStatus = '正在从服务器下载...';
    });

    try {
      final success = await SyncService.instance.manualDownloadSync();
      
      setState(() {
        _isDownloadSyncing = false;
        if (success) {
          _syncStatus = '下载成功';
          _lastSyncTime = _formatDateTime(DateTime.now());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已成功从服务器同步数据'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _syncStatus = '下载失败';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('下载失败，请检查网络连接'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isDownloadSyncing = false;
        _syncStatus = '下载出错';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('下载出错: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkServerConnection() async {
    if (_isTestingConnection) return;

    setState(() {
      _isTestingConnection = true;
      _connectionStatus = '检测中...';
    });

    try {
      final isHealthy = await SyncService.instance.checkBackendHealth();
      
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = isHealthy ? '连接正常' : '连接失败';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHealthy ? '服务器连接正常' : '服务器连接失败'),
          backgroundColor: isHealthy ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isTestingConnection = false;
        _connectionStatus = '连接错误';
      });
      
      // 提供更详细的错误信息和解决建议
      String errorMessage = '连接检查失败: ${e.toString()}';
      String suggestion = '';
      
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        suggestion = '\n\n💡 建议：\n1. 检查服务器是否正在运行\n2. 确认IP地址是否正确\n3. 检查防火墙设置';
      } else if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        suggestion = '\n\n💡 建议：\n1. 检查网络连接\n2. 服务器响应可能较慢\n3. 尝试重新测试';
      } else if (e.toString().contains('Certificate') || e.toString().contains('SSL')) {
        suggestion = '\n\n💡 建议：\n1. 使用HTTP而不是HTTPS\n2. 检查网络安全配置';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage + suggestion),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据同步'),
        backgroundColor: Colors.orange.shade100,
        foregroundColor: Colors.orange.shade800,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 同步状态卡片
            _buildStatusCard(),
            
            const SizedBox(height: 24),
            
            // 同步操作区域
            _buildSyncActionsSection(),
            
            const SizedBox(height: 24),
            
            // 服务器信息
            _buildServerInfoSection(),
            
            const SizedBox(height: 24),
            
            // 说明信息
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade50,
              Colors.orange.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sync,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '同步状态',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildStatusRow('当前状态', _syncStatus),
            const SizedBox(height: 8),
            _buildStatusRow('上次同步', _lastSyncTime ?? '未同步'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.orange.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSyncActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '同步操作',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 上传到服务器按钮
        _buildSyncButton(
          icon: Icons.cloud_upload,
          title: '上传到服务器',
          subtitle: '将本地数据同步到服务器',
          isLoading: _isUploadSyncing,
          onPressed: _uploadToServer,
          color: Colors.blue,
        ),
        
        const SizedBox(height: 12),
        
        // 从服务器下载按钮
        _buildSyncButton(
          icon: Icons.cloud_download,
          title: '从服务器下载',
          subtitle: '将服务器数据同步到本地',
          isLoading: _isDownloadSyncing,
          onPressed: _downloadFromServer,
          color: Colors.green,
        ),
        
        const SizedBox(height: 12),
        
      ],
    );
  }

  Widget _buildSyncButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLoading,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(icon, color: color, size: 24),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerInfoSection() {
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
                  Icons.storage,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '服务器信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            _buildInfoRow('服务器地址', AppConfig.displayServerUrl),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '连接状态',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _connectionStatus == '连接正常' 
                            ? Colors.green 
                            : _connectionStatus == '连接失败' || _connectionStatus == '连接错误'
                                ? Colors.red
                                : Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      height: 28,
                      child: ElevatedButton(
                        onPressed: _isTestingConnection ? null : _checkServerConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: _isTestingConnection
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.orange.shade700,
                                  ),
                                ),
                              )
                            : const Text(
                                '测试',
                                style: TextStyle(fontSize: 12),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
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
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '同步说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            _buildInfoItem('上传到服务器', '将您的本地数据（用户信息、佛号经文、回向记录等）备份到服务器'),
            const SizedBox(height: 8),
            _buildInfoItem('从服务器下载', '将服务器上的数据同步到本地，会覆盖本地数据'),
            const SizedBox(height: 8),
            _buildInfoItem('自动同步', '应用会在启动1分钟后自动上传数据到服务器'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
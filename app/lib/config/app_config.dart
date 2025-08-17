class AppConfig {
  // 服务器配置
  static const String primaryServerHost = '192.168.10.11';
  static const int serverPort = 5000;
  static const String serverProtocol = 'http';
  
  // 构建完整的服务器地址
  static String get baseServerUrl => '$serverProtocol://$primaryServerHost:$serverPort';
  
  // 后台API地址列表
  static List<String> get backendUrls => [
    '$baseServerUrl/sync',  // 主服务器地址
    'http://localhost:$serverPort/sync',
    'http://127.0.0.1:$serverPort/sync',
    // 可以添加更多备用地址
  ];
  
  // 显示用的服务器地址
  static String get displayServerUrl => baseServerUrl;
  
  // 健康检查地址
  static String get healthCheckUrl => '$baseServerUrl/sync/health';
  
  // 上传地址
  static String get uploadUrl => '$baseServerUrl/sync/upload';
  
  // 下载地址
  static String get downloadUrl => '$baseServerUrl/sync/download';
  
  // 超时配置
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration healthCheckTimeout = Duration(seconds: 10);
  
  // 用户代理
  static const String userAgent = 'NianfoApp/1.0';
}
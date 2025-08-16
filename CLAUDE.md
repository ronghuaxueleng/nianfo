# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 提供在此代码库中工作的指导。

## 项目概述

这是一个名为"修行记录"的 Flutter 移动应用程序，用于记录和管理佛教念经、经文和回向文本。

## 开发命令

```bash
# 获取依赖包
flutter pub get

# 以调试模式运行应用
flutter run

# 构建Android APK
flutter build apk

# 构建iOS版本（需要macOS）
flutter build ios

# 运行测试
flutter test

# 代码分析
flutter analyze
```

## 架构

### 目录结构
```
lib/
├── main.dart              # 应用入口
├── models/               # 数据模型
│   ├── user.dart         # 用户模型（含昵称字段）
│   ├── dedication.dart   # 回向文本模型
│   ├── chanting.dart     # 佛教念经/经文模型
│   ├── chanting_record.dart # 修行记录模型
│   ├── daily_stats.dart  # 每日统计模型
│   └── dedication_template.dart # 回向文模板模型
├── screens/              # UI界面
│   ├── login_screen.dart # 登录/注册界面
│   ├── home_screen.dart  # 主导航界面
│   ├── dedication_screen.dart # 回向管理界面
│   ├── chanting_screen.dart   # 修行记录管理界面
│   ├── chanting_management_screen.dart # 佛号经文管理界面
│   ├── chanting_detail_screen.dart # 经文详情界面
│   ├── chanting_statistics_screen.dart # 统计报表界面
│   ├── profile_screen.dart    # 个人中心界面
│   ├── edit_profile_screen.dart # 编辑资料界面
│   └── template_management_screen.dart # 模板管理界面
├── widgets/              # 可复用组件
│   ├── dedication_form.dart # 添加/编辑回向的表单
│   ├── chanting_form.dart   # 添加/编辑念经的表单
│   └── template_form.dart   # 模板表单
└── services/             # 业务逻辑
    ├── auth_service.dart     # 认证服务
    └── database_service.dart # SQLite数据库操作
```

### 核心功能
1. **用户认证**：用户名/密码登录，支持昵称设置，本地存储
2. **回向管理**：佛教回向文本的增删改查操作，支持模板系统
3. **佛号经文管理**：分别管理佛号和经文，支持注音、内置库和自定义添加
4. **修行记录系统**：
   - 从佛号经文管理中选择添加到修行记录
   - 记录与管理分离，删除记录不影响原始数据
   - 每日念诵次数统计和手动设置
   - 详细的统计报表和数据分析
5. **本地存储**：SQLite数据库实现离线数据持久化

### 数据库结构
- **users（用户表）**: id, username, password, avatar, avatar_type, nickname, created_at
- **dedications（回向表）**: id, title, content, chanting_id, created_at, updated_at
- **chantings（佛号经文表）**: id, title, content, pronunciation, type, is_built_in, is_deleted, created_at, updated_at
- **chanting_records（修行记录表）**: id, chanting_id, created_at, updated_at
- **daily_stats（每日统计表）**: id, chanting_id, count, date, created_at, updated_at
- **dedication_templates（回向模板表）**: id, title, content, is_built_in, created_at, updated_at

### 状态管理
- 使用Provider模式管理认证状态
- UI组件使用本地状态管理

## 依赖包
- sqflite: 本地SQLite数据库
- shared_preferences: 简单键值存储
- provider: 状态管理
- cupertino_icons: iOS风格图标

## 配置优化

### Flutter环境配置

1. **国内镜像配置 (Windows)**
   ```cmd
   # 在Windows系统环境变量中设置，或在PowerShell中设置
   # PowerShell方式：
   $env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
   $env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
   
   # 或者使用腾讯云镜像
   $env:FLUTTER_STORAGE_BASE_URL="https://mirrors.cloud.tencent.com/flutter"
   $env:PUB_HOSTED_URL="https://mirrors.cloud.tencent.com/dart-pub"
   
   # CMD方式：
   set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
   set PUB_HOSTED_URL=https://pub.flutter-io.cn
   
   # 永久设置：在Windows系统环境变量中添加上述变量
   # 控制面板 -> 系统 -> 高级系统设置 -> 环境变量
   ```

2. **Gradle配置优化**
   ```gradle
   # android/build.gradle 中添加国内镜像
   allprojects {
       repositories {
           maven { url 'https://maven.aliyun.com/repository/google' }
           maven { url 'https://maven.aliyun.com/repository/central' }
           maven { url 'https://maven.aliyun.com/repository/jcenter' }
           google()
           mavenCentral()
       }
   }
   ```

3. **Flutter配置文件 (Windows)**
   ```cmd
   # 配置Android SDK路径 (Windows路径格式)
   flutter config --android-sdk "C:\Users\%USERNAME%\AppData\Local\Android\Sdk"
   
   # 禁用不需要的平台支持以提高性能
   flutter config --enable-web false
   flutter config --enable-macos-desktop false
   flutter config --enable-linux-desktop false
   
   # Windows桌面开发可选择保留
   flutter config --enable-windows-desktop true
   
   # 禁用数据收集
   flutter config --enable-analytics false
   ```

4. **代理和网络配置 (Windows)**
   ```cmd
   # PowerShell中设置代理
   $env:https_proxy="http://proxy.example.com:8080"
   $env:http_proxy="http://proxy.example.com:8080"
   
   # CMD中设置代理
   set https_proxy=http://proxy.example.com:8080
   set http_proxy=http://proxy.example.com:8080
   
   # Git配置（用于Flutter SDK更新）
   git config --global url."https://gitclone.com/github.com/".insteadOf "https://github.com/"
   
   # Windows系统代理设置
   # 设置 -> 网络和Internet -> 代理 -> 手动设置代理
   ```

5. **Gradle优化配置 (Windows)**
   ```properties
   # 在项目根目录/android/gradle.properties 文件中添加以下配置
   org.gradle.jvmargs=-Xmx4096m -XX:MaxPermSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
   org.gradle.parallel=true
   org.gradle.configureondemand=true
   org.gradle.daemon=true
   android.useAndroidX=true
   android.enableJetifier=true
   
   # Windows特定配置
   org.gradle.console=plain
   org.gradle.logging.level=lifecycle
   ```

### 性能优化
1. **构建优化**
   - 使用 `flutter build apk --split-per-abi` 减小APK大小
   - 启用代码混淆：`flutter build apk --obfuscate --split-debug-info=<directory>`
   - 使用 `flutter build apk --release` 构建生产版本

2. **数据库优化**
   - 为常用查询字段添加索引
   - 使用批量操作处理大量数据
   - 定期清理过期数据

3. **内存优化**
   - 及时释放不使用的资源
   - 使用 `const` 构造函数减少重建
   - 合理使用 `ListView.builder` 处理长列表

### 开发环境配置
1. **IDE配置**
   - 推荐使用 VS Code 或 Android Studio
   - 安装 Flutter 和 Dart 插件
   - 配置代码格式化：`dart format .`
   - VS Code 推荐插件：
     - Flutter
     - Dart
     - Flutter Tree
     - Awesome Flutter Snippets
     - Bracket Pair Colorizer

2. **环境变量配置 (Windows)**
   ```cmd
   # Windows系统环境变量设置
   # 通过控制面板 -> 系统 -> 高级系统设置 -> 环境变量 添加：
   FLUTTER_ROOT=C:\flutter
   ANDROID_HOME=C:\Users\%USERNAME%\AppData\Local\Android\Sdk
   
   # 在PATH中添加：
   C:\flutter\bin
   %ANDROID_HOME%\platform-tools
   %ANDROID_HOME%\tools
   %ANDROID_HOME%\tools\bin
   
   # PowerShell Profile中设置（可选）
   # 编辑 $PROFILE 文件添加：
   $env:FLUTTER_ROOT="C:\flutter"
   $env:ANDROID_HOME="C:\Users\$env:USERNAME\AppData\Local\Android\Sdk"
   ```

3. **Windows开发工具配置**
   ```powershell
   # PowerShell别名配置 (在 $PROFILE 中添加)
   Set-Alias frun 'flutter run'
   Set-Alias fbuild 'flutter build apk'
   Set-Alias ftest 'flutter test'
   Set-Alias fanalyze 'flutter analyze'
   
   # 函数定义
   function fclean { flutter clean; flutter pub get }
   function fpubget { flutter pub get }
   
   # Windows Terminal 配置
   # 推荐使用 Windows Terminal 作为开发终端
   # 可在 Microsoft Store 中下载安装
   ```

4. **调试配置 (Windows)**
   - 启用 Flutter Inspector 进行UI调试
   - 使用 `flutter analyze` 进行静态分析
   - 配置热重载提高开发效率
   - 使用 `flutter doctor -v` 检查环境问题
   - 启用详细日志：`flutter run --verbose`
   - Windows防火墙配置：允许Flutter开发服务器通过防火墙
   - 使用Windows Terminal或PowerShell进行开发

5. **版本管理**
   - 使用 `flutter doctor` 检查环境
   - 在 `pubspec.yaml` 中锁定依赖版本
   - 定期更新依赖：`flutter pub upgrade`

### 安全配置
1. **数据安全**
   - 用户密码使用哈希存储
   - 敏感数据加密存储
   - 定期备份重要数据

2. **代码安全**
   - 移除调试信息
   - 使用代码混淆保护源码
   - 避免在代码中硬编码敏感信息

### 部署配置
1. **Android配置**
   - 配置签名密钥
   - 设置应用图标和启动画面
   - 优化权限声明

2. **版本管理**
   - 遵循语义化版本规范
   - 维护更新日志
   - 配置自动化构建流程
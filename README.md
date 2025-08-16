# 修行记录 (Spiritual Practice Record)

一款专为修行人士设计的移动应用，用于记录和管理佛教念经、回向文本，支持功德记录和修行管理。

## 📱 功能特色

### 🙏 核心功能
- **回向文管理**：记录和管理各种回向文本
- **修行记录系统**：分别管理佛号和经文的修行记录，支持统计分析
- **佛号经文管理**：内置佛号经文库，支持自定义添加和编辑
- **模板系统**：内置常用回向文模板，支持自定义模板
- **用户系统**：本地用户认证、昵称设置和个人资料管理

### ✨ 亮点特性
- **内置回向文模板**：
  - 通用回向文
  - 往生回向文
  - 消业回向文
  - 众生回向文
  - 家庭回向文
  - 法界回向文

- **修行记录功能**：
  - 从佛号经文管理中选择内容添加到修行记录
  - 记录与管理分离，删除记录不影响原始数据
  - 每日念诵次数统计和手动设置
  - 详细的统计报表和修行数据分析

- **个性化设置**：
  - 用户头像设置（emoji + 图片）
  - 用户名和昵称设置
  - 个人资料管理

- **现代化界面**：
  - 橙色佛教主题设计
  - 隐藏式侧边菜单
  - 手势滑动交互
  - 卡片式布局
  - 注音功能支持（位置优化）
  - 懒加载优化（长经文快速显示）

## 🏗️ 技术架构

### 开发框架
- **Flutter** - 跨平台移动应用开发框架
- **Dart** - 编程语言

### 数据存储
- **SQLite** - 本地数据库
- **SharedPreferences** - 用户偏好设置

### 状态管理
- **Provider** - 状态管理解决方案

### 主要依赖
```yaml
dependencies:
  flutter: sdk
  sqflite: ^2.3.0           # 本地数据库
  shared_preferences: ^2.2.2 # 简单键值存储
  provider: ^6.1.1          # 状态管理
  image_picker: ^1.0.4      # 图片选择器
  path_provider: ^2.1.1     # 路径管理
  cupertino_icons: ^1.0.2   # iOS风格图标
```

## 📁 项目结构

```
lib/
├── main.dart              # 应用入口
├── models/               # 数据模型
│   ├── user.dart         # 用户模型
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

## 🗄️ 数据库设计

### 用户表 (users)
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  avatar TEXT,
  avatar_type TEXT DEFAULT 'emoji',
  nickname TEXT,
  created_at TEXT NOT NULL
);
```

### 回向文表 (dedications)
```sql
CREATE TABLE dedications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT
);
```

### 念经表 (chantings)
```sql
CREATE TABLE chantings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  pronunciation TEXT,
  type TEXT NOT NULL, -- 'buddhaNam' 或 'sutra'
  is_built_in INTEGER NOT NULL DEFAULT 0,
  is_deleted INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT
);
```

### 修行记录表 (chanting_records)
```sql
CREATE TABLE chanting_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chanting_id INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  FOREIGN KEY (chanting_id) REFERENCES chantings (id) ON DELETE CASCADE
);
```

### 每日统计表 (daily_stats)
```sql
CREATE TABLE daily_stats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chanting_id INTEGER NOT NULL,
  count INTEGER NOT NULL DEFAULT 0,
  date TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  UNIQUE(chanting_id, date),
  FOREIGN KEY (chanting_id) REFERENCES chantings (id)
);
```

### 回向文模板表 (dedication_templates)
```sql
CREATE TABLE dedication_templates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_built_in INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT
);
```

## 🚀 开发环境配置

### 系统要求
- Flutter SDK >=3.32.0
- Dart SDK >=3.8.0
- Android Studio / VS Code
- Android SDK (Android开发)
- Xcode (iOS开发，仅macOS)

### 国内开发环境配置
```bash
# 设置Flutter中国镜像
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export PUB_HOSTED_URL="https://pub.flutter-io.cn"

# 或者使用腾讯云镜像
export FLUTTER_STORAGE_BASE_URL="https://mirrors.cloud.tencent.com/flutter"
export PUB_HOSTED_URL="https://mirrors.cloud.tencent.com/dart-pub"
```

### 项目设置
```bash
# 克隆项目
git clone <repository-url>
cd nianfo

# 获取依赖
flutter pub get

# 运行应用
flutter run

# 构建APK
flutter build apk

# 代码分析
flutter analyze
```

### Gradle配置优化
在 `android/build.gradle` 中添加国内镜像：
```gradle
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

## 📱 应用截图

### 主要界面
- 登录/注册界面
- 底部导航主页
- 回向文管理
- 佛号经文管理
- 个人中心（隐藏式菜单）

### 核心功能
- 回向文模板选择
- 头像设置（emoji/图片）
- 用户资料编辑
- 模板管理系统

## 🔧 开发工具推荐

### IDE插件
- **VS Code**:
  - Flutter
  - Dart
  - Flutter Tree
  - Awesome Flutter Snippets

### 调试工具
- Flutter Inspector
- Flutter Performance
- Database Inspector

## 📝 开发规范

### 代码风格
- 使用 `dart format` 格式化代码
- 遵循 Flutter/Dart 官方代码规范
- 使用有意义的变量和函数命名

### Git提交规范
- feat: 新功能
- fix: 修复bug
- refactor: 重构代码
- docs: 文档更新
- style: 代码格式调整

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

感恩所有为佛法传播和科技弘法做出贡献的开发者和用户。

---

**南无阿弥陀佛** 🙏

*愿以此功德，回向法界众生*
*愿众生离苦得乐，究竟解脱*
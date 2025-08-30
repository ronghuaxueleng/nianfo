#!/usr/bin/env python3
"""
Flutter App Icon Updater
自动更新Flutter应用图标的脚本
"""
import shutil
import os

def update_flutter_icons():
    """更新Flutter应用图标"""
    
    # 图标文件映射
    icon_mappings = [
        ("app_icons/android/ic_launcher-mdpi-48.png", "app/android/app/src/main/res/mipmap-mdpi/ic_launcher.png"),
        ("app_icons/android/ic_launcher-hdpi-72.png", "app/android/app/src/main/res/mipmap-hdpi/ic_launcher.png"),
        ("app_icons/android/ic_launcher-xhdpi-96.png", "app/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"),
        ("app_icons/android/ic_launcher-xxhdpi-144.png", "app/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"),
        ("app_icons/android/ic_launcher-xxxhdpi-192.png", "app/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"),
        ("app_icons/android/ic_launcher-xxxhdpi-192.png", "app/android/app/src/main/res/ic_launcher.png"),
    ]
    
    print("开始更新Flutter应用图标...")
    
    success_count = 0
    for source, destination in icon_mappings:
        try:
            if os.path.exists(source):
                # 确保目标目录存在
                dest_dir = os.path.dirname(destination)
                os.makedirs(dest_dir, exist_ok=True)
                
                # 复制文件
                shutil.copy2(source, destination)
                print(f"✓ 已更新: {destination}")
                success_count += 1
            else:
                print(f"✗ 源文件不存在: {source}")
        except Exception as e:
            print(f"✗ 复制失败 {source} -> {destination}: {e}")
    
    print(f"\n图标更新完成！成功更新了 {success_count}/{len(icon_mappings)} 个图标")
    print("\n下一步:")
    print("1. 运行 'flutter clean' 清理缓存")
    print("2. 运行 'flutter pub get' 获取依赖") 
    print("3. 运行 'flutter run' 查看新图标")

if __name__ == "__main__":
    update_flutter_icons()
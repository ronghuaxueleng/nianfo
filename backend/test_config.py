#!/usr/bin/env python3
"""
测试配置加载器
"""

import sys
import os

# 添加当前目录到路径
sys.path.insert(0, os.path.dirname(__file__))

from utils.config_loader import config_loader

def test_config():
    """测试配置加载"""
    print("🔧 测试配置加载器...")
    
    # 重新加载配置
    config_loader.load_config()
    
    # 获取数据库配置
    db_config = config_loader.get_database_config()
    print(f"数据库类型: {db_config.get('type')}")
    
    if db_config.get('type') == 'mysql':
        mysql_config = db_config.get('mysql', {})
        print("MySQL配置:")
        for key, value in mysql_config.items():
            if key == 'password':
                print(f"  {key}: ***")
            else:
                print(f"  {key}: {value}")
    
    # 构建数据库URL
    try:
        db_url = config_loader.build_database_url()
        print(f"数据库URL: {db_url}")
    except Exception as e:
        print(f"构建数据库URL失败: {e}")
    
    # 测试Base64解码
    print("\n🔓 测试Base64解码:")
    test_strings = [
        "d3d3LnJvbmdodWF4dWVsZW5nLnNpdGU=",  # host
        "MzMwNg==",  # port
        "cm9vdA==",  # user
        "WGlueWFuMTIwM0BA",  # password
        "eGl1eGluZw=="  # database
    ]
    
    for test_str in test_strings:
        decoded = config_loader._decode_base64(test_str)
        print(f"  {test_str} -> {decoded}")

if __name__ == '__main__':
    test_config()
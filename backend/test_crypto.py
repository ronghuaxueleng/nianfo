#!/usr/bin/env python3
"""
测试后端密码加密功能，确保与Flutter app的哈希结果一致
"""

import sys
sys.path.append('.')

from utils.crypto_utils import CryptoUtils

def test_password_hashing():
    """测试密码哈希功能"""
    test_cases = [
        'test123',
        'password',
        '123456',
        'mypassword123',
        '',  # 空密码
        '!@#$%^&*()',  # 特殊字符
        '测试密码123',  # 中文密码
        'a' * 100,  # 长密码
    ]
    
    print("🔐 密码哈希测试")
    print("=" * 50)
    
    for password in test_cases:
        hashed = CryptoUtils.hash_password(password)
        is_valid = CryptoUtils.verify_password(password, hashed)
        is_hash_format = CryptoUtils.is_hashed_password(hashed)
        
        print(f"原始密码: '{password}' (长度: {len(password)})")
        print(f"哈希结果: {hashed}")
        print(f"验证结果: {'✅ 通过' if is_valid else '❌ 失败'}")
        print(f"哈希格式: {'✅ 正确' if is_hash_format else '❌ 错误'}")
        print("-" * 30)
    
    # 测试哈希的一致性
    password = 'consistency_test'
    hash1 = CryptoUtils.hash_password(password)
    hash2 = CryptoUtils.hash_password(password)
    
    print(f"一致性测试:")
    print(f"哈希1: {hash1}")
    print(f"哈希2: {hash2}")
    print(f"一致性: {'✅ 一致' if hash1 == hash2 else '❌ 不一致'}")
    print("-" * 30)
    
    # 测试错误密码验证
    wrong_password_result = CryptoUtils.verify_password('wrong', hash1)
    print(f"错误密码验证: {'❌ 意外通过' if wrong_password_result else '✅ 正确拒绝'}")
    
    print("\n🎯 测试完成！")

def generate_known_hashes():
    """生成一些已知密码的哈希，用于与Flutter app对比"""
    known_passwords = ['admin123', 'test123', 'password', '123456']
    
    print("\n🔑 已知密码哈希（用于Flutter app对比）")
    print("=" * 60)
    
    for password in known_passwords:
        hashed = CryptoUtils.hash_password(password)
        print(f"'{password}' -> {hashed}")

if __name__ == '__main__':
    test_password_hashing()
    generate_known_hashes()
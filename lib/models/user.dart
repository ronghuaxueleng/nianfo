enum AvatarType { emoji, image }

class User {
  final int? id;
  final String username;
  final String password;
  final String? avatar; // 头像路径或emoji
  final AvatarType avatarType; // 头像类型
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    this.avatar,
    this.avatarType = AvatarType.emoji,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'avatar': avatar,
      'avatar_type': avatarType.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      avatar: map['avatar'],
      avatarType: map['avatar_type'] == 'image' ? AvatarType.image : AvatarType.emoji,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? avatar,
    AvatarType? avatarType,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      avatar: avatar ?? this.avatar,
      avatarType: avatarType ?? this.avatarType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
/// User model representing a user in the messaging app
class User {
  final int id;
  final String username;
  final String phoneNumber;
  final String? displayName;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime? lastSeen;

  const User({
    required this.id,
    required this.username,
    required this.phoneNumber,
    this.displayName,
    this.avatarPath,
    required this.createdAt,
    this.lastSeen,
  });

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      displayName: json['displayName'] as String?,
      avatarPath: json['avatarPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      lastSeen: json['lastSeen'] != null ? DateTime.parse(json['lastSeen'] as String) : null,
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'avatarPath': avatarPath,
      'createdAt': createdAt.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    int? id,
    String? username,
    String? phoneNumber,
    String? displayName,
    String? avatarPath,
    DateTime? createdAt,
    DateTime? lastSeen,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  /// Get display name (displayName or username if displayName is empty)
  String get name {
    return displayName?.isNotEmpty == true ? displayName! : username;
  }

  /// Get initials for avatar placeholder
  String get initials {
    final nameValue = name;
    if (nameValue.isEmpty) return '?';

    final parts = nameValue.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return nameValue[0].toUpperCase();
    }
  }

  /// Check if user is online (last seen within 5 minutes)
  bool get isOnline {
    if (lastSeen == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);
    return difference.inMinutes <= 5;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, username: $username, phoneNumber: $phoneNumber, isOnline: $isOnline)';
  }
}

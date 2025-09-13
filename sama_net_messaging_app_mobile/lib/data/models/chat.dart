import 'user.dart';
import 'message.dart';

/// Chat model representing a conversation between users
class Chat {
  final int id;
  final String name;
  final List<int> participantIds;
  final List<User> participants;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ChatType type;
  final String? groupImageUrl;

  const Chat({
    required this.id,
    required this.name,
    required this.participantIds,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.type = ChatType.direct,
    this.groupImageUrl,
  });

  /// Create Chat from JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      participantIds: (json['participantIds'] as List<dynamic>? ?? [])
          .map((id) => id is int ? id : int.tryParse(id.toString()) ?? 0)
          .toList(),
      participants:
          (json['participantDetails'] as List<dynamic>?)
              ?.map((p) => User.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      lastMessage: json['lastMessage'] != null ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>) : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      type: ChatType.fromString(json['type'] as String? ?? 'direct'),
      groupImageUrl: json['groupImageUrl'] as String?,
    );
  }

  /// Convert Chat to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'participantIds': participantIds,
      'participantDetails': participants.map((p) => p.toJson()).toList(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'type': type.value,
      'groupImageUrl': groupImageUrl,
    };
  }

  /// Create a copy of Chat with updated fields
  Chat copyWith({
    int? id,
    String? name,
    List<int>? participantIds,
    List<User>? participants,
    Message? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChatType? type,
    String? groupImageUrl,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
    );
  }

  /// Get display name for the chat
  String getDisplayName(String currentUserId) {
    if (type == ChatType.group) {
      return name.isNotEmpty ? name : 'Group Chat';
    }

    // For direct chats, show the other participant's name
    final otherParticipant = participants.firstWhere(
      (user) => user.id.toString() != currentUserId,
      orElse: () =>
          User(id: 0, username: 'unknown', phoneNumber: '', createdAt: DateTime.now(), displayName: 'Unknown'),
    );

    return otherParticipant.name;
  }

  /// Get chat image URL
  String? getChatImageUrl(String currentUserId) {
    if (type == ChatType.group) {
      return groupImageUrl;
    }

    // For direct chats, no profile image available in current User model
    return null;
  }

  /// Get other participant in direct chat
  User? getOtherParticipant(String currentUserId) {
    if (type == ChatType.group) return null;

    try {
      return participants.firstWhere((user) => user.id.toString() != currentUserId);
    } catch (e) {
      return null;
    }
  }

  /// Check if current user is online (for direct chats)
  bool isOtherUserOnline(String currentUserId) {
    final otherUser = getOtherParticipant(currentUserId);
    return otherUser?.isOnline ?? false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Chat(id: $id, name: $name, type: $type, unreadCount: $unreadCount)';
  }
}

/// Enum for chat types
enum ChatType {
  direct('direct'),
  group('group');

  const ChatType(this.value);

  final String value;

  static ChatType fromString(String value) {
    return ChatType.values.firstWhere((type) => type.value == value, orElse: () => ChatType.direct);
  }
}

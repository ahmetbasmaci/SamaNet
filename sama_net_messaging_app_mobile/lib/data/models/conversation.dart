import 'user.dart';
import 'message.dart';

/// Conversation model representing a chat between users
class Conversation {
  final int id;
  final User otherUser;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime lastActivity;

  const Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    required this.lastActivity,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int? ?? 0,
      otherUser: User.fromJson(json['otherUser'] as Map<String, dynamic>),
      lastMessage: json['lastMessage'] != null ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>) : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastActivity: DateTime.parse(json['lastActivity'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'otherUser': otherUser.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'lastActivity': lastActivity.toIso8601String(),
    };
  }

  Conversation copyWith({int? id, User? otherUser, Message? lastMessage, int? unreadCount, DateTime? lastActivity}) {
    return Conversation(
      id: id ?? this.id,
      otherUser: otherUser ?? this.otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

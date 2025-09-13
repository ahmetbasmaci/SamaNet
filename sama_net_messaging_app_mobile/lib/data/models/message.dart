/// Message model representing a chat message
class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String messageType;
  final String? content;
  final DateTime sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final List<MessageAttachment> attachments;
  final String? senderUsername;
  final String? receiverUsername;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.messageType,
    this.content,
    required this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.attachments = const [],
    this.senderUsername,
    this.receiverUsername,
  });

  /// Create Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int? ?? 0,
      senderId: json['senderId'] as int? ?? 0,
      receiverId: json['receiverId'] as int? ?? 0,
      messageType: json['messageType'] as String? ?? 'text',
      content: json['content'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String? ?? DateTime.now().toIso8601String()),
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt'] as String) : null,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((attachment) => MessageAttachment.fromJson(attachment as Map<String, dynamic>))
          .toList(),
      senderUsername: json['senderUsername'] as String?,
      receiverUsername: json['receiverUsername'] as String?,
    );
  }

  /// Convert Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'messageType': messageType,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'attachments': attachments.map((attachment) => attachment.toJson()).toList(),
      'senderUsername': senderUsername,
      'receiverUsername': receiverUsername,
    };
  }

  /// Create a copy of Message with updated fields
  Message copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? messageType,
    String? content,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    List<MessageAttachment>? attachments,
    String? senderUsername,
    String? receiverUsername,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      attachments: attachments ?? this.attachments,
      senderUsername: senderUsername ?? this.senderUsername,
      receiverUsername: receiverUsername ?? this.receiverUsername,
    );
  }

  /// Check if message is from current user
  bool isFromUser(int currentUserId) {
    return senderId == currentUserId;
  }

  /// Check if message has attachment
  bool get hasAttachment {
    return attachments.isNotEmpty;
  }

  /// Get message status based on timestamps
  MessageStatus get status {
    if (readAt != null) return MessageStatus.read;
    if (deliveredAt != null) return MessageStatus.delivered;
    return MessageStatus.sent;
  }

  /// Get message type enum
  MessageType get type {
    return MessageType.fromString(messageType);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, type: $messageType, status: $status)';
  }
}

/// Message attachment model
class MessageAttachment {
  final int id;
  final String filePath;
  final String fileType;
  final int fileSize;

  const MessageAttachment({required this.id, required this.filePath, required this.fileType, required this.fileSize});

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] as int? ?? 0,
      filePath: json['filePath'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'filePath': filePath, 'fileType': fileType, 'fileSize': fileSize};
  }
}

/// Enum for message types
enum MessageType {
  text('text'),
  image('image'),
  video('video'),
  audio('audio'),
  file('file');

  const MessageType(this.value);

  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere((type) => type.value == value, orElse: () => MessageType.text);
  }
}

/// Enum for message status
enum MessageStatus {
  sending('sending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  const MessageStatus(this.value);

  final String value;

  static MessageStatus fromString(String value) {
    return MessageStatus.values.firstWhere((status) => status.value == value, orElse: () => MessageStatus.sent);
  }
}

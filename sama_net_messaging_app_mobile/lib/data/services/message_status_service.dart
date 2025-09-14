import '../models/message.dart';
import '../services/message_service.dart';
import '../services/local_storage_service.dart';
import '../../core/di/service_locator.dart';

/// Service for managing message status and real-time updates
class MessageStatusService {
  final MessageService _messageService;
  final LocalStorageService _localStorage;

  MessageStatusService(this._messageService, this._localStorage);

  /// Mark a message as delivered
  Future<bool> markAsDelivered(int messageId) async {
    try {
      final response = await _messageService.markMessageAsDelivered(messageId);
      if (response.isSuccess) {
        // Cache the delivered status locally for offline support
        await _localStorage.saveString('message_${messageId}_delivered', DateTime.now().toIso8601String());
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking message as delivered: $e');
      return false;
    }
  }

  /// Mark a message as read
  Future<bool> markAsRead(int messageId) async {
    try {
      final response = await _messageService.markMessageAsRead(messageId);
      if (response.isSuccess) {
        // Cache the read status locally
        await _localStorage.saveString('message_${messageId}_read', DateTime.now().toIso8601String());
        // Also mark as delivered if not already
        await _localStorage.saveString('message_${messageId}_delivered', DateTime.now().toIso8601String());
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking message as read: $e');
      return false;
    }
  }

  /// Mark multiple messages as read (for conversation)
  Future<List<int>> markMultipleAsRead(List<int> messageIds) async {
    List<int> successfullyMarked = [];

    for (int messageId in messageIds) {
      final success = await markAsRead(messageId);
      if (success) {
        successfullyMarked.add(messageId);
      }
    }

    return successfullyMarked;
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final response = await _messageService.getUnreadCount();
      if (response.isSuccess && response.data != null) {
        // Cache the count locally
        await _localStorage.saveInt('unread_count', response.data!);
        return response.data!;
      }

      // Fallback to cached count
      final cachedCount = await _localStorage.getInt('unread_count');
      return cachedCount ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      // Return cached count on error
      final cachedCount = await _localStorage.getInt('unread_count');
      return cachedCount ?? 0;
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(int messageId) async {
    try {
      final response = await _messageService.deleteMessage(messageId);
      if (response.isSuccess) {
        // Clear any cached status for this message
        await _localStorage.remove('message_${messageId}_delivered');
        await _localStorage.remove('message_${messageId}_read');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  /// Remove a message from a list (for UI updates after deletion)
  List<Message> removeMessageFromList(List<Message> messages, int messageId) {
    return messages.where((message) => message.id != messageId).toList();
  }

  /// Update message status in a list of messages
  List<Message> updateMessageStatus(List<Message> messages, int messageId, MessageStatus newStatus) {
    return messages.map((message) {
      if (message.id == messageId) {
        switch (newStatus) {
          case MessageStatus.delivered:
            return message.copyWith(deliveredAt: DateTime.now());
          case MessageStatus.read:
            return message.copyWith(readAt: DateTime.now(), deliveredAt: message.deliveredAt ?? DateTime.now());
          default:
            return message;
        }
      }
      return message;
    }).toList();
  }

  /// Mark all incoming messages in a conversation as read
  Future<List<int>> markConversationAsRead(List<Message> messages, int currentUserId) async {
    final unreadIncomingMessages = messages
        .where((message) => message.receiverId == currentUserId && message.readAt == null)
        .map((message) => message.id)
        .toList();

    if (unreadIncomingMessages.isEmpty) {
      return [];
    }

    return await markMultipleAsRead(unreadIncomingMessages);
  }

  /// Check if message needs status update based on cached data
  Future<Message> applyLocalStatusUpdates(Message message) async {
    try {
      // Check if we have local delivered status
      final deliveredTime = await _localStorage.getString('message_${message.id}_delivered');
      final readTime = await _localStorage.getString('message_${message.id}_read');

      Message updatedMessage = message;

      if (deliveredTime != null && message.deliveredAt == null) {
        updatedMessage = updatedMessage.copyWith(deliveredAt: DateTime.parse(deliveredTime));
      }

      if (readTime != null && message.readAt == null) {
        updatedMessage = updatedMessage.copyWith(readAt: DateTime.parse(readTime));
      }

      return updatedMessage;
    } catch (e) {
      return message;
    }
  }

  /// Clean up old cached status data (call periodically)
  Future<void> cleanupOldStatusCache() async {
    try {
      final keys = await _localStorage.getKeys();
      final messageStatusKeys = keys.where(
        (key) => key.startsWith('message_') && (key.endsWith('_delivered') || key.endsWith('_read')),
      );

      // Remove status data older than 7 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      for (String key in messageStatusKeys) {
        final timeString = await _localStorage.getString(key);
        if (timeString != null) {
          try {
            final time = DateTime.parse(timeString);
            if (time.isBefore(cutoffDate)) {
              await _localStorage.remove(key);
            }
          } catch (e) {
            // Remove invalid entries
            await _localStorage.remove(key);
          }
        }
      }
    } catch (e) {
      print('Error cleaning up status cache: $e');
    }
  }
}

/// Factory function to create MessageStatusService with dependency injection
MessageStatusService createMessageStatusService() {
  return MessageStatusService(serviceLocator.get<MessageService>(), serviceLocator.get<LocalStorageService>());
}

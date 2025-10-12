import 'dart:async';

/// Data class for conversation update events
class ConversationUpdate {
  final int? otherUserId;
  final int? unreadCount;
  final bool fullRefresh;

  const ConversationUpdate({
    this.otherUserId,
    this.unreadCount,
    this.fullRefresh = false,
  });
}

/// Simple event notifier for conversation updates
class ConversationUpdateNotifier {
  static final ConversationUpdateNotifier _instance = ConversationUpdateNotifier._internal();
  factory ConversationUpdateNotifier() => _instance;
  ConversationUpdateNotifier._internal();

  final StreamController<ConversationUpdate> _controller = StreamController<ConversationUpdate>.broadcast();

  /// Stream to listen for conversation update events
  Stream<ConversationUpdate> get updateStream => _controller.stream;

  /// Notify all listeners that conversations need to be refreshed
  void notifyConversationUpdate() {
    if (!_controller.isClosed) {
      _controller.add(const ConversationUpdate(fullRefresh: true));
    }
  }

  /// Notify that a specific conversation's unread count should be updated
  void notifyUnreadCountUpdate(int otherUserId, int unreadCount) {
    if (!_controller.isClosed) {
      _controller.add(ConversationUpdate(
        otherUserId: otherUserId,
        unreadCount: unreadCount,
      ));
    }
  }

  /// Clean up resources
  void dispose() {
    _controller.close();
  }
}

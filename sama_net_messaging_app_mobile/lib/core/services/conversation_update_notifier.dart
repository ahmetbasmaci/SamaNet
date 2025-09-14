import 'dart:async';

/// Simple event notifier for conversation updates
class ConversationUpdateNotifier {
  static final ConversationUpdateNotifier _instance = ConversationUpdateNotifier._internal();
  factory ConversationUpdateNotifier() => _instance;
  ConversationUpdateNotifier._internal();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  /// Stream to listen for conversation update events
  Stream<void> get updateStream => _controller.stream;

  /// Notify all listeners that conversations need to be refreshed
  void notifyConversationUpdate() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  /// Clean up resources
  void dispose() {
    _controller.close();
  }
}

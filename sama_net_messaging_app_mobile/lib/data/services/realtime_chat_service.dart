import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:signalr_core/signalr_core.dart';

import '../../core/constants/app_constants.dart';
import '../models/message.dart';

class MessageDeliveryUpdate {
  const MessageDeliveryUpdate({required this.messageId, required this.deliveredAt});

  final int messageId;
  final DateTime deliveredAt;
}

class MessageReadUpdate {
  const MessageReadUpdate({required this.messageId, required this.readAt, required this.readBy});

  final int messageId;
  final DateTime readAt;
  final int readBy;
}

/// Handles real-time chat communication via SignalR.
class RealtimeChatService {
  HubConnection? _connection;
  int? _currentUserId;
  bool _isConnecting = false;

  final StreamController<Message> _messageSentController = StreamController<Message>.broadcast();
  final StreamController<Message> _messageReceivedController = StreamController<Message>.broadcast();
  final StreamController<MessageDeliveryUpdate> _messageDeliveredController =
      StreamController<MessageDeliveryUpdate>.broadcast();
  final StreamController<MessageReadUpdate> _messageReadController = StreamController<MessageReadUpdate>.broadcast();
  final StreamController<int> _userOnlineController = StreamController<int>.broadcast();
  final StreamController<int> _userOfflineController = StreamController<int>.broadcast();

  Stream<Message> get onMessageSent => _messageSentController.stream;
  Stream<Message> get onMessageReceived => _messageReceivedController.stream;
  Stream<MessageDeliveryUpdate> get onMessageDelivered => _messageDeliveredController.stream;
  Stream<MessageReadUpdate> get onMessageRead => _messageReadController.stream;
  Stream<int> get onUserOnline => _userOnlineController.stream;
  Stream<int> get onUserOffline => _userOfflineController.stream;

  bool get isConnected => _connection?.state == HubConnectionState.connected;

  /// Prepare the service for a specific user without establishing a connection yet.
  void configureForUser(int userId) {
    _currentUserId = userId;
  }

  /// Establish the SignalR connection for the specified user.
  Future<void> connect({required int userId}) async {
    if (_connection != null && _currentUserId == userId) {
      if (_connection!.state == HubConnectionState.connected) {
        return;
      }
      if (_isConnecting) {
        await _waitForConnection();
        return;
      }
    }

    if (_isConnecting) {
      await _waitForConnection();
      if (_connection != null && _connection!.state == HubConnectionState.connected) {
        return;
      }
    }

    _isConnecting = true;

    try {
      if (_connection != null) {
        await _disposeConnection();
      }

      _currentUserId = userId;

      _connection = HubConnectionBuilder().withUrl(ApiConstants.chatHubUrl).withAutomaticReconnect().build();

      _registerHandlers();

      await _connection!.start();
      await _connection!.invoke('JoinChat', args: <Object?>[userId]);

      if (kDebugMode) {
        debugPrint('[SignalR] Successfully connected for user $userId');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[SignalR] Connection failed: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
      // Clean up on error
      await _disposeConnection();
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _waitForConnection() async {
    const maxWaitTime = Duration(seconds: 10);
    final stopwatch = Stopwatch()..start();

    while (_isConnecting) {
      if (stopwatch.elapsed >= maxWaitTime) {
        if (kDebugMode) {
          debugPrint('[SignalR] Wait for connection timed out after ${stopwatch.elapsed.inSeconds}s');
        }
        _isConnecting = false; // Force reset the flag
        throw TimeoutException('Connection attempt timed out');
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    stopwatch.stop();
  }

  Future<void> _disposeConnection() async {
    try {
      await _connection!.stop();
    } catch (_) {
      // Ignore stop errors; connection might already be closed.
    }
    _connection = null;
  }

  void _registerHandlers() {
    if (_connection == null) return;

    _connection!.onclose((error) {
      if (kDebugMode) {
        debugPrint('[SignalR] Connection closed: ${error?.toString() ?? 'no error'}');
      }
    });

    _connection!.onreconnected((_) async {
      final userId = _currentUserId;
      if (userId != null) {
        try {
          await _connection?.invoke('JoinChat', args: <Object?>[userId]);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[SignalR] Failed to re-join chat: $e');
          }
        }
      }
    });

    _connection!.on('MessageSent', (arguments) {
      final data = _safeParse(arguments);
      if (data != null) {
        _messageSentController.add(Message.fromJson(data));
      }
    });

    _connection!.on('MessageReceived', (arguments) {
      final data = _safeParse(arguments);
      if (data != null) {
        _messageReceivedController.add(Message.fromJson(data));
      }
    });

    _connection!.on('MessageDelivered', (arguments) {
      final data = _safeParse(arguments);
      final messageId = data?['messageId'] as int?;
      final deliveredAtRaw = data?['deliveredAt'] as String?;

      if (messageId != null && deliveredAtRaw != null) {
        _messageDeliveredController.add(
          MessageDeliveryUpdate(messageId: messageId, deliveredAt: DateTime.parse(deliveredAtRaw)),
        );
      }
    });

    _connection!.on('MessageRead', (arguments) {
      final data = _safeParse(arguments);
      final messageId = data?['messageId'] as int?;
      final readAtRaw = data?['readAt'] as String?;
      final readBy = data?['readBy'] as int?;

      if (messageId != null && readAtRaw != null && readBy != null) {
        _messageReadController.add(
          MessageReadUpdate(messageId: messageId, readAt: DateTime.parse(readAtRaw), readBy: readBy),
        );
      }
    });

    _connection!.on('UserOnline', (arguments) {
      final userId = _parseUserId(arguments);
      if (userId != null) {
        _userOnlineController.add(userId);
      }
    });

    _connection!.on('UserOffline', (arguments) {
      final userId = _parseUserId(arguments);
      if (userId != null) {
        _userOfflineController.add(userId);
      }
    });
  }

  Map<String, dynamic>? _safeParse(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) return null;
    final raw = arguments.first;

    if (raw == null) return null;

    if (raw is Map) {
      return raw.cast<String, dynamic>();
    }

    if (raw is String) {
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          return decoded.cast<String, dynamic>();
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  int? _parseUserId(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return null;
    }

    final raw = arguments.first;
    if (raw == null) return null;

    if (raw is int) {
      return raw;
    }

    if (raw is num) {
      return raw.toInt();
    }

    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      final userId = map['userId'];
      if (userId is int) return userId;
      if (userId is num) return userId.toInt();
      if (userId is String) return int.tryParse(userId);
    }

    if (raw is String) {
      return int.tryParse(raw);
    }

    return null;
  }

  Future<void> sendTextMessage({
    required int receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    await _ensureConnection();

    await _connection?.invoke('SendMessage', args: <Object?>[
      {
        'receiverId': receiverId,
        'content': content,
        'messageType': messageType,
      }
    ]);
  }

  Future<void> markMessageAsRead(int messageId) async {
    await _ensureConnection();
    await _connection?.invoke('MarkMessageAsRead', args: <Object?>[messageId]);
  }

  Future<void> startTyping(int receiverId) async {
    await _ensureConnection();
    await _connection?.invoke('StartTyping', args: <Object?>[receiverId]);
  }

  Future<void> stopTyping(int receiverId) async {
    await _ensureConnection();
    await _connection?.invoke('StopTyping', args: <Object?>[receiverId]);
  }

  Future<void> disconnect() async {
    await _disposeConnection();
  }

  Future<void> _ensureConnection() async {
    final userId = _currentUserId;
    if (userId == null) {
      throw StateError('Cannot establish SignalR connection without current user ID');
    }

    if (_connection == null || _connection!.state != HubConnectionState.connected) {
      await connect(userId: userId);
    }
  }

  Future<void> dispose() async {
    await _disposeConnection();
    await _messageSentController.close();
    await _messageReceivedController.close();
    await _messageDeliveredController.close();
    await _messageReadController.close();
    await _userOnlineController.close();
    await _userOfflineController.close();
  }
}

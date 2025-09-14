# Message Status Management Guide

## Overview
This guide explains how to use the comprehensive message status system that handles message delivery, read receipts, and unread counts in the SamaNet messaging app.

## 🔧 Backend API Endpoints

The backend provides these message status endpoints:

### Mark Message as Delivered
```http
PUT /api/messages/{messageId}/delivered
```

### Mark Message as Read  
```http
PUT /api/messages/{messageId}/read
```

### Get Unread Count
```http
GET /api/messages/unread-count
Headers: X-User-Id: {userId}
```

## 📱 Frontend Implementation

### 1. MessageStatusService

The `MessageStatusService` handles all message status operations:

```dart
// Get the service
final messageStatusService = serviceLocator.get<MessageStatusService>();

// Mark a message as delivered
await messageStatusService.markAsDelivered(messageId);

// Mark a message as read
await messageStatusService.markAsRead(messageId);

// Mark multiple messages as read
final successIds = await messageStatusService.markMultipleAsRead([1, 2, 3]);

// Get unread count
final unreadCount = await messageStatusService.getUnreadCount();

// Mark entire conversation as read
final markedIds = await messageStatusService.markConversationAsRead(messages, currentUserId);
```

### 2. MessageBubble Widget

The `MessageBubble` widget displays messages with proper status indicators:

```dart
MessageBubble(
  message: message,
  currentUser: currentUser,
  showTimestamp: true,
  onTap: () => _onMessageTap(message),
  onLongPress: () => _onMessageLongPress(message),
)
```

**Status Indicators:**
- ⏱️ `sending` - Clock icon (message being sent)
- ✓ `sent` - Single check mark
- ✓✓ `delivered` - Double check mark (gray)
- ✓✓ `read` - Double check mark (blue)
- ❌ `failed` - Error icon (red)

### 3. UnreadCountBadge Widget

Shows unread message count with badge:

```dart
UnreadCountBadge(
  userId: currentUserId,
  child: YourWidget(),
  padding: EdgeInsets.all(8),
)
```

### 4. Message Status Handling in MessagesPage

The `MessagesPage` automatically handles message status:

```dart
class _MessagesPageState extends State<MessagesPage> {
  late MessageStatusService _messageStatusService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadMessages(); // Automatically marks messages as read
  }

  // Messages are automatically marked as read when conversation opens
  Future<void> _markIncomingMessagesAsRead() async {
    final markedIds = await _messageStatusService.markConversationAsRead(
      _messages, 
      _currentUser!.id
    );
    // Update UI to reflect read status
  }
}
```

## 🎯 Usage Scenarios

### Scenario 1: Opening a Conversation
```dart
// When user opens a conversation, automatically mark as read
@override
void initState() {
  super.initState();
  _loadMessages(); // This will automatically mark incoming messages as read
}
```

### Scenario 2: Sending a Message
```dart
Future<void> _sendMessage() async {
  // Send message - it starts with 'sending' status
  setState(() {
    _messages.add(Message(/* ... with sending status */));
  });

  // Send to API
  final response = await _messageService.sendMessage(/* ... */);
  
  if (response.isSuccess) {
    // Message is now 'sent', will be marked 'delivered' by recipient's device
    // and 'read' when recipient opens the conversation
  }
}
```

### Scenario 3: Real-time Status Updates
```dart
// Listen for real-time status updates (if using WebSocket/SignalR)
void _onMessageStatusUpdate(int messageId, MessageStatus status) {
  setState(() {
    _messages = _messageStatusService.updateMessageStatus(
      _messages, 
      messageId, 
      status
    );
  });
}
```

### Scenario 4: Displaying Unread Count
```dart
// In conversation list
Widget build(BuildContext context) {
  return FutureBuilder<int>(
    future: _messageStatusService.getUnreadCount(),
    builder: (context, snapshot) {
      final unreadCount = snapshot.data ?? 0;
      return ListTile(
        title: Text(conversation.otherUser.username),
        trailing: unreadCount > 0 
          ? UnreadCountIndicator(count: unreadCount)
          : null,
      );
    },
  );
}
```

## 🔄 Automatic Features

### 1. Local Caching
- Message status is cached locally for offline support
- Status updates are applied even when offline
- Cache is synchronized when back online

### 2. Bulk Operations
- Multiple messages can be marked as read in one operation
- Entire conversations can be marked as read automatically
- Efficient API calls reduce server load

### 3. Status Progression
- Messages automatically progress: `sending` → `sent` → `delivered` → `read`
- `delivered` status is set automatically when marking as `read`
- Failed messages are properly handled

## 📊 Message Status Flow

```
[User sends message]
        ↓
   Status: sending
        ↓
[API call successful]
        ↓
    Status: sent
        ↓
[Recipient's device receives]
        ↓
  Status: delivered
        ↓
[Recipient opens conversation]
        ↓
    Status: read
```

## 🛠️ Advanced Usage

### Custom Status Handling
```dart
// Apply custom status logic
Future<Message> _processMessageStatus(Message message) async {
  // Apply local cached status updates
  message = await _messageStatusService.applyLocalStatusUpdates(message);
  
  // Custom business logic
  if (message.status == MessageStatus.sent) {
    // Auto-mark as delivered after 5 seconds (simulation)
    Timer(Duration(seconds: 5), () {
      _messageStatusService.markAsDelivered(message.id);
    });
  }
  
  return message;
}
```

### Cleanup Old Data
```dart
// Periodically clean up old cached status data
await _messageStatusService.cleanupOldStatusCache();
```

### Error Handling
```dart
try {
  await _messageStatusService.markAsRead(messageId);
} catch (e) {
  // Handle network errors gracefully
  // Status will be applied from local cache when available
  print('Failed to mark as read: $e');
}
```

## 🎨 UI Customization

### Custom Status Icons
```dart
Widget _buildCustomStatusIcon(MessageStatus status) {
  switch (status) {
    case MessageStatus.sending:
      return CircularProgressIndicator(strokeWidth: 2);
    case MessageStatus.sent:
      return Icon(Icons.check, color: Colors.grey);
    case MessageStatus.delivered:
      return Icon(Icons.done_all, color: Colors.grey);
    case MessageStatus.read:
      return Icon(Icons.done_all, color: Colors.blue);
    case MessageStatus.failed:
      return Icon(Icons.error, color: Colors.red);
  }
}
```

### Custom Unread Badge
```dart
UnreadCountIndicator(
  count: unreadCount,
  size: 24,
  backgroundColor: Theme.of(context).primaryColor,
  textColor: Colors.white,
)
```

## 🔍 Debugging

### Check Message Status
```dart
print('Message ${message.id} status: ${message.status}');
print('Sent: ${message.sentAt}');
print('Delivered: ${message.deliveredAt}');
print('Read: ${message.readAt}');
```

### Monitor Unread Count
```dart
// Add this to debug unread count issues
Timer.periodic(Duration(seconds: 10), (timer) async {
  final count = await _messageStatusService.getUnreadCount();
  print('Current unread count: $count');
});
```

This comprehensive message status system provides real-time feedback, improves user experience, and handles all edge cases including offline scenarios and error recovery!

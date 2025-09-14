import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sama_net_messaging_app_mobile/data/services/message_service.dart';
import '../../core/constants/arabic_strings.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/message_status_service.dart';
import '../widgets/message_bubble.dart';
import '../../core/di/service_locator.dart';

/// Messages page for chatting with a specific user
class MessagesPage extends StatefulWidget {
  final User chatUser;

  const MessagesPage({super.key, required this.chatUser});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late LocalStorageService _localStorage;
  late MessageService _messageService;
  late MessageStatusService _messageStatusService;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadCurrentUser();
    _loadMessages();
  }

  void _initializeServices() {
    _localStorage = serviceLocator.get<LocalStorageService>();
    _messageService = serviceLocator.get<MessageService>();
    _messageStatusService = serviceLocator.get<MessageStatusService>();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Load cached user data instead of just user ID
      final cachedUser = await _localStorage.getCurrentUser();
      if (cachedUser != null) {
        setState(() {
          _currentUser = cachedUser;
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      // Load conversation messages
      final response = await _messageService.getConversation(otherUserId: widget.chatUser.id);
      if (response.isSuccess && response.data != null) {
        List<Message> messages = response.data!;

        // Apply local status updates from cache
        for (int i = 0; i < messages.length; i++) {
          messages[i] = await _messageStatusService.applyLocalStatusUpdates(messages[i]);
        }

        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        // Mark incoming messages as read when conversation is opened
        if (_currentUser != null) {
          await _markIncomingMessagesAsRead();
        }
      } else {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Mark all incoming unread messages as read
  Future<void> _markIncomingMessagesAsRead() async {
    if (_currentUser == null) return;

    try {
      final markedIds = await _messageStatusService.markConversationAsRead(_messages, _currentUser!.id);

      if (markedIds.isNotEmpty) {
        // Update local message status
        setState(() {
          for (int messageId in markedIds) {
            _messages = _messageStatusService.updateMessageStatus(_messages, messageId, MessageStatus.read);
          }
        });
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      // Create new message
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        senderId: _currentUser?.id ?? 1,
        receiverId: widget.chatUser.id,
        messageType: 'text',
        content: messageText,
        sentAt: DateTime.now(),
      );

      // Add message to list immediately (optimistic update)
      setState(() {
        _messages.add(newMessage);
      });

      _scrollToBottom();

      // In real app, send to API:
      await _messageService.sendMessage(receiverId: widget.chatUser.id, content: newMessage.content ?? "");

      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = newMessage.copyWith(deliveredAt: DateTime.now());
          }
        });
      }
    } catch (e) {
      // Handle error - maybe show a retry option
      if (kDebugMode) {
        print('Error sending message: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                widget.chatUser.initials,
                style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chatUser.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    widget.chatUser.isOnline ? ArabicStrings.online : ArabicStrings.offline,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.chatUser.isOnline ? Colors.green : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Implement voice call
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Implement video call
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearChat();
                  break;
                case 'block':
                  _blockUser();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'clear', child: Text(ArabicStrings.delete)),
              const PopupMenuItem(value: 'block', child: Text('حظر المستخدم')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      ArabicStrings.noMessages,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageBubble(
                        message: message,
                        currentUser: _currentUser,
                        showTimestamp: true,
                        onTap: () => _onMessageTap(message),
                        onLongPress: () => _onMessageLongPress(message),
                      );
                    },
                  ),
          ),

          // Message Input
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  /// Handle message tap
  void _onMessageTap(Message message) {
    // Handle message tap - could show message details, etc.
    if (kDebugMode) {
      print('Tapped message: ${message.id}');
    }
  }

  /// Handle message long press
  void _onMessageLongPress(Message message) {
    // Handle message long press - could show context menu
    _showMessageContextMenu(message);
  }

  /// Show message context menu
  void _showMessageContextMenu(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.senderId == _currentUser?.id) ...[
            ListTile(
              leading: const Icon(Icons.info),
              title: Text('Message Info'),
              onTap: () {
                Navigator.pop(context);
                _showMessageInfo(message);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text('Copy'),
            onTap: () {
              Navigator.pop(context);
              // Copy message content to clipboard
            },
          ),
          if (message.senderId == _currentUser?.id) ...[
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(message);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Show message information dialog
  void _showMessageInfo(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Status', message.status.value),
            _buildInfoRow('Sent', DateTimeUtils.formatMessageTime(message.sentAt)),
            if (message.deliveredAt != null)
              _buildInfoRow('Delivered', DateTimeUtils.formatMessageTime(message.deliveredAt!)),
            if (message.readAt != null) _buildInfoRow('Read', DateTimeUtils.formatMessageTime(message.readAt!)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  /// Delete a message
  void _deleteMessage(Message message) {
    // Implement message deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performMessageDeletion(message);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Perform the actual message deletion
  Future<void> _performMessageDeletion(Message message) async {
    try {
      // Call the delete API
      final success = await _messageStatusService.deleteMessage(message.id);

      if (success) {
        // Remove message from local list
        setState(() {
          _messages = _messageStatusService.removeMessageFromList(_messages, message.id);
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message deleted successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete message. You can only delete your own messages.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting message: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(icon: const Icon(Icons.attach_file), onPressed: _showAttachmentOptions),

          // Message input field
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: ArabicStrings.typeMessage,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          Container(
            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
            child: IconButton(
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                      ),
                    )
                  : Icon(Icons.send, color: theme.colorScheme.onPrimary),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(ArabicStrings.camera),
              onTap: () {
                Navigator.pop(context);
                // Implement camera functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(ArabicStrings.gallery),
              onTap: () {
                Navigator.pop(context);
                // Implement gallery functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: Text(ArabicStrings.selectFile),
              onTap: () {
                Navigator.pop(context);
                // Implement file selection functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ArabicStrings.delete),
        content: const Text('هل تريد حذف جميع الرسائل؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(ArabicStrings.cancel)),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              Navigator.pop(context);
            },
            child: Text(ArabicStrings.delete),
          ),
        ],
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حظر المستخدم'),
        content: Text('هل تريد حظر ${widget.chatUser.name}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(ArabicStrings.cancel)),
          TextButton(
            onPressed: () {
              // Implement block functionality
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('حظر'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/arabic_strings.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import '../../data/services/local_storage_service.dart';
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
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await _localStorage.getUserId();
    if (userId != null) {
      // In a real app, you'd fetch the current user data
      // For now, create a mock current user
      setState(() {
        _currentUser = User(id: userId, username: 'currentUser', phoneNumber: '1234567890', createdAt: DateTime.now());
      });
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      // Mock messages for demo - in real app, load from API
      await Future.delayed(const Duration(milliseconds: 500));

      if (kDebugMode) {
        setState(() {
          _messages = _generateMockMessages();
          _isLoading = false;
        });
      } else {
        // Real implementation would use:
        // final response = await _messageService.getMessages(widget.chatUser.id);
        setState(() {
          _messages = [];
          _isLoading = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Message> _generateMockMessages() {
    final now = DateTime.now();
    return [
      Message(
        id: 1,
        senderId: widget.chatUser.id,
        receiverId: _currentUser?.id ?? 1,
        messageType: 'text',
        content: 'مرحبا! كيف حالك؟',
        sentAt: now.subtract(const Duration(hours: 2)),
        deliveredAt: now.subtract(const Duration(hours: 2, minutes: -1)),
        readAt: now.subtract(const Duration(hours: 1, minutes: 30)),
        senderUsername: widget.chatUser.username,
      ),
      Message(
        id: 2,
        senderId: _currentUser?.id ?? 1,
        receiverId: widget.chatUser.id,
        messageType: 'text',
        content: 'أهلاً وسهلاً! أنا بخير، شكراً لك',
        sentAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        deliveredAt: now.subtract(const Duration(hours: 1, minutes: 44)),
        readAt: now.subtract(const Duration(hours: 1, minutes: 30)),
      ),
      Message(
        id: 3,
        senderId: widget.chatUser.id,
        receiverId: _currentUser?.id ?? 1,
        messageType: 'text',
        content: 'هل لديك وقت للاجتماع غداً؟',
        sentAt: now.subtract(const Duration(minutes: 30)),
        deliveredAt: now.subtract(const Duration(minutes: 29)),
        readAt: now.subtract(const Duration(minutes: 25)),
        senderUsername: widget.chatUser.username,
      ),
      Message(
        id: 4,
        senderId: _currentUser?.id ?? 1,
        receiverId: widget.chatUser.id,
        messageType: 'text',
        content: 'نعم، بالطبع. في أي وقت؟',
        sentAt: now.subtract(const Duration(minutes: 5)),
        deliveredAt: now.subtract(const Duration(minutes: 4)),
      ),
    ];
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
      // await _messageService.sendMessage(newMessage);

      // Simulate delivery status update
      await Future.delayed(const Duration(seconds: 1));
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
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Message Input
          _buildMessageInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final theme = Theme.of(context);
    final isMe = message.senderId == _currentUser?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                widget.chatUser.initials,
                style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.content != null)
                    Text(
                      message.content!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      ),
                    ),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateTimeUtils.formatMessageTime(message.sentAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isMe
                              ? theme.colorScheme.onPrimary.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),

                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.readAt != null
                              ? Icons.done_all
                              : message.deliveredAt != null
                              ? Icons.done_all
                              : Icons.done,
                          size: 16,
                          color: message.readAt != null ? Colors.blue : theme.colorScheme.onPrimary.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
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

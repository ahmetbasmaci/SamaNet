import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sama_net_messaging_app_mobile/data/services/message_service.dart';
import '../../core/constants/arabic_strings.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/message_status_service.dart';
import '../../data/services/file_service.dart';
import '../../data/services/realtime_chat_service.dart';
import '../../data/services/user_block_service.dart';
import '../widgets/message_bubble.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/conversation_update_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

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
  late FileService _fileService;
  late ConversationUpdateNotifier _updateNotifier;
  late RealtimeChatService _realtimeChatService;
  late UserBlockService _userBlockService;
  StreamSubscription<Message>? _messageReceivedSubscription;
  StreamSubscription<Message>? _messageSentSubscription;
  StreamSubscription<MessageDeliveryUpdate>? _messageDeliveredSubscription;
  StreamSubscription<MessageReadUpdate>? _messageReadSubscription;
  final ImagePicker _imagePicker = ImagePicker();
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploadingFile = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initPage();
  }

  Future<void> _initPage() async {
    await _loadCurrentUser();
    await _loadMessages();
    await _initializeRealtime();
  }

  void _initializeServices() {
    _localStorage = serviceLocator.get<LocalStorageService>();
    _messageService = serviceLocator.get<MessageService>();
    _messageStatusService = serviceLocator.get<MessageStatusService>();
    _fileService = serviceLocator.get<FileService>();
    _updateNotifier = serviceLocator.get<ConversationUpdateNotifier>();
    _realtimeChatService = serviceLocator.get<RealtimeChatService>();
    _userBlockService = serviceLocator.get<UserBlockService>();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _disposeRealtimeListeners();
    // Notify conversations to update when leaving this page
    _updateNotifier.notifyConversationUpdate();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Load cached user data instead of just user ID
      final cachedUser = await _localStorage.getCurrentUser();
      if (cachedUser != null) {
        if (mounted) {
          setState(() {
            _currentUser = cachedUser;
          });
        } else {
          _currentUser = cachedUser;
        }
        _realtimeChatService.configureForUser(cachedUser.id);
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

        messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

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

  Future<void> _initializeRealtime() async {
    if (_currentUser == null) return;

    try {
      await _realtimeChatService.connect(userId: _currentUser!.id);
      _registerRealtimeListeners();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Failed to initialize realtime connection: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  void _registerRealtimeListeners() {
    _messageReceivedSubscription?.cancel();
    _messageSentSubscription?.cancel();
    _messageDeliveredSubscription?.cancel();
    _messageReadSubscription?.cancel();

    _messageReceivedSubscription = _realtimeChatService.onMessageReceived.listen(_handleRealtimeMessageReceived);
    _messageSentSubscription = _realtimeChatService.onMessageSent.listen(_handleRealtimeMessageSent);
    _messageDeliveredSubscription = _realtimeChatService.onMessageDelivered.listen(_handleMessageDelivered);
    _messageReadSubscription = _realtimeChatService.onMessageRead.listen(_handleMessageRead);
  }

  void _disposeRealtimeListeners() {
    _messageReceivedSubscription?.cancel();
    _messageSentSubscription?.cancel();
    _messageDeliveredSubscription?.cancel();
    _messageReadSubscription?.cancel();

    _messageReceivedSubscription = null;
    _messageSentSubscription = null;
    _messageDeliveredSubscription = null;
    _messageReadSubscription = null;
  }

  void _handleRealtimeMessageReceived(Message message) {
    if (_currentUser == null) return;

    final isCurrentConversation = message.senderId == widget.chatUser.id && message.receiverId == _currentUser!.id;

    if (!isCurrentConversation) {
      // Notify other parts of the app (e.g., conversation list) to refresh
      _updateNotifier.notifyConversationUpdate();
      return;
    }

    final existingIndex = _messages.indexWhere((m) => m.id == message.id);

    if (!mounted) return;

    if (existingIndex == -1) {
      final updatedMessages = [..._messages, message]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      setState(() {
        _messages = updatedMessages;
      });
    } else {
      setState(() {
        _messages[existingIndex] = message;
      });
    }

    _scrollToBottom();
    _updateNotifier.notifyConversationUpdate();

    unawaited(
      _realtimeChatService.markMessageAsRead(message.id).catchError((error) {
        if (kDebugMode) {
          debugPrint('Failed to mark message as read via realtime: $error');
        }
      }),
    );

    unawaited(_messageStatusService.markAsRead(message.id));
  }

  void _handleRealtimeMessageSent(Message message) {
    if (_currentUser == null) return;

    final isFromCurrentUser = message.senderId == _currentUser!.id;
    if (!isFromCurrentUser) {
      return;
    }

    final isCurrentConversation = message.receiverId == widget.chatUser.id;
    if (!isCurrentConversation) {
      _updateNotifier.notifyConversationUpdate();
      return;
    }

    final existingIndex = _messages.indexWhere((m) => m.id == message.id);

    if (!mounted) return;

    if (existingIndex == -1) {
      final updatedMessages = [..._messages, message]..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      setState(() {
        _messages = updatedMessages;
      });
    } else {
      setState(() {
        _messages[existingIndex] = message;
      });
    }

    _scrollToBottom();
    _updateNotifier.notifyConversationUpdate();
  }

  void _handleMessageDelivered(MessageDeliveryUpdate update) {
    final index = _messages.indexWhere((message) => message.id == update.messageId);
    if (index == -1 || !mounted) return;

    final existing = _messages[index];
    if (existing.deliveredAt != null && existing.deliveredAt!.isAfter(update.deliveredAt)) {
      return;
    }

    setState(() {
      _messages[index] = existing.copyWith(deliveredAt: update.deliveredAt);
    });
  }

  void _handleMessageRead(MessageReadUpdate update) {
    final index = _messages.indexWhere((message) => message.id == update.messageId);
    if (index == -1 || !mounted) return;

    final existing = _messages[index];
    if (_currentUser != null && existing.senderId != _currentUser!.id) {
      return;
    }

    setState(() {
      _messages[index] = existing.copyWith(
        readAt: update.readAt,
        deliveredAt: existing.deliveredAt ?? update.readAt,
      );
    });

    _updateNotifier.notifyConversationUpdate();
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

        // Notify that conversations need to be updated (unread count changed)
        _updateNotifier.notifyConversationUpdate();

        if (_realtimeChatService.isConnected) {
          for (final messageId in markedIds) {
            unawaited(
              _realtimeChatService.markMessageAsRead(messageId).catchError((error) {
                if (kDebugMode) {
                  debugPrint('Failed to notify read status via realtime: $error');
                }
              }),
            );
          }
        }
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

  Future<void> _ensureRealtimeConnection() async {
    if (_currentUser == null) {
      await _loadCurrentUser();
    }

    if (_currentUser == null) {
      throw StateError('Cannot establish realtime connection without current user');
    }

    if (_realtimeChatService.isConnected) {
      return;
    }

    await _realtimeChatService.connect(userId: _currentUser!.id);
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _ensureRealtimeConnection();
      await _realtimeChatService.sendTextMessage(
        receiverId: widget.chatUser.id,
        content: messageText,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Realtime send failed, attempting fallback: $e');
      }

      final fallbackResponse = await _messageService.sendMessage(receiverId: widget.chatUser.id, content: messageText);

      if (fallbackResponse.isSuccess && fallbackResponse.data != null) {
        if (mounted) {
          setState(() {
            final updatedMessages = [..._messages, fallbackResponse.data!]
              ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
            _messages = updatedMessages;
          });
          _scrollToBottom();
        }

        _updateNotifier.notifyConversationUpdate();
      } else {
        if (mounted) {
          _messageController.text = messageText;
          _showErrorSnackBar('خطأ في إرسال الرسالة: ${fallbackResponse.error ?? e.toString()}');
        }
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
    final statusText = widget.chatUser.isOnline
        ? 'متصل الآن'
        : widget.chatUser.lastSeen != null
            ? 'آخر ظهور: ${DateTimeUtils.formatChatListTime(widget.chatUser.lastSeen!)}'
            : 'غير متصل';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatUser.name,
              style: theme.textTheme.titleMedium,
            ),
            Text(
              statusText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.7),
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
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'clear', child: Text(ArabicStrings.delete)),
              PopupMenuItem(value: 'block', child: Text('حظر المستخدم')),
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
                          style:
                              theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
              title: const Text('معلومات الرسالة'),
              onTap: () {
                Navigator.pop(context);
                _showMessageInfo(message);
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('نسخ'),
            onTap: () {
              Navigator.pop(context);
              // Copy message content to clipboard
            },
          ),
          if (message.senderId == _currentUser?.id) ...[
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('حذف'),
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
        title: const Text('معلومات الرسالة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('الحالة', message.status.value),
            _buildInfoRow('تم الإرسال', DateTimeUtils.formatMessageTime(message.sentAt)),
            if (message.deliveredAt != null)
              _buildInfoRow('تم التسليم', DateTimeUtils.formatMessageTime(message.deliveredAt!)),
            if (message.readAt != null) _buildInfoRow('تم القراءة', DateTimeUtils.formatMessageTime(message.readAt!)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
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
        title: const Text('حذف الرسالة'),
        content: const Text('هل أنت متأكد من أنك تريد حذف هذه الرسالة لنفسك؟ سيؤدي هذا إلى إزالتها من عرضك فقط.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performMessageDeletion(message);
            },
            child: const Text('حذف لي'),
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
            const SnackBar(
                content: Text('تم حذف الرسالة لك'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في حذف الرسالة. يمكنك حذف الرسائل من محادثاتك فقط.'),
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
            content: Text('خطأ في حذف الرسالة: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _isUploadingFile ? null : _showAttachmentOptions,
          ),

          // Message input field
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Upload progress indicator
                if (_isUploadingFile)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text('جاري رفع الملف...', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                // Text input
                TextField(
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
              ],
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
              onPressed: (_isSending || _isUploadingFile) ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'إرسال مرفق',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Options Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  context: context,
                  icon: Icons.camera_alt,
                  label: 'كاميرا',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
                _buildAttachmentOption(
                  context: context,
                  icon: Icons.videocam,
                  label: 'فيديو',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideoFromCamera();
                  },
                ),
                _buildAttachmentOption(
                  context: context,
                  icon: Icons.insert_drive_file,
                  label: 'ملف',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    // Prevent double-sending
    if (_isUploadingFile) {
      debugPrint('[MessagesPage::_pickImageFromCamera] Already uploading a file, ignoring request');
      return;
    }

    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showPermissionDeniedDialog('الكاميرا');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _promptForCaptionAndSend(image.path, 'image');
      }
    } catch (e) {
      debugPrint('[MessagesPage::_pickImageFromCamera] $e');
      _showErrorSnackBar('خطأ في التقاط الصورة: ${e.toString()}');
    }
  }

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    // Prevent double-sending
    if (_isUploadingFile) {
      debugPrint('[MessagesPage::_pickImageFromGallery] Already uploading a file, ignoring request');
      return;
    }

    try {
      // Request photo permission
      final photoStatus = await Permission.photos.request();
      if (!photoStatus.isGranted) {
        _showPermissionDeniedDialog('المعرض');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _promptForCaptionAndSend(image.path, 'image');
      }
    } catch (e) {
      debugPrint('[MessagesPage::_pickImageFromGallery] $e');
      _showErrorSnackBar('خطأ في اختيار الصورة: ${e.toString()}');
    }
  }

  /// Pick video from camera
  Future<void> _pickVideoFromCamera() async {
    // Prevent double-sending
    if (_isUploadingFile) {
      debugPrint('[MessagesPage::_pickVideoFromCamera] Already uploading a file, ignoring request');
      return;
    }

    try {
      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showPermissionDeniedDialog('الكاميرا');
        return;
      }

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        await _uploadAndSendFile(video.path, 'video');
      }
    } catch (e) {
      debugPrint('[MessagesPage::_pickVideoFromCamera] $e');
      _showErrorSnackBar('خطأ في تسجيل الفيديو: ${e.toString()}');
    }
  }

  /// Pick video from gallery
  Future<void> _pickVideoFromGallery() async {
    // Prevent double-sending
    if (_isUploadingFile) {
      debugPrint('[MessagesPage::_pickVideoFromGallery] Already uploading a file, ignoring request');
      return;
    }

    try {
      // Request photo permission
      final photoStatus = await Permission.photos.request();
      if (!photoStatus.isGranted) {
        _showPermissionDeniedDialog('المعرض');
        return;
      }

      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        await _uploadAndSendFile(video.path, 'video');
      }
    } catch (e) {
      debugPrint('[MessagesPage::_pickVideoFromGallery] $e');
      _showErrorSnackBar('خطأ في اختيار الفيديو: ${e.toString()}');
    }
  }

  /// Pick file from device
  Future<void> _pickFile() async {
    // Prevent double-sending
    if (_isUploadingFile) {
      debugPrint('[MessagesPage::_pickFile] Already uploading a file, ignoring request');
      return;
    }

    try {
      // Request storage permission
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        _showPermissionDeniedDialog('التخزين');
        return;
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        allowedExtensions: null,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final filePath = file.path!;

        // Check file size (10MB limit)
        final fileSize = await _fileService.getFileSize(filePath);
        if (!_fileService.isFileSizeValid(fileSize)) {
          _showErrorSnackBar('حجم الملف كبير جداً. الحد الأقصى 10 ميجابايت');
          return;
        }

        // Check if file type is supported
        if (!_fileService.isFileTypeSupported(filePath)) {
          _showErrorSnackBar('نوع الملف غير مدعوم');
          return;
        }

        final messageType = _fileService.getMessageTypeFromFile(filePath);
        await _uploadAndSendFile(filePath, messageType);
      }
    } catch (e) {
      debugPrint('[MessagesPage::_pickFile] $e');
      _showErrorSnackBar('خطأ في اختيار الملف: ${e.toString()}');
    }
  }

  /// Prompt user for caption before sending an image
  Future<void> _promptForCaptionAndSend(String filePath, String messageType) async {
    if (!mounted) return;

    String captionText = '';

    final caption = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(filePath),
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 220,
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        maxLines: 3,
                        onChanged: (value) => setSheetState(() => captionText = value),
                        decoration: const InputDecoration(
                          labelText: 'أضف وصفًا (اختياري)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(null),
                              child: const Text(ArabicStrings.cancel),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(captionText.trim()),
                              child: const Text(ArabicStrings.send),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (caption == null || !mounted) {
      return; // User cancelled.
    }

    // Pass empty string if caption is empty, so we don't add file description
    await _uploadAndSendFile(filePath, messageType, caption: caption.isEmpty ? '' : caption);
  }

  /// Upload file and send message
  Future<void> _uploadAndSendFile(String filePath, String messageType, {String? caption}) async {
    if (_currentUser == null) return;

    // Prevent double-sending
    if (_isUploadingFile) {
      debugPrint('[MessagesPage::_uploadAndSendFile] Already uploading a file, aborting');
      return;
    }

    setState(() => _isUploadingFile = true);

    try {
      try {
        await _ensureRealtimeConnection();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Continuing without realtime connection for attachment: $e');
        }
      }

      final messageContent = _resolveAttachmentCaption(filePath, messageType, caption);

      final messageResponse = await _messageService.sendMessageWithAttachment(
        receiverId: widget.chatUser.id,
        content: messageContent, // Send as-is, empty is now allowed by API
        messageType: messageType,
        filePath: filePath,
      );

      if (messageResponse.isSuccess && messageResponse.data != null) {
        setState(() {
          _messages.add(messageResponse.data!);
        });

        _scrollToBottom();
        _updateNotifier.notifyConversationUpdate();
      } else {
        _showErrorSnackBar('فشل في إرسال الرسالة: ${messageResponse.error ?? ''}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error sending file message: $e');
      debugPrintStack(stackTrace: stackTrace);
      _showErrorSnackBar('خطأ في إرسال الملف: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
    }
  }

  String _resolveAttachmentCaption(String filePath, String messageType, String? caption) {
    // If caption is explicitly empty string (user chose to send without caption), return empty
    if (caption == '') {
      return '';
    }

    final trimmed = caption?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      return trimmed;
    }

    // For images with no caption, return empty string
    // For other files (videos, documents), return file description
    if (messageType == 'image') {
      return '';
    }

    return _getFileDescription(filePath, messageType);
  }

  /// Get file description based on type
  String _getFileDescription(String filePath, String messageType) {
    final fileName = filePath.split('/').last;
    switch (messageType) {
      case 'image':
        return 'صورة: $fileName';
      case 'video':
        return 'فيديو: $fileName';
      case 'audio':
        return 'ملف صوتي: $fileName';
      default:
        return 'ملف: $fileName';
    }
  }

  /// Show permission denied dialog with shortcut to app settings
  void _showPermissionDeniedDialog(String permissionType) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إذن مرفوض'),
        content: Text('لا يمكن الوصول إلى $permissionType. يرجى منح الإذن من إعدادات التطبيق.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final opened = await openAppSettings();

              if (!opened && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تعذر فتح إعدادات التطبيق.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(ArabicStrings.delete),
        content: const Text('هل تريد حذف جميع الرسائل؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text(ArabicStrings.cancel)),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              Navigator.pop(context);
            },
            child: const Text(ArabicStrings.delete),
          ),
        ],
      ),
    );
  }

  void _blockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حظر المستخدم'),
        content: Text('هل تريد حظر ${widget.chatUser.name}؟ لن تتمكن من إرسال أو استقبال رسائل من هذا المستخدم.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(ArabicStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حظر', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || _currentUser == null) return;

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      final response = await _userBlockService.blockUser(
        blockerId: _currentUser!.id,
        blockedUserId: widget.chatUser.id,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (response.isSuccess && response.data != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data!.message),
              backgroundColor: Colors.green,
            ),
          );
          // Close the messages page
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error ?? 'فشل حظر المستخدم'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حظر المستخدم: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

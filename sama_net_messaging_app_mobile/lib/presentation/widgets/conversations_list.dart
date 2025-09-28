import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../data/services/message_service.dart';
import 'conversation_tile.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/realtime_chat_service.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import '../../core/services/conversation_update_notifier.dart';
import 'dart:async';

/// Widget to display list of conversations
class ConversationsList extends StatefulWidget {
  final VoidCallback? onConversationUpdated;

  const ConversationsList({super.key, this.onConversationUpdated});

  @override
  State<ConversationsList> createState() => _ConversationsListState();
}

class _ConversationsListState extends State<ConversationsList> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<Conversation> _conversations = [];
  late LocalStorageService _localStorage;
  late MessageService _messageService;
  late RealtimeChatService _realtimeChatService;
  late ConversationUpdateNotifier _updateNotifier;
  User? _currentUser;
  StreamSubscription<void>? _updateSubscription;
  StreamSubscription<Message>? _messageReceivedSubscription;
  StreamSubscription<Message>? _messageSentSubscription;
  Timer? _refreshDebounceTimer;
  bool _realtimeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadCurrentUser();
    _setupUpdateListener();
    // Listen for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateSubscription?.cancel();
    _messageReceivedSubscription?.cancel();
    _messageSentSubscription?.cancel();
    _refreshDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh conversations when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      refreshConversations();
    }
  }

  void _initializeServices() {
    _localStorage = serviceLocator.get<LocalStorageService>();
    _messageService = serviceLocator.get<MessageService>();
    _realtimeChatService = serviceLocator.get<RealtimeChatService>();
    _updateNotifier = serviceLocator.get<ConversationUpdateNotifier>();
  }

  void _setupUpdateListener() {
    _updateSubscription = _updateNotifier.updateStream.listen((_) {
      // Refresh conversations when update is triggered
      refreshConversations();
    });
  }

  /// Public method to refresh conversations (can be called from parent widgets)
  Future<void> refreshConversations({bool showLoadingIndicator = false}) async {
    await _loadConversations(showLoadingIndicator: showLoadingIndicator);
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Load cached user data instead of just user ID
      final cachedUser = await _localStorage.getCurrentUser();
      if (cachedUser != null) {
        setState(() {
          _currentUser = cachedUser;
        });
        await _initializeRealtime();
        await _loadConversations(showLoadingIndicator: true);
      }
    } catch (e) {
      print('Error loading current user: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeRealtime() async {
    if (_currentUser == null || _realtimeInitialized) return;

    _realtimeInitialized = true;
    _realtimeChatService.configureForUser(_currentUser!.id);

    try {
      await _realtimeChatService.connect(userId: _currentUser!.id);
    } catch (e) {
      print('Error connecting to realtime service: $e');
    }

    _messageReceivedSubscription?.cancel();
    _messageSentSubscription?.cancel();

    _messageReceivedSubscription =
        _realtimeChatService.onMessageReceived.listen(_handleRealtimeIncomingMessage);
    _messageSentSubscription = _realtimeChatService.onMessageSent.listen(_handleRealtimeOutgoingMessage);
  }

  Future<void> _loadConversations({bool showLoadingIndicator = true}) async {
    if (_currentUser == null) return;

    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final response = await _messageService.getRecentConversations(limit: 20);
      if (response.isSuccess && response.data != null) {
        final conversations = [...response.data!]
          ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      } else if (showLoadingIndicator) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
      if (showLoadingIndicator) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleRealtimeIncomingMessage(Message message) {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null || message.receiverId != currentUserId) return;

    _applyRealtimeUpdate(message: message, otherUserId: message.senderId, isIncoming: true);
  }

  void _handleRealtimeOutgoingMessage(Message message) {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null || message.senderId != currentUserId) return;

    _applyRealtimeUpdate(message: message, otherUserId: message.receiverId, isIncoming: false);
  }

  void _applyRealtimeUpdate({
    required Message message,
    required int otherUserId,
    required bool isIncoming,
  }) {
    final index = _conversations.indexWhere((conversation) => conversation.otherUser.id == otherUserId);

    if (index != -1) {
      final existing = _conversations[index];
      final updatedConversation = existing.copyWith(
        lastMessage: message,
        unreadCount: isIncoming ? existing.unreadCount + 1 : existing.unreadCount,
        lastActivity: message.sentAt,
      );

      if (!mounted) return;

      setState(() {
        final updatedList = [..._conversations];
        updatedList.removeAt(index);
        updatedList.insert(0, updatedConversation);
        _conversations = updatedList;
      });
    } else {
      _scheduleDebouncedRefresh();
      return;
    }

    _scheduleDebouncedRefresh();
  }

  void _scheduleDebouncedRefresh() {
    _refreshDebounceTimer?.cancel();
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      refreshConversations(showLoadingIndicator: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد محادثات',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ محادثة جديدة باستخدام البحث',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadConversations(showLoadingIndicator: false),
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return ConversationTile(
            conversation: conversation,
            onConversationUpdated: () async {
              // Refresh conversations when user returns from MessagesPage
              await refreshConversations();
              // Call parent callback if provided
              widget.onConversationUpdated?.call();
            },
          );
        },
      ),
    );
  }
}

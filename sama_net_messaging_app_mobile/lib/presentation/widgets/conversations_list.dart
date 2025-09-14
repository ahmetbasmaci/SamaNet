import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../data/services/message_service.dart';
import 'conversation_tile.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/models/conversation.dart';
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
  late ConversationUpdateNotifier _updateNotifier;
  User? _currentUser;
  StreamSubscription<void>? _updateSubscription;

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
    _updateNotifier = serviceLocator.get<ConversationUpdateNotifier>();
  }

  void _setupUpdateListener() {
    _updateSubscription = _updateNotifier.updateStream.listen((_) {
      // Refresh conversations when update is triggered
      refreshConversations();
    });
  }

  /// Public method to refresh conversations (can be called from parent widgets)
  Future<void> refreshConversations() async {
    await _loadConversations();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Load cached user data instead of just user ID
      final cachedUser = await _localStorage.getCurrentUser();
      if (cachedUser != null) {
        setState(() {
          _currentUser = cachedUser;
        });
        await _loadConversations();
      }
    } catch (e) {
      print('Error loading current user: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadConversations() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _messageService.getRecentConversations(limit: 20);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _conversations = response.data!;
          _isLoading = false;
        });
      }

      // F
    } catch (e) {
      print('Error loading conversations: $e');
    }
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
      onRefresh: _loadConversations,
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

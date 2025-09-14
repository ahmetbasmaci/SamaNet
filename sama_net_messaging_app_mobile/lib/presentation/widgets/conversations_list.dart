import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../data/services/message_service.dart';
import 'conversation_tile.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/models/conversation.dart';
import '../../data/models/user.dart';

/// Widget to display list of conversations
class ConversationsList extends StatefulWidget {
  const ConversationsList({super.key});

  @override
  State<ConversationsList> createState() => _ConversationsListState();
}

class _ConversationsListState extends State<ConversationsList> {
  bool _isLoading = true;
  List<Conversation> _conversations = [];
  late LocalStorageService _localStorage;
  late MessageService _messageService;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadCurrentUser();
  }

  void _initializeServices() {
    _localStorage = serviceLocator.get<LocalStorageService>();
    _messageService = serviceLocator.get<MessageService>();
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
          return ConversationTile(conversation: conversation);
        },
      ),
    );
  }
}

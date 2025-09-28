import 'package:flutter/material.dart';
import 'package:sama_net_messaging_app_mobile/presentation/pages/messages_page.dart';
import '../../data/models/conversation.dart';
import 'user_avatar.dart';

/// Individual conversation tile widget
class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback? onConversationUpdated;

  const ConversationTile({super.key, required this.conversation, this.onConversationUpdated});

  @override
  Widget build(BuildContext context) {
    final user = conversation.otherUser;
    final lastMessage = conversation.lastMessage?.content ?? 'لا توجد رسائل';
    final timestamp = conversation.lastActivity;
    final unreadCount = conversation.unreadCount;
    final isOnline = user.isOnline;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            UserAvatar(user: user, radius: 24),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
          ],
        ),
        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: unreadCount > 0 ? Theme.of(context).colorScheme.onSurface : Colors.grey[600],
            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTimestamp(timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: unreadCount > 0 ? Theme.of(context).colorScheme.primary : Colors.grey[500],
                  ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onTap: () async {
          // Navigate to individual conversation and wait for result
          await Navigator.push(context, MaterialPageRoute(builder: (context) => MessagesPage(chatUser: user)));

          // When user returns from MessagesPage, refresh the conversations
          onConversationUpdated?.call();
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} س';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ي';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

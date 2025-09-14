import 'package:flutter/material.dart';
import '../../data/models/message.dart';
import '../../data/models/user.dart';
import '../../core/utils/date_time_utils.dart';

/// Message bubble widget with status indicators
class MessageBubble extends StatelessWidget {
  final Message message;
  final User? currentUser;
  final bool showTimestamp;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUser,
    this.showTimestamp = true,
    this.onTap,
    this.onLongPress,
  });

  bool get isOwnMessage => currentUser != null && message.senderId == currentUser!.id;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other user's messages
          if (!isOwnMessage) _buildAvatar(),

          // Message bubble
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                margin: EdgeInsets.only(left: isOwnMessage ? 50 : 8, right: isOwnMessage ? 8 : 50),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOwnMessage ? Theme.of(context).primaryColor : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
                    bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content
                    if (message.content != null) ...[
                      Text(
                        message.content!,
                        style: TextStyle(color: isOwnMessage ? Colors.white : Colors.black87, fontSize: 16),
                      ),
                    ],

                    // Attachments
                    if (message.hasAttachment) ...[const SizedBox(height: 8), _buildAttachments()],

                    // Timestamp and status
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showTimestamp) ...[
                          Text(
                            DateTimeUtils.formatTime(message.sentAt),
                            style: TextStyle(color: isOwnMessage ? Colors.white70 : Colors.black54, fontSize: 12),
                          ),
                        ],

                        // Status indicators for own messages
                        if (isOwnMessage) ...[const SizedBox(width: 6), _buildStatusIndicator()],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Avatar for own messages
          if (isOwnMessage) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(color: isOwnMessage ? Colors.blue : Colors.grey, shape: BoxShape.circle),
      child: Icon(Icons.person, size: 20, color: Colors.white),
    );
  }

  Widget _buildStatusIndicator() {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.white60;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white70;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white70;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.lightBlueAccent;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.redAccent;
        break;
    }

    return Icon(icon, size: 16, color: color);
  }

  Widget _buildAttachments() {
    return Column(
      children: message.attachments.map((attachment) {
        switch (message.type) {
          case MessageType.image:
            return _buildImageAttachment(attachment);
          case MessageType.video:
            return _buildVideoAttachment(attachment);
          case MessageType.audio:
            return _buildAudioAttachment(attachment);
          case MessageType.file:
            return _buildFileAttachment(attachment);
          default:
            return _buildFileAttachment(attachment);
        }
      }).toList(),
    );
  }

  Widget _buildImageAttachment(attachment) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ClipRRectangle(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          attachment.filePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 100,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.broken_image),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(attachment) {
    return Container(
      height: 120,
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_filled, size: 40),
            const SizedBox(height: 8),
            Text('Video (${_formatFileSize(attachment.fileSize)})', style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioAttachment(attachment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.audiotrack),
          const SizedBox(width: 8),
          Text('Audio (${_formatFileSize(attachment.fileSize)})', style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFileAttachment(attachment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.filePath.split('/').last,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(_formatFileSize(attachment.fileSize), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// Fix for ClipRRectangle (should be ClipRRect)
class ClipRRectangle extends StatelessWidget {
  final BorderRadius borderRadius;
  final Widget child;

  const ClipRRectangle({super.key, required this.borderRadius, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: borderRadius, child: child);
  }
}

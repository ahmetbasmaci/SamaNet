import 'package:flutter/material.dart';
import '../../data/services/message_status_service.dart';
import '../../core/di/service_locator.dart';

/// Widget that displays unread message count
class UnreadCountBadge extends StatefulWidget {
  final int userId;
  final Widget child;
  final EdgeInsets? padding;

  const UnreadCountBadge({super.key, required this.userId, required this.child, this.padding});

  @override
  State<UnreadCountBadge> createState() => _UnreadCountBadgeState();
}

class _UnreadCountBadgeState extends State<UnreadCountBadge> {
  late MessageStatusService _messageStatusService;
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadUnreadCount();
  }

  void _initializeService() {
    _messageStatusService = serviceLocator.get<MessageStatusService>();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _messageStatusService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
          _isLoading = false;
        });
      }
    }
  }

  /// Public method to refresh unread count
  Future<void> refreshUnreadCount() async {
    await _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(padding: widget.padding ?? EdgeInsets.zero, child: widget.child),
        if (!_isLoading && _unreadCount > 0)
          Positioned(
            right: (widget.padding?.right ?? 0) + 8,
            top: (widget.padding?.top ?? 0) + 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

/// Global unread count provider for app bar
class GlobalUnreadCountProvider extends StatefulWidget {
  final Widget child;

  const GlobalUnreadCountProvider({super.key, required this.child});

  @override
  State<GlobalUnreadCountProvider> createState() => _GlobalUnreadCountProviderState();
}

class _GlobalUnreadCountProviderState extends State<GlobalUnreadCountProvider> {
  late MessageStatusService _messageStatusService;
  int _totalUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadTotalUnreadCount();
  }

  void _initializeService() {
    _messageStatusService = serviceLocator.get<MessageStatusService>();
  }

  Future<void> _loadTotalUnreadCount() async {
    try {
      final count = await _messageStatusService.getUnreadCount();
      if (mounted) {
        setState(() {
          _totalUnreadCount = count;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Method to refresh total unread count
  Future<void> refreshTotalUnreadCount() async {
    await _loadTotalUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// Getter for total unread count
  int get totalUnreadCount => _totalUnreadCount;
}

/// Simple unread count indicator
class UnreadCountIndicator extends StatelessWidget {
  final int count;
  final double? size;
  final Color? backgroundColor;
  final Color? textColor;

  const UnreadCountIndicator({super.key, required this.count, this.size, this.backgroundColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final actualSize = size ?? 20;

    return Container(
      padding: EdgeInsets.all(actualSize * 0.25),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.red,
        borderRadius: BorderRadius.circular(actualSize * 0.6),
      ),
      constraints: BoxConstraints(minWidth: actualSize, minHeight: actualSize),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(color: textColor ?? Colors.white, fontSize: actualSize * 0.5, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

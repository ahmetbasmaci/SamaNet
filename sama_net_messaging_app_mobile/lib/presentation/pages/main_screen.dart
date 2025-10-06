import 'package:flutter/material.dart';
import 'package:sama_net_messaging_app_mobile/presentation/widgets/conversations_list.dart';
import '../../core/constants/arabic_strings.dart';
import '../../core/di/service_locator.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/models/user.dart';
import '../widgets/notification_permission_dialog.dart';

/// Main screen with conversations list
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  User? _currentUser;
  late LocalStorageService _localStorage;

  @override
  void initState() {
    super.initState();
    _localStorage = serviceLocator.get<LocalStorageService>();
    _loadCurrentUser();
    // Request notification permission after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = await _localStorage.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (!mounted) return;
    await NotificationPermissionDialog.checkAndRequestPermission(context);
  }

  @override
  Widget build(BuildContext context) {
    // Build the title with username if available
    final titleText = _currentUser != null
        ? '${ArabicStrings.chats} - ${_currentUser!.displayName ?? _currentUser!.username}'
        : ArabicStrings.chats;

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search page
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: const ConversationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/search');
        },
        child: const Icon(Icons.message),
      ),
    );
  }
}

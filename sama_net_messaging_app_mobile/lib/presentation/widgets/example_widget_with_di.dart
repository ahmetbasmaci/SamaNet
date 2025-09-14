import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../data/services/user_service.dart';
import '../../data/services/local_storage_service.dart';

/// Example widget showing how to use dependency injection
class ExampleWidgetWithDI extends StatefulWidget {
  const ExampleWidgetWithDI({super.key});

  @override
  State<ExampleWidgetWithDI> createState() => _ExampleWidgetWithDIState();
}

class _ExampleWidgetWithDIState extends State<ExampleWidgetWithDI> {
  // 1. Declare service variables
  late UserService _userService;
  late LocalStorageService _localStorage;

  bool _isLoading = false;
  String _status = 'Not loaded';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadData();
  }

  // 2. Initialize services using dependency injection
  void _initializeServices() {
    _userService = serviceLocator.get<UserService>();
    _localStorage = serviceLocator.get<LocalStorageService>();
  }

  // 3. Use the services
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Example of using injected services
      final currentUserId = await _localStorage.getString('currentUserId');
      if (currentUserId != null) {
        // Use user service to get user data
        // final user = await _userService.getUserById(currentUserId);
        setState(() {
          _status = 'User ID: $currentUserId';
        });
      } else {
        setState(() {
          _status = 'No user logged in';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DI Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How to use Dependency Injection:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('1. Declare service variables as late'),
            const Text('2. Initialize in initState using serviceLocator.get<T>()'),
            const Text('3. Use the services in your methods'),
            const SizedBox(height: 24),
            Text('Status: $_status'),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(onPressed: _loadData, child: const Text('Reload Data')),
          ],
        ),
      ),
    );
  }
}

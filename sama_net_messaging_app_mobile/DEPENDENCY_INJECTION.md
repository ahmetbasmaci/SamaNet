# Dependency Injection System

This project uses a custom dependency injection system without external packages to manage service dependencies.

## Overview

The dependency injection system consists of:
- `ServiceLocator`: Main DI container class
- Service registration: Done in `main.dart` during app initialization
- Service retrieval: Using `serviceLocator.get<T>()`

## How to Use

### 1. Service Registration (Already done in main.dart)

```dart
// This is already implemented in main.dart
void initializeDependencies() {
  // Register singletons (one instance for the entire app lifecycle)
  serviceLocator.registerSingleton<ApiClient>(ApiClient());
  serviceLocator.registerSingleton<LocalStorageService>(LocalStorageService());
  
  // Register factories (new instance each time)
  serviceLocator.registerFactory<AuthService>(
    () => AuthService(serviceLocator.get<ApiClient>()),
  );
  serviceLocator.registerFactory<UserService>(
    () => UserService(serviceLocator.get<ApiClient>()),
  );
  serviceLocator.registerFactory<MessageService>(
    () => MessageService(serviceLocator.get<ApiClient>()),
  );
}
```

### 2. Service Usage in Widgets

```dart
import '../../core/di/service_locator.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // 1. Declare service variables
  late UserService _userService;
  late LocalStorageService _localStorage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  // 2. Initialize services
  void _initializeServices() {
    _userService = serviceLocator.get<UserService>();
    _localStorage = serviceLocator.get<LocalStorageService>();
  }

  // 3. Use the services
  Future<void> _loadData() async {
    final user = await _userService.getCurrentUser();
    await _localStorage.saveString('lastLogin', DateTime.now().toString());
  }

  @override
  Widget build(BuildContext context) {
    // Your UI code here
    return Container();
  }
}
```

### 3. Service Usage in BLoCs

```dart
import '../../core/di/service_locator.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final LocalStorageService _localStorage;

  AuthBloc()
      : _authService = serviceLocator.get<AuthService>(),
        _localStorage = serviceLocator.get<LocalStorageService>(),
        super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    // Use _authService and _localStorage here
  }
}
```

## Available Services

### Core Services
- `ApiClient`: HTTP client for API communication
- `LocalStorageService`: File-based local storage

### Business Services
- `AuthService`: Authentication operations
- `UserService`: User management operations  
- `MessageService`: Message and conversation operations

### UI Services
- `AuthBloc`: Authentication state management

## Service Lifecycle

### Singletons
- `ApiClient`: One instance for the entire app
- `LocalStorageService`: One instance for the entire app

### Factories
- `AuthService`: New instance each time you call `get<AuthService>()`
- `UserService`: New instance each time you call `get<UserService>()`
- `MessageService`: New instance each time you call `get<MessageService>()`
- `AuthBloc`: New instance each time you call `get<AuthBloc>()`

## Best Practices

1. **Initialize in initState**: Always get services in `initState()` method
2. **Use late variables**: Declare services as `late` since they're initialized after construction
3. **Single responsibility**: Each service should have a clear, single responsibility
4. **Error handling**: Always handle potential errors when using services
5. **Dispose properly**: If services need cleanup, do it in `dispose()` method

## Example Files

- `lib/presentation/widgets/example_widget_with_di.dart`: Complete example of DI usage
- `lib/presentation/pages/search_page.dart`: Real-world usage example
- `lib/presentation/widgets/conversations_list.dart`: Widget with DI integration

## Adding New Services

1. Create your service class
2. Add registration in `initializeDependencies()` in `main.dart`
3. Choose between singleton or factory based on your needs
4. Use `serviceLocator.get<YourService>()` to retrieve it

```dart
// 1. Create service
class NotificationService {
  final ApiClient _apiClient;
  NotificationService(this._apiClient);
  
  Future<void> sendNotification(String message) async {
    // Implementation
  }
}

// 2. Register in main.dart
serviceLocator.registerFactory<NotificationService>(
  () => NotificationService(serviceLocator.get<ApiClient>()),
);

// 3. Use in widgets
late NotificationService _notificationService;

void _initializeServices() {
  _notificationService = serviceLocator.get<NotificationService>();
}
```

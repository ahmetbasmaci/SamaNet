import '../../data/services/api_client.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/message_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/file_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/message_status_service.dart';
import '../../data/services/realtime_chat_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/user_block_service.dart';
import '../../presentation/blocs/auth_bloc.dart';
import '../constants/app_constants.dart';
import '../services/conversation_update_notifier.dart';

/// Simple service locator for dependency injection without external packages
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  final Map<Type, dynamic Function()> _factories = {};

  /// Register a singleton service
  void registerSingleton<T>(T service) {
    _services[T] = service;
  }

  /// Register a factory for creating new instances
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Get a service instance
  T get<T>() {
    // First check if it's a singleton
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }

    // Then check if it's a factory
    if (_factories.containsKey(T)) {
      return _factories[T]!() as T;
    }

    throw Exception('Service of type $T is not registered');
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _services.containsKey(T) || _factories.containsKey(T);
  }

  /// Clear all services (useful for testing)
  void reset() {
    _services.clear();
    _factories.clear();
  }
}

/// Global service locator instance
final serviceLocator = ServiceLocator();

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // Core services (singletons)
  serviceLocator.registerSingleton<LocalStorageService>(LocalStorageService());

  serviceLocator.registerSingleton<ApiClient>(ApiClient(baseUrl: ApiConstants.baseUrl));

  serviceLocator.registerSingleton<RealtimeChatService>(RealtimeChatService());

  // Conversation update notifier
  serviceLocator.registerSingleton<ConversationUpdateNotifier>(ConversationUpdateNotifier());

  // API services
  serviceLocator.registerSingleton<AuthService>(
    AuthService(serviceLocator.get<ApiClient>(), serviceLocator.get<LocalStorageService>()),
  );

  serviceLocator.registerSingleton<UserService>(UserService(serviceLocator.get<ApiClient>()));

  serviceLocator.registerSingleton<MessageService>(MessageService(serviceLocator.get<ApiClient>()));

  // Additional services
  serviceLocator.registerSingleton<FileService>(FileService(serviceLocator.get<ApiClient>()));

  serviceLocator.registerSingleton<ChatService>(ChatService(serviceLocator.get<ApiClient>()));

  serviceLocator.registerSingleton<UserBlockService>(UserBlockService(serviceLocator.get<ApiClient>()));

  // Message status service
  serviceLocator.registerSingleton<MessageStatusService>(
    MessageStatusService(serviceLocator.get<MessageService>(), serviceLocator.get<LocalStorageService>()),
  );

  // Notification service
  serviceLocator.registerSingleton<NotificationService>(NotificationService());

  // BLoCs (factory pattern for new instances when needed)
  serviceLocator.registerFactory<AuthBloc>(
    () => AuthBloc(
      authService: serviceLocator.get<AuthService>(),
      localStorage: serviceLocator.get<LocalStorageService>(),
    ),
  );

  // Initialize core services
  await _initializeCoreServices();
}

/// Initialize core services that need async setup
Future<void> _initializeCoreServices() async {
  final localStorage = serviceLocator.get<LocalStorageService>();
  final apiClient = serviceLocator.get<ApiClient>();
  final notificationService = serviceLocator.get<NotificationService>();

  // Initialize notification service
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Load stored auth token and user ID
  final token = await localStorage.getString('authToken');
  final userId = await localStorage.getString('currentUserId');

  if (token != null) {
    apiClient.setAuthToken(token);
  }

  if (userId != null) {
    apiClient.setUserId(userId.toString());
    final parsedUserId = int.tryParse(userId);
    if (parsedUserId != null) {
      final realtime = serviceLocator.get<RealtimeChatService>();
      realtime.configureForUser(parsedUserId);
    }
  }
}

/// Clean up all dependencies (useful for testing)
Future<void> resetDependencies() async {
  serviceLocator.reset();
}

/// Update API base server URL and refresh dependent services without recreating blocs
Future<void> updateApiServerUrl(String newBaseServerUrl) async {
  final normalizedUrl = _normalizeBaseServerUrl(newBaseServerUrl);
  ApiConstants.updateBaseServerUrl(normalizedUrl);

  if (serviceLocator.isRegistered<ApiClient>()) {
    final apiClient = serviceLocator.get<ApiClient>();
    apiClient.updateBaseUrl(ApiConstants.baseUrl);
  } else {
    serviceLocator.registerSingleton<ApiClient>(ApiClient(baseUrl: ApiConstants.baseUrl));
  }

  if (serviceLocator.isRegistered<RealtimeChatService>()) {
    try {
      await serviceLocator.get<RealtimeChatService>().disconnect();
    } catch (_) {
      // Ignore disconnect errors; connection will be re-established lazily when needed
    }
  }
}

String _normalizeBaseServerUrl(String url) {
  var normalized = url.trim();

  if (normalized.isEmpty) {
    return ApiConstants.baseServerUrl;
  }

  if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
    normalized = 'http://$normalized';
  }

  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }

  return normalized;
}

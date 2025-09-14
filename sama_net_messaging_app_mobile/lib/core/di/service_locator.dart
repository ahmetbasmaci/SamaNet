import '../../data/services/api_client.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/message_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/file_service.dart';
import '../../data/services/chat_service.dart';
import '../../presentation/blocs/auth_bloc.dart';
import '../constants/app_constants.dart';

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

  // API services
  serviceLocator.registerSingleton<AuthService>(AuthService(serviceLocator.get<ApiClient>()));

  serviceLocator.registerSingleton<UserService>(UserService(serviceLocator.get<ApiClient>()));

  serviceLocator.registerSingleton<MessageService>(MessageService(serviceLocator.get<ApiClient>()));

  // Additional services
  serviceLocator.registerSingleton<FileService>(FileService(serviceLocator.get<ApiClient>()));

  serviceLocator.registerSingleton<ChatService>(ChatService(serviceLocator.get<ApiClient>()));

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

  // Load stored auth token and user ID
  final token = await localStorage.getString('authToken');
  final userId = await localStorage.getString('currentUserId');

  if (token != null) {
    apiClient.setAuthToken(token);
  }

  if (userId != null) {
    apiClient.setUserId(userId);
  }
}

/// Clean up all dependencies (useful for testing)
Future<void> resetDependencies() async {
  serviceLocator.reset();
}

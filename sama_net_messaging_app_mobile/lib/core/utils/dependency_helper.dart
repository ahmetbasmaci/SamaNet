import '../di/service_locator.dart';
import '../../data/services/local_storage_service.dart';
import '../../data/services/api_client.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/message_service.dart';

/// Extension to make dependency injection more convenient
extension DependencyInjection on Object {
  /// Get a service from the service locator
  T get<T>() => serviceLocator.get<T>();
}

/// Convenient access to common services
class Dependencies {
  static T get<T>() => serviceLocator.get<T>();

  // Common services getters for easier access
  static LocalStorageService get localStorage => get<LocalStorageService>();
  static ApiClient get apiClient => get<ApiClient>();
  static AuthService get authService => get<AuthService>();
  static UserService get userService => get<UserService>();
  static MessageService get messageService => get<MessageService>();
}

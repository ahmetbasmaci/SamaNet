import '../../data/models/auth.dart';
import '../../data/models/user.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../core/constants/app_constants.dart';
import 'bloc_provider.dart';

/// Authentication events
abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  AuthLoginRequested({required this.username, required this.password});
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final String phoneNumber;
  final String? displayName;
  final String password;

  AuthRegisterRequested({required this.username, required this.phoneNumber, this.displayName, required this.password});
}

class AuthLogoutRequested extends AuthEvent {}

/// Authentication states
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final String accessToken;

  AuthAuthenticated({required this.user, required this.accessToken});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}

/// Authentication BLoC
class AuthBloc extends BaseBloc {
  final AuthService authService;
  final LocalStorageService localStorage;

  User? _currentUser;
  String? _accessToken;

  AuthBloc({required this.authService, required this.localStorage}) : super(AuthInitial());

  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;

  @override
  void add(dynamic event) {
    if (event is AuthCheckRequested) {
      _handleAuthCheck();
    } else if (event is AuthLoginRequested) {
      _handleLogin(event);
    } else if (event is AuthRegisterRequested) {
      _handleRegister(event);
    } else if (event is AuthLogoutRequested) {
      _handleLogout();
    }
  }

  /// Check if user is already authenticated on app start
  Future<void> _handleAuthCheck() async {
    emit(AuthLoading());

    try {
      // Check for stored auth token
      final storedToken = await localStorage.getString(AppConstants.authTokenKey);
      final storedUserData = await localStorage.getObject(AppConstants.userDataKey);

      if (storedToken != null && storedUserData != null) {
        // Set token in auth service
        authService.setAuthToken(storedToken);

        // Create user from stored data
        final user = User.fromJson(storedUserData);
        _currentUser = user;
        _accessToken = storedToken;

        emit(AuthAuthenticated(user: user, accessToken: storedToken));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      await _clearStoredAuth();
      emit(AuthUnauthenticated());
    }
  }

  /// Handle user login
  Future<void> _handleLogin(AuthLoginRequested event) async {
    emit(AuthLoading());

    try {
      final loginRequest = LoginRequest(username: event.username, password: event.password);

      final response = await authService.login(loginRequest);

      if (response.isSuccess && response.data != null) {
        final authData = response.data!;
        if (authData.success && authData.user != null && authData.token != null) {
          _currentUser = authData.user!;
          _accessToken = authData.token!;

          // Store auth data locally
          await localStorage.saveString(AppConstants.authTokenKey, authData.token!);
          await localStorage.saveObject(AppConstants.userDataKey, authData.user!.toJson());
          await localStorage.saveString(AppConstants.userIdKey, authData.user!.id.toString());

          emit(AuthAuthenticated(user: authData.user!, accessToken: authData.token!));
        } else {
          emit(AuthError(authData.message));
        }
      } else {
        emit(AuthError(response.error ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  /// Handle user registration
  Future<void> _handleRegister(AuthRegisterRequested event) async {
    emit(AuthLoading());

    try {
      final registerRequest = RegisterRequest(
        username: event.username,
        phoneNumber: event.phoneNumber,
        displayName: event.displayName,
        password: event.password,
      );

      final response = await authService.register(registerRequest);

      if (response.isSuccess && response.data != null) {
        final authData = response.data!;
        if (authData.success && authData.user != null && authData.token != null) {
          _currentUser = authData.user!;
          _accessToken = authData.token!;

          // Store auth data locally
          await localStorage.saveString(AppConstants.authTokenKey, authData.token!);
          await localStorage.saveObject(AppConstants.userDataKey, authData.user!.toJson());
          await localStorage.saveString(AppConstants.userIdKey, authData.user!.id.toString());

          emit(AuthAuthenticated(user: authData.user!, accessToken: authData.token!));
        } else {
          emit(AuthError(authData.message));
        }
      } else {
        emit(AuthError(response.error ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  /// Handle user logout
  Future<void> _handleLogout() async {
    emit(AuthLoading());

    try {
      // Call logout API (best effort)
      authService.logout(); // Remove await since it returns void
    } catch (e) {
      // Continue with logout even if API call fails
    }

    // Clear stored auth data
    await _clearStoredAuth();

    // Clear current user data
    _currentUser = null;
    _accessToken = null;

    emit(AuthUnauthenticated());
  }

  /// Clear stored authentication data
  Future<void> _clearStoredAuth() async {
    await localStorage.remove(AppConstants.authTokenKey);
    await localStorage.remove(AppConstants.userIdKey);
    await localStorage.remove(AppConstants.userDataKey);
    authService.setAuthToken(null);
  }
}

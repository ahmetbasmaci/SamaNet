import '../../data/models/auth.dart';
import '../../data/models/user.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/local_storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/arabic_strings.dart';
import 'bloc_provider.dart';

/// Authentication events
abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  AuthLoginRequested({required this.username, required this.password});
}

class AuthUserUpdated extends AuthEvent {
  final User user;

  AuthUserUpdated({required this.user});
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
  final AuthErrorType errorType;

  AuthError(this.message, {this.errorType = AuthErrorType.general});
}

/// Authentication error types for more specific error handling
enum AuthErrorType {
  general,
  invalidCredentials,
  networkError,
  serverError,
  accountNotFound,
  accountDisabled,
  timeout,
  validationError
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
    } else if (event is AuthUserUpdated) {
      _handleUserUpdated(event);
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
        // Create user from stored data
        final user = User.fromJson(storedUserData);

        // Set token and user ID in auth service
        authService.setAuthToken(storedToken);
        authService.setUserId(user.id.toString());

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
      // Client-side validation first
      if (event.username.trim().isEmpty) {
        emit(AuthError(ArabicStrings.emptyUsername, errorType: AuthErrorType.validationError));
        return;
      }

      if (event.password.trim().isEmpty) {
        emit(AuthError(ArabicStrings.emptyPassword, errorType: AuthErrorType.validationError));
        return;
      }

      if (event.username.length < 3) {
        emit(AuthError(ArabicStrings.usernameMinLength, errorType: AuthErrorType.validationError));
        return;
      }

      if (event.password.length < 3) {
        emit(AuthError(ArabicStrings.passwordMinLength, errorType: AuthErrorType.validationError));
        return;
      }

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
          // Parse API error message for more specific error types
          final String errorMessage = authData.message.toLowerCase();
          AuthErrorType errorType = AuthErrorType.general;
          String userMessage = authData.message;

          if (errorMessage.contains('invalid') ||
              errorMessage.contains('wrong') ||
              errorMessage.contains('incorrect') ||
              errorMessage.contains('credentials')) {
            errorType = AuthErrorType.invalidCredentials;
            userMessage = ArabicStrings.wrongUsernameOrPassword;
          } else if (errorMessage.contains('not found') || errorMessage.contains('not exist')) {
            errorType = AuthErrorType.accountNotFound;
            userMessage = ArabicStrings.accountNotFound;
          } else if (errorMessage.contains('disabled') || errorMessage.contains('blocked')) {
            errorType = AuthErrorType.accountDisabled;
            userMessage = ArabicStrings.accountDisabled;
          }

          emit(AuthError(userMessage, errorType: errorType));
        }
      } else {
        // Handle HTTP/Network errors
        final String errorMessage = (response.error ?? '').toLowerCase();
        AuthErrorType errorType = AuthErrorType.general;
        String userMessage = response.error ?? ArabicStrings.loginFailed;
        print('Error message: $errorMessage');
        if (errorMessage.contains('network') ||
            errorMessage.contains('connection') ||
            errorMessage.contains('internet') ||
            errorMessage.contains('dns')) {
          errorType = AuthErrorType.networkError;
          userMessage = ArabicStrings.networkConnectionError;
        } else if (errorMessage.contains('server') ||
            errorMessage.contains('500') ||
            errorMessage.contains('503') ||
            errorMessage.contains('unavailable')) {
          errorType = AuthErrorType.serverError;
          userMessage = ArabicStrings.serverUnavailable;
        } else if (errorMessage.contains('timeout')) {
          errorType = AuthErrorType.timeout;
          userMessage = ArabicStrings.requestTimeout;
        } else if (errorMessage.contains('401') || errorMessage.contains('unauthorized')) {
          errorType = AuthErrorType.invalidCredentials;
          userMessage = ArabicStrings.wrongUsernameOrPassword;
        }

        emit(AuthError(userMessage, errorType: errorType));
      }
    } catch (e) {
      String errorMessage = e.toString().toLowerCase();
      AuthErrorType errorType = AuthErrorType.general;
      String userMessage = ArabicStrings.unexpectedError;

      if (errorMessage.contains('socket') ||
          errorMessage.contains('network') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('dns')) {
        errorType = AuthErrorType.networkError;
        userMessage = ArabicStrings.networkConnectionError;
      } else if (errorMessage.contains('timeout')) {
        errorType = AuthErrorType.timeout;
        userMessage = ArabicStrings.requestTimeout;
      } else if (errorMessage.contains('server')) {
        errorType = AuthErrorType.serverError;
        userMessage = ArabicStrings.serverUnavailable;
      }

      emit(AuthError(userMessage, errorType: errorType));
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
          emit(AuthError(authData.message, errorType: AuthErrorType.general));
        }
      } else {
        emit(AuthError(response.error ?? ArabicStrings.registrationFailed, errorType: AuthErrorType.general));
      }
    } catch (e) {
      emit(AuthError('${ArabicStrings.registrationFailed}: ${e.toString()}', errorType: AuthErrorType.general));
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

  /// Handle user data updates (e.g., avatar changes)
  Future<void> _handleUserUpdated(AuthUserUpdated event) async {
    final updatedUser = event.user;
    _currentUser = updatedUser;

    if (_accessToken == null) {
      // Attempt to read token from cached storage as fallback
      _accessToken = await localStorage.getString(AppConstants.authTokenKey);
    }

    await localStorage.saveObject(AppConstants.userDataKey, updatedUser.toJson());
    await localStorage.saveCurrentUser(updatedUser);

    // Preserve existing access token from state or cache
    final currentToken = _accessToken ??
        (state is AuthAuthenticated ? (state as AuthAuthenticated).accessToken : null);

    if (currentToken != null) {
      _accessToken = currentToken;
      emit(AuthAuthenticated(user: updatedUser, accessToken: currentToken));
    } else {
      emit(AuthAuthenticated(user: updatedUser, accessToken: ''));
    }
  }

  /// Clear stored authentication data
  Future<void> _clearStoredAuth() async {
    await localStorage.remove(AppConstants.authTokenKey);
    await localStorage.remove(AppConstants.userIdKey);
    await localStorage.remove(AppConstants.userDataKey);
    authService.setAuthToken(null);
  }
}

import '../models/auth.dart';
import '../models/user.dart';
import '../../core/constants/app_constants.dart';
import 'api_client.dart';
import 'local_storage_service.dart';

/// Authentication service for handling login, logout, and user authentication
class AuthService {
  final ApiClient _apiClient;
  final LocalStorageService _localStorage;

  AuthService(this._apiClient, this._localStorage);

  /// Login with username/phone and password
  Future<ApiResponse<AuthResponse>> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post<AuthResponse>(
        ApiConstants.login,
        body: request.toJson(),
        fromJson: (json) => AuthResponse.fromJson(json),
      );

      // If login successful, set the auth token and user ID for future requests
      if (response.isSuccess && response.data != null) {
        _apiClient.setAuthToken(response.data!.accessToken);
        _apiClient.setUserId(response.data!.user!.id.toString());

        // Cache the current user for offline access
        await _localStorage.saveCurrentUser(response.data!.user!);
      } else {
        throw Exception(response.error);
      }
      return response;
    } catch (e) {
      return ApiResponse.error('Login failed: ${e.toString()}');
    }
  }

  /// Register new user account
  Future<ApiResponse<AuthResponse>> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.post<AuthResponse>(
        ApiConstants.register,
        body: request.toJson(),
        fromJson: (json) => AuthResponse.fromJson(json),
      );

      // If registration successful, set the auth token and user ID for future requests
      if (response.isSuccess && response.data != null) {
        _apiClient.setAuthToken(response.data!.accessToken);
        _apiClient.setUserId(response.data!.user!.id.toString());

        // Cache the current user for offline access
        await _localStorage.saveCurrentUser(response.data!.user!);
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Registration failed: ${e.toString()}');
    }
  }

  /// Register new user account (Admin function - does not change current authentication)
  /// Used by admins to create new users without switching their own authentication context
  Future<ApiResponse<AuthResponse>> adminRegister(RegisterRequest request) async {
    try {
      final response = await _apiClient.post<AuthResponse>(
        ApiConstants.register,
        body: request.toJson(),
        fromJson: (json) => AuthResponse.fromJson(json),
      );

      // Note: We don't set auth token or save the user as current user
      // This preserves the admin's authentication state

      return response;
    } catch (e) {
      return ApiResponse.error('Registration failed: ${e.toString()}');
    }
  }

  /// Search users by phone number
  Future<ApiResponse<List<User>>> searchUsers(String phoneNumber) async {
    try {
      final response = await _apiClient.get<List<User>>(
        ApiConstants.searchUsers,
        queryParams: {'phoneNumber': phoneNumber},
        fromJson: (json) {
          final usersData = json as List<dynamic>? ?? [];
          return usersData.map((userJson) => User.fromJson(userJson as Map<String, dynamic>)).toList();
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Search failed: ${e.toString()}');
    }
  }

  /// Get user by ID
  Future<ApiResponse<User>> getUserById(int userId) async {
    try {
      final response = await _apiClient.get<User>(
        '${ApiConstants.getUserById}/$userId',
        fromJson: (json) => User.fromJson(json),
      );
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get user: ${e.toString()}');
    }
  }

  /// Update user's last seen timestamp
  Future<ApiResponse<void>> updateLastSeen(int userId) async {
    try {
      final response = await _apiClient.put<void>('${ApiConstants.updateLastSeen}/$userId/last-seen');
      return response;
    } catch (e) {
      return ApiResponse.error('Failed to update last seen: ${e.toString()}');
    }
  }

  /// Set authentication token and user ID (for restoring authentication state)
  void setAuthToken(String? token) {
    _apiClient.setAuthToken(token);
  }

  /// Set user ID
  void setUserId(String? userId) {
    _apiClient.setUserId(userId);
  }

  /// Clear authentication
  void logout() {
    _apiClient.setAuthToken(null);
    _apiClient.setUserId(null);
    // Clear cached user data
    _localStorage.clearCurrentUser();
  }
}

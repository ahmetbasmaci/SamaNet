import '../models/user.dart';
import 'api_client.dart';

/// Service for user-related API operations
class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  /// Search users by phone number
  Future<ApiResponse<List<User>>> searchUsersByPhone(String phoneNumber) async {
    try {
      final response = await _apiClient.get<List<User>>(
        '/users/search',
        queryParams: {'phoneNumber': phoneNumber},
        fromJson: (json) {
          // API returns a direct list of users, not wrapped in an object
          if (json is List) {
            return json.map((userJson) => User.fromJson(userJson as Map<String, dynamic>)).toList();
          } else {
            // Fallback: if wrapped in an object, try to extract the list
            final List<dynamic> usersList = json['users'] ?? json;
            return usersList.map((userJson) => User.fromJson(userJson as Map<String, dynamic>)).toList();
          }
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to search users: ${e.toString()}');
    }
  }

  /// Get user by ID
  Future<ApiResponse<User>> getUserById(int userId) async {
    try {
      final response = await _apiClient.get<User>('/users/$userId', fromJson: (json) => User.fromJson(json));

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get user: ${e.toString()}');
    }
  }

  /// Get current user profile
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _apiClient.get<User>('/users/profile', fromJson: (json) => User.fromJson(json));

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get current user: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.put<User>(
        '/users/profile',
        body: userData,
        fromJson: (json) => User.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to update profile: ${e.toString()}');
    }
  }
}

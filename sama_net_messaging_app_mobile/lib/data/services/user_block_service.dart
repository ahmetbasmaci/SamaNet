import '../models/user.dart';
import 'api_client.dart';

/// Service for user blocking operations
class UserBlockService {
  final ApiClient _apiClient;

  UserBlockService(this._apiClient);

  /// Block a user
  Future<ApiResponse<BlockStatusResponse>> blockUser({
    required int blockerId,
    required int blockedUserId,
  }) async {
    try {
      final response = await _apiClient.post<BlockStatusResponse>(
        '/users/$blockerId/block',
        body: {'blockedUserId': blockedUserId},
        fromJson: (json) => BlockStatusResponse.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to block user: ${e.toString()}');
    }
  }

  /// Unblock a user
  Future<ApiResponse<BlockStatusResponse>> unblockUser({
    required int blockerId,
    required int blockedUserId,
  }) async {
    try {
      final response = await _apiClient.delete<BlockStatusResponse>(
        '/users/$blockerId/unblock/$blockedUserId',
        fromJson: (json) => BlockStatusResponse.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to unblock user: ${e.toString()}');
    }
  }

  /// Check if a user is blocked
  Future<ApiResponse<bool>> isUserBlocked({
    required int blockerId,
    required int blockedUserId,
  }) async {
    try {
      final response = await _apiClient.get<bool>(
        '/users/$blockerId/is-blocked/$blockedUserId',
        fromJson: (json) => json as bool,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to check block status: ${e.toString()}');
    }
  }

  /// Get list of blocked users
  Future<ApiResponse<List<BlockedUser>>> getBlockedUsers({
    required int blockerId,
  }) async {
    try {
      final response = await _apiClient.get<List<BlockedUser>>(
        '/users/$blockerId/blocked-users',
        fromJson: (json) {
          if (json is List) {
            return json.map((item) => BlockedUser.fromJson(item as Map<String, dynamic>)).toList();
          } else {
            return [];
          }
        },
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to get blocked users: ${e.toString()}');
    }
  }
}

/// Block status response model
class BlockStatusResponse {
  final bool isBlocked;
  final String message;

  const BlockStatusResponse({
    required this.isBlocked,
    required this.message,
  });

  factory BlockStatusResponse.fromJson(Map<String, dynamic> json) {
    return BlockStatusResponse(
      isBlocked: json['isBlocked'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isBlocked': isBlocked,
      'message': message,
    };
  }
}

/// Blocked user model
class BlockedUser {
  final int id;
  final int blockerId;
  final int blockedUserId;
  final User? blockedUser;
  final DateTime blockedAt;

  const BlockedUser({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    this.blockedUser,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'] as int? ?? 0,
      blockerId: json['blockerId'] as int? ?? 0,
      blockedUserId: json['blockedUserId'] as int? ?? 0,
      blockedUser: json['blockedUser'] != null ? User.fromJson(json['blockedUser'] as Map<String, dynamic>) : null,
      blockedAt: DateTime.parse(json['blockedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'blockedUser': blockedUser?.toJson(),
      'blockedAt': blockedAt.toIso8601String(),
    };
  }
}

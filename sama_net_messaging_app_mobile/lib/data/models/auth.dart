import 'user.dart';

/// Authentication request model for login
class LoginRequest {
  final String username; // Username instead of identifier
  final String password;

  const LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}

/// Authentication response model
class AuthResponse {
  final bool success;
  final String message;
  final User? user;
  final String? token;

  const AuthResponse({required this.success, required this.message, this.user, this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'success': success, 'message': message, 'user': user?.toJson(), 'token': token};
  }

  // For backward compatibility, provide accessToken property
  String? get accessToken => token;
}

/// Registration request model
class RegisterRequest {
  final String username;
  final String password;
  final String phoneNumber;
  final String? displayName;

  const RegisterRequest({required this.username, required this.password, required this.phoneNumber, this.displayName});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password, 'phoneNumber': phoneNumber, 'displayName': displayName};
  }
}

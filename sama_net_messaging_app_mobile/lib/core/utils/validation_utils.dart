/// Utility class for input validation
class ValidationUtils {
  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate name format
  static bool isValidName(String name) {
    if (name.isEmpty) return false;

    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    return nameRegex.hasMatch(name);
  }

  /// Validate phone number format (basic validation)
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;

    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if it has at least 10 digits
    return digitsOnly.length >= 10 && digitsOnly.length <= 15;
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 3;
  }

  /// Validate that field is not empty
  static bool isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }

  /// Get email validation error message
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Get phone validation error message
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!isValidPhone(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Get password validation error message
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!isValidPassword(value)) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  /// Get required field validation error message
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate message length
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (value.length > 1000) {
      return 'Message is too long (max 1000 characters)';
    }
    return null;
  }
}

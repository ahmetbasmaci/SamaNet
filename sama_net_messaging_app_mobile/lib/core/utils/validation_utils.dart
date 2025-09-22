import '../constants/arabic_strings.dart';

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

  /// Validate if numeric
  static bool isNumeric(String str) {
    if (str.isEmpty) return false;

    // Remove all non-digit characters
    final digitsOnly = str.replaceAll(RegExp(r'[^\d]'), '');

    return digitsOnly.isNotEmpty;
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 3;
  }

  /// Validate username format
  static bool isValidUsername(String username) {
    if (username.isEmpty) return false;
    if (username.length < 3) return false;

    // Allow letters, numbers, underscore, and Arabic characters
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_\u0600-\u06FF]+$');
    return usernameRegex.hasMatch(username);
  }

  /// Validate that field is not empty
  static bool isNotEmpty(String value) {
    return value.trim().isNotEmpty;
  }

  /// Get email validation error message
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return ArabicStrings.nameOrPhoneRequired;
    }
    if (!isValidEmail(value)) {
      return ArabicStrings.enterValidNameOrPhone;
    }
    return null;
  }

  /// Get phone validation error message
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return ArabicStrings.nameOrPhoneRequired;
    }
    if (!isValidPhone(value)) {
      return ArabicStrings.enterValidNameOrPhone;
    }
    return null;
  }

  /// Get password validation error message
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return ArabicStrings.emptyPassword;
    }
    if (!isValidPassword(value)) {
      return ArabicStrings.passwordMinLength;
    }
    return null;
  }

  /// Get username validation error message
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return ArabicStrings.emptyUsername;
    }
    if (value.length < 3) {
      return ArabicStrings.usernameMinLength;
    }
    if (!isValidUsername(value)) {
      return ArabicStrings.invalidUsernameFormat;
    }
    return null;
  }

  /// Get required field validation error message
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ArabicStrings.fieldRequired;
    }
    return null;
  }

  /// Validate message length
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ArabicStrings.messageCannotBeEmpty;
    }
    if (value.length > 1000) {
      return ArabicStrings.messageTooLong;
    }
    return null;
  }
}

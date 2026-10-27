class Validators {
  Validators._();

  /// Returns null if valid, error string if invalid.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    final trimmed = value.trim();
    final regex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(trimmed)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Password: min 8 chars, at least one uppercase, at least one digit.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number.';
    }
    return null;
  }

  /// Confirm password matches password.
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'This field is required.';
      }
      if (value != password) {
        return 'Passwords do not match.';
      }
      return null;
    };
  }

  /// Name: at least 2 characters, letters and spaces only.
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    if (!RegExp(r"^[a-zA-Z\s\-'\.]+$").hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes.';
    }
    return null;
  }

  /// Phone: international or local format.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  /// Generic required-field check.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  /// Minimum length check.
  static String? Function(String?) minLength(int min, {String? label}) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'This field is required.';
      if (value.length < min) {
        return '${label ?? 'This field'} must be at least $min characters.';
      }
      return null;
    };
  }

  /// Maximum length check.
  static String? Function(String?) maxLength(int max, {String? label}) {
    return (String? value) {
      if (value == null) return null;
      if (value.length > max) {
        return '${label ?? 'This field'} must be at most $max characters.';
      }
      return null;
    };
  }
}

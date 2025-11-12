/// Input validation service for the application
class ValidationService {
  /// Validate email address
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return ValidationResult.invalid('Email is required');
    }

    final trimmedEmail = email.trim();

    // Basic email regex pattern
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!emailRegex.hasMatch(trimmedEmail)) {
      return ValidationResult.invalid('Please enter a valid email address');
    }

    if (trimmedEmail.length > 254) {
      return ValidationResult.invalid('Email is too long');
    }

    return ValidationResult.valid();
  }

  /// Validate phone number
  static ValidationResult validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return ValidationResult.invalid('Phone number is required');
    }

    final trimmedPhone = phone.trim();

    // Remove common formatting characters
    final digitsOnly = trimmedPhone.replaceAll(RegExp(r'[^\d+]'), '');

    if (digitsOnly.length < 10) {
      return ValidationResult.invalid('Phone number is too short');
    }

    if (digitsOnly.length > 15) {
      return ValidationResult.invalid('Phone number is too long');
    }

    // Basic phone number pattern
    final phoneRegex = RegExp(
      r'^[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}$',
    );

    if (!phoneRegex.hasMatch(trimmedPhone)) {
      return ValidationResult.invalid('Please enter a valid phone number');
    }

    return ValidationResult.valid();
  }

  /// Validate URL/website
  static ValidationResult validateUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return ValidationResult.invalid('URL is required');
    }

    final trimmedUrl = url.trim();

    // URL regex pattern
    final urlRegex = RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(trimmedUrl)) {
      return ValidationResult.invalid('Please enter a valid URL');
    }

    return ValidationResult.valid();
  }

  /// Validate name
  static ValidationResult validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return ValidationResult.invalid('Name is required');
    }

    final trimmedName = name.trim();

    if (trimmedName.length < 2) {
      return ValidationResult.invalid('Name must be at least 2 characters');
    }

    if (trimmedName.length > 100) {
      return ValidationResult.invalid('Name is too long');
    }

    // Check for valid name characters (letters, spaces, hyphens, apostrophes, periods)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'.]+$");

    if (!nameRegex.hasMatch(trimmedName)) {
      return ValidationResult.invalid('Name contains invalid characters');
    }

    return ValidationResult.valid();
  }

  /// Validate company name
  static ValidationResult validateCompany(String? company) {
    if (company == null || company.trim().isEmpty) {
      return ValidationResult.warning('Company name is recommended');
    }

    final trimmedCompany = company.trim();

    if (trimmedCompany.length > 200) {
      return ValidationResult.invalid('Company name is too long');
    }

    return ValidationResult.valid();
  }

  /// Validate job title
  static ValidationResult validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return ValidationResult.warning('Job title is recommended');
    }

    final trimmedTitle = title.trim();

    if (trimmedTitle.length > 100) {
      return ValidationResult.invalid('Job title is too long');
    }

    return ValidationResult.valid();
  }

  /// Validate address
  static ValidationResult validateAddress(String? address) {
    if (address == null || address.trim().isEmpty) {
      return ValidationResult.warning('Address is recommended');
    }

    final trimmedAddress = address.trim();

    if (trimmedAddress.length < 5) {
      return ValidationResult.invalid('Address is too short');
    }

    if (trimmedAddress.length > 500) {
      return ValidationResult.invalid('Address is too long');
    }

    return ValidationResult.valid();
  }

  /// Validate notes
  static ValidationResult validateNotes(String? notes) {
    if (notes == null || notes.trim().isEmpty) {
      return ValidationResult.valid();
    }

    final trimmedNotes = notes.trim();

    if (trimmedNotes.length > 5000) {
      return ValidationResult.invalid('Notes are too long (max 5000 characters)');
    }

    return ValidationResult.valid();
  }

  /// Validate LinkedIn URL
  static ValidationResult validateLinkedIn(String? linkedin) {
    if (linkedin == null || linkedin.trim().isEmpty) {
      return ValidationResult.valid();
    }

    final trimmedLinkedIn = linkedin.trim();

    final linkedInRegex = RegExp(
      r'^(https?:\/\/)?(www\.)?linkedin\.com\/(in|company)\/[a-zA-Z0-9_-]+\/?$',
    );

    if (!linkedInRegex.hasMatch(trimmedLinkedIn)) {
      return ValidationResult.invalid('Please enter a valid LinkedIn URL');
    }

    return ValidationResult.valid();
  }

  /// Validate Twitter handle or URL
  static ValidationResult validateTwitter(String? twitter) {
    if (twitter == null || twitter.trim().isEmpty) {
      return ValidationResult.valid();
    }

    final trimmedTwitter = twitter.trim();

    // Accept both @username and full URLs
    final twitterRegex = RegExp(
      r'^(@?[a-zA-Z0-9_]{1,15}|https?:\/\/(www\.)?(twitter|x)\.com\/[a-zA-Z0-9_]+)$',
    );

    if (!twitterRegex.hasMatch(trimmedTwitter)) {
      return ValidationResult.invalid('Please enter a valid Twitter handle or URL');
    }

    return ValidationResult.valid();
  }

  /// Validate generic social media URL
  static ValidationResult validateSocialUrl(String? url, String platform) {
    if (url == null || url.trim().isEmpty) {
      return ValidationResult.valid();
    }

    final urlValidation = validateUrl(url);
    if (!urlValidation.isValid) {
      return ValidationResult.invalid('Please enter a valid $platform URL');
    }

    return ValidationResult.valid();
  }

  /// Validate required field
  static ValidationResult validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('$fieldName is required');
    }

    return ValidationResult.valid();
  }

  /// Validate minimum length
  static ValidationResult validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.valid();
    }

    if (value.trim().length < minLength) {
      return ValidationResult.invalid(
        '$fieldName must be at least $minLength characters',
      );
    }

    return ValidationResult.valid();
  }

  /// Validate maximum length
  static ValidationResult validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.valid();
    }

    if (value.trim().length > maxLength) {
      return ValidationResult.invalid(
        '$fieldName must not exceed $maxLength characters',
      );
    }

    return ValidationResult.valid();
  }

  /// Validate tag format
  static ValidationResult validateTag(String? tag) {
    if (tag == null || tag.trim().isEmpty) {
      return ValidationResult.invalid('Tag cannot be empty');
    }

    final trimmedTag = tag.trim();

    if (trimmedTag.length > 50) {
      return ValidationResult.invalid('Tag is too long (max 50 characters)');
    }

    // Tags should be alphanumeric with hyphens and underscores
    final tagRegex = RegExp(r'^[a-zA-Z0-9_-]+$');

    if (!tagRegex.hasMatch(trimmedTag)) {
      return ValidationResult.invalid(
        'Tag can only contain letters, numbers, hyphens, and underscores',
      );
    }

    return ValidationResult.valid();
  }

  /// Sanitize input to prevent injection attacks
  static String sanitizeInput(String? input) {
    if (input == null) return '';

    return input
        .trim()
        .replaceAll(RegExp(r'<script.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<.*?>'), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
  }

  /// Validate and sanitize contact data
  static Map<String, ValidationResult> validateContact({
    String? name,
    String? email,
    String? phone,
    String? company,
    String? title,
    String? website,
    String? address,
    String? notes,
  }) {
    return {
      'name': validateName(name),
      if (email != null && email.isNotEmpty) 'email': validateEmail(email),
      if (phone != null && phone.isNotEmpty) 'phone': validatePhone(phone),
      if (company != null && company.isNotEmpty)
        'company': validateCompany(company),
      if (title != null && title.isNotEmpty) 'title': validateTitle(title),
      if (website != null && website.isNotEmpty) 'website': validateUrl(website),
      if (address != null && address.isNotEmpty)
        'address': validateAddress(address),
      if (notes != null && notes.isNotEmpty) 'notes': validateNotes(notes),
    };
  }

  /// Check if all validations passed
  static bool allValid(Map<String, ValidationResult> results) {
    return results.values.every((result) => result.isValid);
  }

  /// Get all error messages
  static List<String> getErrorMessages(Map<String, ValidationResult> results) {
    return results.values
        .where((result) => !result.isValid)
        .map((result) => result.message ?? 'Validation failed')
        .toList();
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? message;
  final ValidationLevel level;

  const ValidationResult._({
    required this.isValid,
    this.message,
    this.level = ValidationLevel.error,
  });

  factory ValidationResult.valid() {
    return const ValidationResult._(isValid: true);
  }

  factory ValidationResult.invalid(String message) {
    return ValidationResult._(
      isValid: false,
      message: message,
      level: ValidationLevel.error,
    );
  }

  factory ValidationResult.warning(String message) {
    return ValidationResult._(
      isValid: true,
      message: message,
      level: ValidationLevel.warning,
    );
  }

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, message: $message, level: $level)';
  }
}

/// Validation level enum
enum ValidationLevel {
  error,
  warning,
  info,
}

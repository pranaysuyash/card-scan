import '../config/app_config.dart';

class ParserService {
  Map<String, dynamic> parseLines(List<String> lines) {
    final emails = <Map<String, dynamic>>[];
    final phones = <Map<String, dynamic>>[];
    final nameCandidates = <String>[];

    var fullName = '';
    var givenName = '';
    var familyName = '';
    var title = '';
    var company = '';
    var website = '';
    var address = '';

    const companyKeywords = [
      'Inc',
      'Ltd',
      'LLC',
      'Corp',
      'Company',
      'Labs',
      'Technologies',
      'Solutions',
    ];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Email detection
      if (AppConstants.emailRegex.hasMatch(trimmed)) {
        final email = AppConstants.emailRegex.firstMatch(trimmed)?.group(0);
        if (email != null && !_isDuplicate(emails, email)) {
          emails.add({
            'value': email.toLowerCase(),
            'confidence': 0.95,
            'type': 'work',
          });
        }
        continue;
      }

      // Phone detection
      final phoneMatches = AppConstants.phoneRegex.allMatches(trimmed);
      for (final match in phoneMatches) {
        final phone = match.group(0);
        if (phone != null && phone.length >= 7 && !_isDuplicate(phones, phone)) {
          phones.add({
            'value': phone,
            'confidence': 0.90,
            'type': 'work',
            'e164': _normalizePhone(phone),
          });
        }
      }

      // Website detection
      if (AppConstants.urlRegex.hasMatch(trimmed) && website.isEmpty) {
        var detected = AppConstants.urlRegex.firstMatch(trimmed)?.group(0) ?? '';
        if (detected.isNotEmpty && !detected.startsWith('http')) {
          detected = 'https://$detected';
        }
        website = detected;
        continue;
      }

      // Company detection (contains keywords)
      if (company.isEmpty && companyKeywords.any((kw) => trimmed.contains(kw))) {
        company = trimmed;
        continue;
      }

      // Potential title (contains separators or role keywords)
      if (title.isEmpty && _looksLikeTitle(trimmed)) {
        title = trimmed;
        continue;
      }

      // Potential name (short lines with 2-3 words, early in the card)
      final words = trimmed.split(RegExp(r'\s+'));
      if (words.length >= 2 && words.length <= 4 && trimmed.length < 50) {
        if (!_hasNumbers(trimmed) && !_hasSpecialChars(trimmed)) {
          nameCandidates.add(trimmed);
        }
      } else if (address.isEmpty && trimmed.length > 20 && trimmed.contains(RegExp(r'\d'))) {
        // Heuristic: long line with numbers could be an address
        address = trimmed;
      }
    }

    // Assign name (first candidate is usually the name)
    if (nameCandidates.isNotEmpty && fullName.isEmpty) {
      fullName = nameCandidates.first;
      final parts = fullName.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        givenName = parts.first;
        familyName = parts.sublist(1).join(' ');
      }
    }

    // If no company found but have extra name candidates, second might be company
    if (company.isEmpty && nameCandidates.length > 1) {
      company = nameCandidates[1];
    }

    return <String, dynamic>{
      'full_name': fullName,
      'given_name': givenName,
      'family_name': familyName,
      'title': title,
      'company': company,
      'emails': emails,
      'phones': phones,
      'website': website,
      'address': address,
    };
  }

  Map<String, double> calculateConfidence(Map<String, dynamic> parsed) {
    final emails = parsed['emails'] as List?;
    final phones = parsed['phones'] as List?;

    return {
      'full_name': parsed['full_name'].toString().isNotEmpty ? 0.85 : 0.0,
      'company': parsed['company'].toString().isNotEmpty ? 0.80 : 0.0,
      'emails': (emails != null && emails.isNotEmpty) ? 0.95 : 0.0,
      'phones': (phones != null && phones.isNotEmpty) ? 0.90 : 0.0,
      'website': parsed['website'].toString().isNotEmpty ? 0.85 : 0.0,
    };
  }

  bool _isDuplicate(List<Map<String, dynamic>> items, String value) {
    return items.any((item) => item['value'] == value);
  }

  bool _hasNumbers(String text) {
    return RegExp(r'\d').hasMatch(text);
  }

  bool _hasSpecialChars(String text) {
    return RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text);
  }

  bool _looksLikeTitle(String text) {
    final lower = text.toLowerCase();
    const keywords = [
      'director',
      'manager',
      'lead',
      'officer',
      'engineer',
      'specialist',
      'consultant',
      'chief',
      'vp',
      'president',
    ];
    return keywords.any(lower.contains) ||
        text.contains('/') ||
        text.contains('-') && !_hasNumbers(text);
  }

  String _normalizePhone(String phone) {
    // Simple E.164 approximation (remove non-digits)
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return phone;
    }
    if (digits.startsWith('1') && digits.length == 11) {
      return '+$digits';
    } else if (digits.length == 10) {
      return '+1$digits';
    }
    return '+$digits';
  }
}

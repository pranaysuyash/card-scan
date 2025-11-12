import 'package:string_similarity/string_similarity.dart';
import '../../../models/contact.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';

/// Service for detecting and merging duplicate contacts
/// Uses fuzzy matching algorithms for intelligent duplicate detection
class DeduplicationService {
  // Similarity thresholds
  static const double nameThreshold = 0.85;
  static const double companyThreshold = 0.90;
  static const double emailThreshold = 1.0; // Exact match
  static const double phoneThreshold = 0.95;

  /// Calculate similarity score between two contacts
  /// Returns a value between 0.0 (no match) and 1.0 (perfect match)
  double calculateSimilarity(Contact c1, Contact c2) {
    double totalScore = 0.0;
    int factors = 0;

    // Name similarity (highest weight)
    final nameSimilarity = _calculateNameSimilarity(c1.fullName, c2.fullName);
    totalScore += nameSimilarity * 3.0; // 3x weight
    factors += 3;

    // Company similarity
    if (c1.company != null && c2.company != null) {
      final companySimilarity = c1.company!.similarityTo(c2.company!);
      totalScore += companySimilarity * 2.0; // 2x weight
      factors += 2;
    }

    // Email similarity
    final emailMatch = _checkEmailMatch(c1.emails, c2.emails);
    if (emailMatch != null) {
      totalScore += emailMatch * 2.5; // 2.5x weight for exact match
      factors += 2;
    }

    // Phone similarity
    final phoneMatch = _checkPhoneMatch(c1.phones, c2.phones);
    if (phoneMatch != null) {
      totalScore += phoneMatch * 2.0; // 2x weight
      factors += 2;
    }

    // Website similarity
    if (c1.website != null && c2.website != null) {
      final websiteSimilarity = c1.website!.similarityTo(c2.website!);
      totalScore += websiteSimilarity;
      factors += 1;
    }

    return factors > 0 ? totalScore / factors : 0.0;
  }

  /// Calculate name similarity with fuzzy matching
  /// Handles variations like "John Smith", "J. Smith", "Smith, John"
  double _calculateNameSimilarity(String name1, String name2) {
    final normalized1 = _normalizeName(name1);
    final normalized2 = _normalizeName(name2);

    // Direct similarity
    double directSimilarity = normalized1.similarityTo(normalized2);

    // Check reversed name (Smith, John vs John Smith)
    final parts1 = normalized1.split(' ');
    final parts2 = normalized2.split(' ');

    if (parts1.length >= 2 && parts2.length >= 2) {
      final reversed1 = '${parts1.last} ${parts1.first}';
      final reversed2 = '${parts2.last} ${parts2.first}';
      final reversedSimilarity = reversed1.similarityTo(reversed2);
      directSimilarity = directSimilarity > reversedSimilarity
          ? directSimilarity
          : reversedSimilarity;
    }

    // Check initials (J. Smith vs John Smith)
    if (_hasInitials(name1) || _hasInitials(name2)) {
      final initialMatch = _checkInitialMatch(parts1, parts2);
      if (initialMatch > directSimilarity) {
        return initialMatch;
      }
    }

    return directSimilarity;
  }

  /// Normalize name for comparison
  String _normalizeName(String name) {
    return name.toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Check if name contains initials
  bool _hasInitials(String name) {
    return RegExp(r'\b[A-Z]\.\s').hasMatch(name);
  }

  /// Check if initials match
  double _checkInitialMatch(List<String> parts1, List<String> parts2) {
    if (parts1.isEmpty || parts2.isEmpty) return 0.0;

    // Check if first name initial matches
    if (parts1[0].length == 1 && parts2[0].isNotEmpty) {
      if (parts1[0] == parts2[0][0]) {
        // Check last name
        if (parts1.length > 1 && parts2.length > 1) {
          return parts1.last.similarityTo(parts2.last);
        }
        return 0.7; // Partial match
      }
    }

    if (parts2[0].length == 1 && parts1[0].isNotEmpty) {
      if (parts2[0] == parts1[0][0]) {
        if (parts1.length > 1 && parts2.length > 1) {
          return parts1.last.similarityTo(parts2.last);
        }
        return 0.7;
      }
    }

    return 0.0;
  }

  /// Check email match (exact match preferred)
  double? _checkEmailMatch(List<EmailItem> emails1, List<EmailItem> emails2) {
    if (emails1.isEmpty || emails2.isEmpty) return null;

    for (final e1 in emails1) {
      for (final e2 in emails2) {
        final email1 = e1.value.toLowerCase().trim();
        final email2 = e2.value.toLowerCase().trim();

        if (email1 == email2) {
          return 1.0; // Exact match
        }

        // Check domain similarity
        final domain1 = email1.split('@').last;
        final domain2 = email2.split('@').last;
        if (domain1 == domain2) {
          return 0.8; // Same domain
        }
      }
    }

    return 0.0;
  }

  /// Check phone match with normalization
  double? _checkPhoneMatch(List<PhoneItem> phones1, List<PhoneItem> phones2) {
    if (phones1.isEmpty || phones2.isEmpty) return null;

    for (final p1 in phones1) {
      for (final p2 in phones2) {
        final phone1 = _normalizePhone(p1.value);
        final phone2 = _normalizePhone(p2.value);

        if (phone1 == phone2) {
          return 1.0; // Exact match
        }

        // Check similarity
        final similarity = phone1.similarityTo(phone2);
        if (similarity > phoneThreshold) {
          return similarity;
        }
      }
    }

    return 0.0;
  }

  /// Normalize phone number for comparison
  String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), ''); // Keep only digits
  }

  /// Find potential duplicates for a contact
  Future<Either<Failure, List<DuplicateMatch>>> findPotentialDuplicates(
    Contact contact,
    List<Contact> allContacts,
  ) async {
    try {
      final matches = <DuplicateMatch>[];

      for (final other in allContacts) {
        if (contact.id == other.id) continue;

        final similarity = calculateSimilarity(contact, other);

        if (similarity >= nameThreshold) {
          matches.add(DuplicateMatch(
            contact: other,
            similarity: similarity,
            confidence: _calculateConfidence(similarity),
            reasons: _generateMatchReasons(contact, other, similarity),
          ));
        }
      }

      // Sort by similarity (highest first)
      matches.sort((a, b) => b.similarity.compareTo(a.similarity));

      return Right(matches);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to find duplicates',
        details: e,
      ));
    }
  }

  /// Calculate confidence level
  DuplicateConfidence _calculateConfidence(double similarity) {
    if (similarity >= 0.95) return DuplicateConfidence.veryHigh;
    if (similarity >= 0.90) return DuplicateConfidence.high;
    if (similarity >= 0.85) return DuplicateConfidence.medium;
    return DuplicateConfidence.low;
  }

  /// Generate human-readable reasons for the match
  List<String> _generateMatchReasons(
    Contact c1,
    Contact c2,
    double similarity,
  ) {
    final reasons = <String>[];

    // Name match
    final nameSim = _calculateNameSimilarity(c1.fullName, c2.fullName);
    if (nameSim > 0.85) {
      reasons.add('Similar name: ${c1.fullName} ≈ ${c2.fullName}');
    }

    // Company match
    if (c1.company != null && c2.company != null) {
      final companySim = c1.company!.similarityTo(c2.company!);
      if (companySim > 0.85) {
        reasons.add('Same company: ${c1.company}');
      }
    }

    // Email match
    final emailMatch = _checkEmailMatch(c1.emails, c2.emails);
    if (emailMatch != null && emailMatch > 0.8) {
      reasons.add('Matching email address');
    }

    // Phone match
    final phoneMatch = _checkPhoneMatch(c1.phones, c2.phones);
    if (phoneMatch != null && phoneMatch > 0.9) {
      reasons.add('Matching phone number');
    }

    return reasons;
  }

  /// Merge two contacts intelligently
  /// Keeps most complete data from both contacts
  Contact mergeContacts(Contact primary, Contact secondary) {
    return Contact()
      ..id = primary.id
      ..createdAt = primary.createdAt
      ..updatedAt = DateTime.now()
      ..fullName = primary.fullName
      ..givenName = primary.givenName ?? secondary.givenName
      ..familyName = primary.familyName ?? secondary.familyName
      ..title = primary.title ?? secondary.title
      ..company = primary.company ?? secondary.company
      ..emails = _mergeEmails(primary.emails, secondary.emails)
      ..phones = _mergePhones(primary.phones, secondary.phones)
      ..website = primary.website ?? secondary.website
      ..address = primary.address ?? secondary.address
      ..linkedIn = primary.linkedIn ?? secondary.linkedIn
      ..facebook = primary.facebook ?? secondary.facebook
      ..twitter = primary.twitter ?? secondary.twitter
      ..instagram = primary.instagram ?? secondary.instagram
      ..youtube = primary.youtube ?? secondary.youtube
      ..github = primary.github ?? secondary.github
      ..whatsapp = primary.whatsapp ?? secondary.whatsapp
      ..department = primary.department ?? secondary.department
      ..jobFunction = primary.jobFunction ?? secondary.jobFunction
      ..industry = primary.industry ?? secondary.industry
      ..skills = _mergeUnique(primary.skills, secondary.skills)
      ..profileImageUrl = primary.profileImageUrl ?? secondary.profileImageUrl
      ..companyLogo = primary.companyLogo ?? secondary.companyLogo
      ..qrCode = primary.qrCode ?? secondary.qrCode
      ..digitalCardUrl = primary.digitalCardUrl ?? secondary.digitalCardUrl
      ..lastContacted = _mostRecent(primary.lastContacted, secondary.lastContacted)
      ..leadSource = primary.leadSource ?? secondary.leadSource
      ..leadStatus = primary.leadStatus ?? secondary.leadStatus
      ..contactScore = primary.contactScore + secondary.contactScore
      ..interests = _mergeUnique(primary.interests, secondary.interests)
      ..syncedToContacts = primary.syncedToContacts || secondary.syncedToContacts
      ..crmId = primary.crmId ?? secondary.crmId
      ..lastSynced = _mostRecent(primary.lastSynced, secondary.lastSynced)
      ..tags = _mergeUnique(primary.tags, secondary.tags)
      ..imagePath = primary.imagePath ?? secondary.imagePath
      ..thumbPath = primary.thumbPath ?? secondary.thumbPath
      ..notes = [...primary.notes, ...secondary.notes]
      ..activity = [...primary.activity, ...secondary.activity]
      ..isFavorite = primary.isFavorite || secondary.isFavorite;
  }

  List<EmailItem> _mergeEmails(List<EmailItem> e1, List<EmailItem> e2) {
    final merged = <String, EmailItem>{};
    for (final email in [...e1, ...e2]) {
      final normalized = email.value.toLowerCase().trim();
      if (!merged.containsKey(normalized) ||
          merged[normalized]!.confidence < email.confidence) {
        merged[normalized] = email;
      }
    }
    return merged.values.toList();
  }

  List<PhoneItem> _mergePhones(List<PhoneItem> p1, List<PhoneItem> p2) {
    final merged = <String, PhoneItem>{};
    for (final phone in [...p1, ...p2]) {
      final normalized = _normalizePhone(phone.value);
      if (!merged.containsKey(normalized) ||
          merged[normalized]!.confidence < phone.confidence) {
        merged[normalized] = phone;
      }
    }
    return merged.values.toList();
  }

  List<String> _mergeUnique(List<String> l1, List<String> l2) {
    return {...l1, ...l2}.toList();
  }

  DateTime? _mostRecent(DateTime? d1, DateTime? d2) {
    if (d1 == null) return d2;
    if (d2 == null) return d1;
    return d1.isAfter(d2) ? d1 : d2;
  }
}

/// Duplicate match result
class DuplicateMatch {
  final Contact contact;
  final double similarity;
  final DuplicateConfidence confidence;
  final List<String> reasons;

  DuplicateMatch({
    required this.contact,
    required this.similarity,
    required this.confidence,
    required this.reasons,
  });

  int get percentSimilarity => (similarity * 100).round();
}

enum DuplicateConfidence {
  veryHigh,
  high,
  medium,
  low,
}

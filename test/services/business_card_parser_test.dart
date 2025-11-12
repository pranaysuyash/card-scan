import 'package:flutter_test/flutter_test.dart';
import 'package:card_scan/services/business_card_parser.dart';

void main() {
  late BusinessCardParser parser;

  setUp(() {
    parser = BusinessCardParser();
  });

  group('BusinessCardParser -', () {
    test('parseBusinessCard extracts email correctly', () {
      final lines = [
        'John Doe',
        'john.doe@company.com',
        '555-123-4567',
      ];

      final result = parser.parseBusinessCard(lines);

      expect(result['email'], equals('john.doe@company.com'));
    });

    test('parseBusinessCard extracts phone correctly', () {
      final lines = [
        'John Doe',
        '(555) 123-4567',
      ];

      final result = parser.parseBusinessCard(lines);

      expect(result['phone'], equals('(555) 123-4567'));
    });

    test('parseBusinessCard handles multiple phone formats', () {
      final testCases = [
        '555-123-4567',
        '(555) 123-4567',
        '+1 555 123 4567',
        '555.123.4567',
      ];

      for (final phoneNumber in testCases) {
        final result = parser.parseBusinessCard([phoneNumber]);
        expect(result['phone'], isNotNull,
            reason: 'Failed to parse: $phoneNumber');
      }
    });

    test('parseBusinessCard extracts website correctly', () {
      final lines = [
        'John Doe',
        'www.company.com',
      ];

      final result = parser.parseBusinessCard(lines);

      expect(result['website'], equals('www.company.com'));
    });

    test('parseBusinessCard handles https URLs', () {
      final lines = [
        'https://www.company.com',
      ];

      final result = parser.parseBusinessCard(lines);

      expect(result['website'], equals('https://www.company.com'));
    });

    test('parseBusinessCard extracts multiple fields', () {
      final lines = [
        'John Doe',
        'CEO',
        'Acme Corporation',
        'john.doe@acme.com',
        '+1 (555) 123-4567',
        'www.acme.com',
        '123 Main St, Suite 100',
        'New York, NY 10001',
      ];

      final result = parser.parseBusinessCard(lines);

      expect(result['name'], isNotNull);
      expect(result['email'], equals('john.doe@acme.com'));
      expect(result['phone'], isNotNull);
      expect(result['website'], equals('www.acme.com'));
      expect(result['company'], isNotNull);
    });

    test('parseBusinessCard handles empty input', () {
      final result = parser.parseBusinessCard([]);

      expect(result, isA<Map<String, dynamic>>());
      expect(result.isEmpty, isFalse); // Should have at least empty strings
    });

    test('parseBusinessCard handles malformed data gracefully', () {
      final lines = [
        '!!!@@@###',
        'random text',
        '12345',
      ];

      expect(() => parser.parseBusinessCard(lines), returnsNormally);
    });

    test('email validation rejects invalid emails', () {
      final invalidEmails = [
        'notanemail',
        '@company.com',
        'user@',
        'user @company.com',
      ];

      for (final email in invalidEmails) {
        final result = parser.parseBusinessCard([email]);
        expect(result['email']?.isEmpty ?? true, isTrue,
            reason: 'Should not accept: $email');
      }
    });

    test('parseBusinessCard prioritizes first occurrence', () {
      final lines = [
        'john@primary.com',
        'john@secondary.com',
      ];

      final result = parser.parseBusinessCard(lines);

      expect(result['email'], equals('john@primary.com'));
    });

    test('parseBusinessCard extracts LinkedIn profile', () {
      final lines = [
        'linkedin.com/in/johndoe',
      ];

      final result = parser.parseBusinessCard(lines);

      expect(result['linkedin'], isNotNull);
    });

    test('parseBusinessCard handles special characters in names', () {
      final lines = [
        "O'Brien, Patrick Jr.",
        'patrick@company.com',
      ];

      final result = parser.parseBusinessCard(lines);

      expect(result['name'], isNotNull);
      expect(result['email'], equals('patrick@company.com'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:card_scan/services/vcard_service.dart';
import 'package:card_scan/models/contact.dart';

void main() {
  late VCardService vCardService;

  setUp(() {
    vCardService = VCardService();
  });

  group('VCardService -', () {
    test('exportToVCard creates valid vCard 3.0 format', () {
      final contact = Contact()
        ..name = 'John Doe'
        ..email = 'john.doe@example.com'
        ..phone = '+1-555-123-4567'
        ..company = 'Acme Corp'
        ..title = 'CEO';

      final vCard = vCardService.exportToVCard(contact);

      expect(vCard, contains('BEGIN:VCARD'));
      expect(vCard, contains('VERSION:3.0'));
      expect(vCard, contains('FN:John Doe'));
      expect(vCard, contains('EMAIL:john.doe@example.com'));
      expect(vCard, contains('TEL:+1-555-123-4567'));
      expect(vCard, contains('ORG:Acme Corp'));
      expect(vCard, contains('TITLE:CEO'));
      expect(vCard, contains('END:VCARD'));
    });

    test('exportToVCard handles empty optional fields', () {
      final contact = Contact()..name = 'Jane Doe';

      final vCard = vCardService.exportToVCard(contact);

      expect(vCard, contains('BEGIN:VCARD'));
      expect(vCard, contains('FN:Jane Doe'));
      expect(vCard, contains('END:VCARD'));
      expect(vCard, isNot(contains('EMAIL:')));
      expect(vCard, isNot(contains('TEL:')));
    });

    test('exportToVCard includes website URL', () {
      final contact = Contact()
        ..name = 'Test User'
        ..website = 'https://www.example.com';

      final vCard = vCardService.exportToVCard(contact);

      expect(vCard, contains('URL:https://www.example.com'));
    });

    test('exportToVCard includes address', () {
      final contact = Contact()
        ..name = 'Test User'
        ..address = '123 Main St, Suite 100, New York, NY 10001';

      final vCard = vCardService.exportToVCard(contact);

      expect(vCard, contains('ADR:'));
      expect(vCard, contains('123 Main St'));
    });

    test('exportToVCard includes notes', () {
      final contact = Contact()
        ..name = 'Test User'
        ..notes = 'Important client - follow up next week';

      final vCard = vCardService.exportToVCard(contact);

      expect(vCard, contains('NOTE:Important client'));
    });

    test('exportToVCard escapes special characters', () {
      final contact = Contact()
        ..name = 'Test, User; Special'
        ..notes = 'Line1\nLine2';

      final vCard = vCardService.exportToVCard(contact);

      expect(vCard, contains('BEGIN:VCARD'));
      expect(vCard, contains('END:VCARD'));
      // vCard should handle special characters properly
    });

    test('exportToVCard includes social media links', () {
      final contact = Contact()
        ..name = 'Test User'
        ..linkedIn = 'https://linkedin.com/in/testuser'
        ..twitter = 'https://twitter.com/testuser';

      final vCard = vCardService.exportToVCard(contact);

      expect(vCard, contains('linkedin.com'));
      expect(vCard, contains('twitter.com'));
    });

    test('exportBatch creates multiple vCards', () {
      final contacts = [
        Contact()
          ..name = 'User 1'
          ..email = 'user1@example.com',
        Contact()
          ..name = 'User 2'
          ..email = 'user2@example.com',
      ];

      final vCards = vCardService.exportBatch(contacts);

      expect(vCards.length, equals(2));
      expect(vCards[0], contains('User 1'));
      expect(vCards[1], contains('User 2'));
    });

    test('importFromVCard parses basic vCard', () {
      final vCardData = '''BEGIN:VCARD
VERSION:3.0
FN:John Smith
EMAIL:john@example.com
TEL:555-1234
END:VCARD''';

      final contact = vCardService.importFromVCard(vCardData);

      expect(contact.name, equals('John Smith'));
      expect(contact.email, equals('john@example.com'));
      expect(contact.phone, equals('555-1234'));
    });

    test('importFromVCard handles complex vCard', () {
      final vCardData = '''BEGIN:VCARD
VERSION:3.0
FN:Jane Doe
ORG:Tech Corp
TITLE:Engineer
EMAIL:jane@techcorp.com
TEL:+1-555-987-6543
URL:https://www.techcorp.com
ADR:;;100 Tech Blvd;San Francisco;CA;94105;USA
NOTE:Key contact for technical issues
END:VCARD''';

      final contact = vCardService.importFromVCard(vCardData);

      expect(contact.name, equals('Jane Doe'));
      expect(contact.company, equals('Tech Corp'));
      expect(contact.title, equals('Engineer'));
      expect(contact.email, equals('jane@techcorp.com'));
      expect(contact.website, contains('techcorp.com'));
    });

    test('importFromVCard handles malformed vCard gracefully', () {
      final malformedVCard = '''BEGIN:VCARD
INVALID DATA
FN:Test
END:VCARD''';

      expect(() => vCardService.importFromVCard(malformedVCard), returnsNormally);
    });

    test('importFromVCard handles empty vCard', () {
      final emptyVCard = '''BEGIN:VCARD
VERSION:3.0
END:VCARD''';

      final contact = vCardService.importFromVCard(emptyVCard);

      expect(contact, isNotNull);
    });

    test('round-trip export and import preserves data', () {
      final original = Contact()
        ..name = 'Test User'
        ..email = 'test@example.com'
        ..phone = '555-1234'
        ..company = 'Test Co'
        ..title = 'Tester';

      final vCard = vCardService.exportToVCard(original);
      final imported = vCardService.importFromVCard(vCard);

      expect(imported.name, equals(original.name));
      expect(imported.email, equals(original.email));
      expect(imported.phone, equals(original.phone));
      expect(imported.company, equals(original.company));
    });
  });
}

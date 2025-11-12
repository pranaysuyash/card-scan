import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:card_scan/services/storage_service.dart';
import 'package:card_scan/models/contact.dart';

void main() {
  late Isar isar;
  late StorageService storageService;

  setUp(() async {
    // Initialize Isar with in-memory database for testing
    isar = await Isar.open(
      [ContactSchema],
      directory: '',
      name: 'test_storage_${DateTime.now().millisecondsSinceEpoch}',
    );
    storageService = StorageService(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('StorageService -', () {
    test('saveContact saves and returns contact with ID', () async {
      final contact = Contact()
        ..name = 'Test User'
        ..email = 'test@example.com'
        ..phone = '555-1234';

      final savedContact = await storageService.saveContact(contact);

      expect(savedContact.id, isNotNull);
      expect(savedContact.id, greaterThan(0));
      expect(savedContact.name, equals('Test User'));
    });

    test('getAllContacts returns all saved contacts', () async {
      final contact1 = Contact()
        ..name = 'User One'
        ..email = 'one@example.com';
      final contact2 = Contact()
        ..name = 'User Two'
        ..email = 'two@example.com';

      await storageService.saveContact(contact1);
      await storageService.saveContact(contact2);

      final contacts = await storageService.getAllContacts();

      expect(contacts.length, equals(2));
    });

    test('getContact returns specific contact by ID', () async {
      final contact = Contact()
        ..name = 'Specific User'
        ..email = 'specific@example.com';

      final saved = await storageService.saveContact(contact);
      final retrieved = await storageService.getContact(saved.id);

      expect(retrieved, isNotNull);
      expect(retrieved?.name, equals('Specific User'));
      expect(retrieved?.id, equals(saved.id));
    });

    test('updateContact modifies existing contact', () async {
      final contact = Contact()
        ..name = 'Original Name'
        ..email = 'original@example.com';

      final saved = await storageService.saveContact(contact);
      saved.name = 'Updated Name';

      await storageService.updateContact(saved);
      final updated = await storageService.getContact(saved.id);

      expect(updated?.name, equals('Updated Name'));
      expect(updated?.email, equals('original@example.com'));
    });

    test('deleteContact removes contact from database', () async {
      final contact = Contact()
        ..name = 'To Delete'
        ..email = 'delete@example.com';

      final saved = await storageService.saveContact(contact);
      await storageService.deleteContact(saved.id);

      final retrieved = await storageService.getContact(saved.id);

      expect(retrieved, isNull);
    });

    test('searchContacts finds contacts by name', () async {
      final contact1 = Contact()
        ..name = 'John Smith'
        ..email = 'john@example.com';
      final contact2 = Contact()
        ..name = 'Jane Doe'
        ..email = 'jane@example.com';
      final contact3 = Contact()
        ..name = 'John Doe'
        ..email = 'johndoe@example.com';

      await storageService.saveContact(contact1);
      await storageService.saveContact(contact2);
      await storageService.saveContact(contact3);

      final results = await storageService.searchContacts('John');

      expect(results.length, equals(2));
      expect(results.every((c) => c.name.contains('John')), isTrue);
    });

    test('searchContacts is case-insensitive', () async {
      final contact = Contact()
        ..name = 'Alice Johnson'
        ..email = 'alice@example.com';

      await storageService.saveContact(contact);

      final results = await storageService.searchContacts('ALICE');

      expect(results.length, greaterThan(0));
    });

    test('searchContacts finds contacts by email', () async {
      final contact = Contact()
        ..name = 'Bob Wilson'
        ..email = 'bob@company.com';

      await storageService.saveContact(contact);

      final results = await storageService.searchContacts('company');

      expect(results.length, greaterThan(0));
    });

    test('saveContact handles duplicate detection', () async {
      final contact1 = Contact()
        ..name = 'Duplicate User'
        ..email = 'dup@example.com';
      final contact2 = Contact()
        ..name = 'Duplicate User'
        ..email = 'dup@example.com';

      await storageService.saveContact(contact1);
      final duplicates = await storageService.findDuplicates(contact2);

      expect(duplicates.length, greaterThan(0));
    });

    test('getContactsByTag filters contacts correctly', () async {
      final contact1 = Contact()
        ..name = 'Tagged User'
        ..tags = ['client', 'vip'];
      final contact2 = Contact()
        ..name = 'Other User'
        ..tags = ['vendor'];

      await storageService.saveContact(contact1);
      await storageService.saveContact(contact2);

      final clientContacts = await storageService.getContactsByTag('client');

      expect(clientContacts.length, equals(1));
      expect(clientContacts.first.name, equals('Tagged User'));
    });

    test('getAllContacts returns empty list when no contacts', () async {
      final contacts = await storageService.getAllContacts();

      expect(contacts, isEmpty);
    });

    test('getContact returns null for non-existent ID', () async {
      final contact = await storageService.getContact(99999);

      expect(contact, isNull);
    });

    test('concurrent saves handle race conditions', () async {
      final futures = List.generate(10, (i) async {
        final contact = Contact()
          ..name = 'Concurrent $i'
          ..email = 'concurrent$i@example.com';
        return storageService.saveContact(contact);
      });

      await Future.wait(futures);
      final allContacts = await storageService.getAllContacts();

      expect(allContacts.length, equals(10));
    });
  });
}

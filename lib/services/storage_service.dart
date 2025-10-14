import 'package:isar/isar.dart';
import '../models/contact.dart';

class StorageService {
  final Isar _isar;

  StorageService(this._isar);

  Future<List<Contact>> getAllContacts() async {
    return await _isar.contacts.where().sortByUpdatedAtDesc().findAll();
  }

  Future<Contact?> getContactById(int id) async {
    return await _isar.contacts.get(id);
  }

  Future<List<Contact>> searchContacts(String query) async {
    final lowerQuery = query.toLowerCase();

    return await _isar.contacts
        .filter()
        .fullNameContains(lowerQuery, caseSensitive: false)
        .or()
        .companyContains(lowerQuery, caseSensitive: false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<List<Contact>> getContactsByTag(String tag) async {
    return await _isar.contacts
        .filter()
        .tagsElementContains(tag, caseSensitive: false)
        .findAll();
  }

  Future<int> saveContact(Contact contact) async {
    contact.updatedAt = DateTime.now();

    return await _isar.writeTxn(() async {
      return await _isar.contacts.put(contact);
    });
  }

  Future<void> deleteContact(int id) async {
    await _isar.writeTxn(() async {
      await _isar.contacts.delete(id);
    });
  }

  Future<List<Contact>> findPotentialDuplicates(
      String email, String phone) async {
    final contacts = await _isar.contacts.where().findAll();

    return contacts.where((c) {
      final hasEmail = c.emails.any((e) => e.value == email);
      final hasPhone = c.phones.any((p) => p.value == phone);
      return hasEmail || hasPhone;
    }).toList();
  }

  Future<int> getContactCount() async {
    return await _isar.contacts.count();
  }

  Future<List<String>> getAllTags() async {
    final contacts = await _isar.contacts.where().findAll();
    final tags = <String>{};

    for (final contact in contacts) {
      tags.addAll(contact.tags);
    }

    return tags.toList()..sort();
  }
}

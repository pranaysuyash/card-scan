import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/contact.dart';

class StorageService {
  static Isar? _isar;

  static Future<Isar> get isar async {
    if (_isar != null) return _isar!;
    
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ContactSchema],
      directory: dir.path,
    );
    
    return _isar!;
  }

  Future<List<Contact>> getAllContacts() async {
    final db = await isar;
    return await db.contacts.where().sortByUpdatedAtDesc().findAll();
  }

  Future<Contact?> getContactById(int id) async {
    final db = await isar;
    return await db.contacts.get(id);
  }

  Future<List<Contact>> searchContacts(String query) async {
    final db = await isar;
    final lowerQuery = query.toLowerCase();
    
    return await db.contacts
        .filter()
        .fullNameContains(lowerQuery, caseSensitive: false)
        .or()
        .companyContains(lowerQuery, caseSensitive: false)
        .sortByUpdatedAtDesc()
        .findAll();
  }

  Future<List<Contact>> getContactsByTag(String tag) async {
    final db = await isar;
    return await db.contacts
        .filter()
        .tagsElementContains(tag, caseSensitive: false)
        .findAll();
  }

  Future<int> saveContact(Contact contact) async {
    final db = await isar;
    contact.updatedAt = DateTime.now();
    
    return await db.writeTxn(() async {
      return await db.contacts.put(contact);
    });
  }

  Future<void> deleteContact(int id) async {
    final db = await isar;
    await db.writeTxn(() async {
      await db.contacts.delete(id);
    });
  }

  Future<List<Contact>> findPotentialDuplicates(String email, String phone) async {
    final db = await isar;
    final contacts = await db.contacts.where().findAll();
    
    return contacts.where((c) {
      final hasEmail = c.emails.any((e) => e.value == email);
      final hasPhone = c.phones.any((p) => p.value == phone);
      return hasEmail || hasPhone;
    }).toList();
  }

  Future<int> getContactCount() async {
    final db = await isar;
    return await db.contacts.count();
  }

  Future<List<String>> getAllTags() async {
    final db = await isar;
    final contacts = await db.contacts.where().findAll();
    final tags = <String>{};
    
    for (final contact in contacts) {
      tags.addAll(contact.tags);
    }
    
    return tags.toList()..sort();
  }
}

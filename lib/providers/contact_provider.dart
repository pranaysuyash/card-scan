import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';

final isarProvider = Provider<Isar>(
    (ref) => throw UnimplementedError('Isar must be initialized in main()'));

final storageServiceProvider = Provider<StorageService>((ref) {
  final isar = ref.watch(isarProvider);
  return StorageService(isar);
});

final contactsProvider = StreamProvider<List<Contact>>((ref) async* {
  final storage = ref.watch(storageServiceProvider);

  // Initial load
  yield await storage.getAllContacts();

  // Re-fetch every time this is invalidated
  while (true) {
    await Future.delayed(const Duration(milliseconds: 500));
    yield await storage.getAllContacts();
  }
});

final contactByIdProvider =
    FutureProvider.family<Contact?, int>((ref, id) async {
  final storage = ref.watch(storageServiceProvider);
  return await storage.getContactById(id);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<Contact>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final storage = ref.watch(storageServiceProvider);

  if (query.isEmpty) {
    return await storage.getAllContacts();
  }

  return await storage.searchContacts(query);
});

final selectedTagProvider = StateProvider<String?>((ref) => null);

final filteredContactsProvider = FutureProvider<List<Contact>>((ref) async {
  final tag = ref.watch(selectedTagProvider);
  final storage = ref.watch(storageServiceProvider);

  if (tag == null) {
    return await storage.getAllContacts();
  }

  return await storage.getContactsByTag(tag);
});

final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return await storage.getAllTags();
});

final contactCountProvider = FutureProvider<int>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return await storage.getContactCount();
});

import 'package:isar/isar.dart';
import '../../models/contact.dart';
import '../error/failures.dart';
import '../error/exceptions.dart';
import '../utils/either.dart';

/// Abstract repository interface for contact operations
/// Follows repository pattern for clean separation of concerns
abstract class ContactRepository {
  Future<Either<Failure, List<Contact>>> getAll();
  Future<Either<Failure, Contact?>> getById(int id);
  Future<Either<Failure, Contact>> save(Contact contact);
  Future<Either<Failure, void>> delete(int id);
  Future<Either<Failure, List<Contact>>> search(String query);
  Future<Either<Failure, List<Contact>>> getByTag(String tag);
  Future<Either<Failure, List<Contact>>> getFavorites();
  Stream<List<Contact>> watchAll();
  Stream<Contact?> watchById(int id);
  Future<Either<Failure, List<Contact>>> findDuplicates(Contact contact);
  Future<Either<Failure, Contact>> merge(Contact primary, Contact secondary);
}

/// Isar implementation of ContactRepository
class IsarContactRepository implements ContactRepository {
  final Isar isar;

  IsarContactRepository(this.isar);

  @override
  Future<Either<Failure, List<Contact>>> getAll() async {
    try {
      final contacts = await isar.contacts
          .where()
          .sortByUpdatedAtDesc()
          .findAll();
      return Right(contacts);
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Failed to fetch contacts: ${e.message}',
        code: 'FETCH_ERROR',
        details: e,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Unexpected error fetching contacts',
        code: 'UNKNOWN_ERROR',
        details: e,
      ));
    }
  }

  @override
  Future<Either<Failure, Contact?>> getById(int id) async {
    try {
      final contact = await isar.contacts.get(id);
      return Right(contact);
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Failed to fetch contact: ${e.message}',
        code: 'FETCH_ERROR',
        details: e,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Unexpected error fetching contact',
        code: 'UNKNOWN_ERROR',
        details: e,
      ));
    }
  }

  @override
  Future<Either<Failure, Contact>> save(Contact contact) async {
    try {
      await isar.writeTxn(() async {
        contact.updatedAt = DateTime.now();
        if (contact.id == Isar.autoIncrement) {
          contact.createdAt = DateTime.now();
        }
        await isar.contacts.put(contact);
      });
      return Right(contact);
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Failed to save contact: ${e.message}',
        code: 'SAVE_ERROR',
        details: e,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Unexpected error saving contact',
        code: 'UNKNOWN_ERROR',
        details: e,
      ));
    }
  }

  @override
  Future<Either<Failure, void>> delete(int id) async {
    try {
      await isar.writeTxn(() async {
        await isar.contacts.delete(id);
      });
      return const Right(null);
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Failed to delete contact: ${e.message}',
        code: 'DELETE_ERROR',
        details: e,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Unexpected error deleting contact',
        code: 'UNKNOWN_ERROR',
        details: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<Contact>>> search(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final contacts = await isar.contacts
          .filter()
          .fullNameContains(lowerQuery, caseSensitive: false)
          .or()
          .companyContains(lowerQuery, caseSensitive: false)
          .sortByUpdatedAtDesc()
          .findAll();
      return Right(contacts);
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Failed to search contacts: ${e.message}',
        code: 'SEARCH_ERROR',
        details: e,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Unexpected error searching contacts',
        code: 'UNKNOWN_ERROR',
        details: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<Contact>>> getByTag(String tag) async {
    try {
      final contacts = await isar.contacts
          .filter()
          .tagsElementContains(tag, caseSensitive: false)
          .sortByUpdatedAtDesc()
          .findAll();
      return Right(contacts);
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Failed to fetch contacts by tag: ${e.message}',
        code: 'FETCH_ERROR',
        details: e,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Unexpected error fetching contacts by tag',
        code: 'UNKNOWN_ERROR',
        details: e,
      ));
    }
  }

  @override
  Future<Either<Failure, List<Contact>>> getFavorites() async {
    try {
      final contacts = await isar.contacts
          .filter()
          .isFavoriteEqualTo(true)
          .sortByUpdatedAtDesc()
          .findAll();
      return Right(contacts);
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Failed to fetch favorites: ${e.message}',
        code: 'FETCH_ERROR',
        details: e,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Unexpected error fetching favorites',
        code: 'UNKNOWN_ERROR',
        details: e,
      ));
    }
  }

  @override
  Stream<List<Contact>> watchAll() {
    return isar.contacts
        .where()
        .sortByUpdatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Stream<Contact?> watchById(int id) {
    return isar.contacts
        .watchObject(id, fireImmediately: true);
  }

  @override
  Future<Either<Failure, List<Contact>>> findDuplicates(Contact contact) async {
    try {
      final potentialDuplicates = await isar.contacts
          .filter()
          .fullNameContains(contact.fullName, caseSensitive: false)
          .or()
          .companyEqualTo(contact.company, caseSensitive: false)
          .findAll();

      // Remove the contact itself from results
      potentialDuplicates.removeWhere((c) => c.id == contact.id);

      return Right(potentialDuplicates);
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Failed to find duplicates: ${e.message}',
        code: 'SEARCH_ERROR',
        details: e,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Unexpected error finding duplicates',
        code: 'UNKNOWN_ERROR',
        details: e,
      ));
    }
  }

  @override
  Future<Either<Failure, Contact>> merge(Contact primary, Contact secondary) async {
    try {
      // Merge logic: keep primary data, fill in missing fields from secondary
      final merged = Contact()
        ..id = primary.id
        ..createdAt = primary.createdAt
        ..updatedAt = DateTime.now()
        ..fullName = primary.fullName
        ..givenName = primary.givenName ?? secondary.givenName
        ..familyName = primary.familyName ?? secondary.familyName
        ..title = primary.title ?? secondary.title
        ..company = primary.company ?? secondary.company
        ..emails = [...primary.emails, ...secondary.emails]
        ..phones = [...primary.phones, ...secondary.phones]
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
        ..skills = [...primary.skills, ...secondary.skills]
        ..profileImageUrl = primary.profileImageUrl ?? secondary.profileImageUrl
        ..companyLogo = primary.companyLogo ?? secondary.companyLogo
        ..qrCode = primary.qrCode ?? secondary.qrCode
        ..digitalCardUrl = primary.digitalCardUrl ?? secondary.digitalCardUrl
        ..lastContacted = primary.lastContacted ?? secondary.lastContacted
        ..leadSource = primary.leadSource ?? secondary.leadSource
        ..leadStatus = primary.leadStatus ?? secondary.leadStatus
        ..contactScore = primary.contactScore + secondary.contactScore
        ..interests = [...primary.interests, ...secondary.interests]
        ..syncedToContacts = primary.syncedToContacts || secondary.syncedToContacts
        ..crmId = primary.crmId ?? secondary.crmId
        ..lastSynced = primary.lastSynced ?? secondary.lastSynced
        ..tags = [...primary.tags, ...secondary.tags]
        ..imagePath = primary.imagePath ?? secondary.imagePath
        ..thumbPath = primary.thumbPath ?? secondary.thumbPath
        ..notes = [...primary.notes, ...secondary.notes]
        ..activity = [...primary.activity, ...secondary.activity]
        ..isFavorite = primary.isFavorite || secondary.isFavorite;

      await isar.writeTxn(() async {
        await isar.contacts.put(merged);
        await isar.contacts.delete(secondary.id);
      });

      return Right(merged);
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Failed to merge contacts: ${e.message}',
        code: 'MERGE_ERROR',
        details: e,
      ));
    } catch (e) {
      return Left(StorageFailure(
        message: 'Unexpected error merging contacts',
        code: 'UNKNOWN_ERROR',
        details: e,
      ));
    }
  }
}

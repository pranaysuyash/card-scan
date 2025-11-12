import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../models/contact.dart';
import '../../backend/services/firebase_service.dart';
import '../../../core/repositories/contact_repository.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';
import 'dart:async';

/// Cloud synchronization service with conflict resolution
/// Implements bidirectional sync between local and cloud storage
class CloudSyncService {
  final FirebaseService firebaseService;
  final ContactRepository contactRepository;
  final Connectivity connectivity = Connectivity();

  CloudSyncService({
    required this.firebaseService,
    required this.contactRepository,
  });

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if device has internet connectivity
  Future<bool> hasConnectivity() async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Full sync: Upload local changes and download remote changes
  Future<Either<Failure, SyncResult>> fullSync() async {
    if (_isSyncing) {
      return Left(ValidationFailure(
        message: 'Sync already in progress',
        code: 'SYNC_IN_PROGRESS',
      ));
    }

    if (!await hasConnectivity()) {
      return Left(NetworkFailure(
        message: 'No internet connection',
        code: 'NO_CONNECTIVITY',
      ));
    }

    if (!firebaseService.isAuthenticated) {
      return Left(AuthFailure(
        message: 'User not authenticated',
        code: 'NOT_AUTHENTICATED',
      ));
    }

    _isSyncing = true;

    try {
      final result = SyncResult();

      // Step 1: Upload local changes
      final uploadResult = await _uploadLocalChanges();
      uploadResult.fold(
        (failure) {
          result.failures.add(failure);
        },
        (count) {
          result.uploaded = count;
        },
      );

      // Step 2: Download remote changes
      final downloadResult = await _downloadRemoteChanges();
      downloadResult.fold(
        (failure) {
          result.failures.add(failure);
        },
        (count) {
          result.downloaded = count;
        },
      );

      // Step 3: Resolve conflicts
      final conflictResult = await _resolveConflicts();
      conflictResult.fold(
        (failure) {
          result.failures.add(failure);
        },
        (count) {
          result.conflictsResolved = count;
        },
      );

      _lastSyncTime = DateTime.now();
      result.completedAt = _lastSyncTime!;

      return Right(result);
    } finally {
      _isSyncing = false;
    }
  }

  /// Upload local changes to cloud
  Future<Either<Failure, int>> _uploadLocalChanges() async {
    try {
      final localContactsResult = await contactRepository.getAll();
      if (localContactsResult.isLeft) {
        return Left(localContactsResult.left);
      }

      final localContacts = localContactsResult.right;
      int uploaded = 0;

      for (final contact in localContacts) {
        // Only upload contacts that haven't been synced or were modified
        if (contact.lastSynced == null ||
            contact.updatedAt.isAfter(contact.lastSynced!)) {
          final contactData = _contactToMap(contact);

          if (contact.crmId != null) {
            // Update existing
            final result = await firebaseService.updateContact(
              contact.crmId!,
              contactData,
            );
            if (result.isRight) {
              contact.lastSynced = DateTime.now();
              await contactRepository.save(contact);
              uploaded++;
            }
          } else {
            // Create new
            final result = await firebaseService.saveContact(contactData);
            result.fold(
              (_) {},
              (id) {
                contact.crmId = id;
                contact.lastSynced = DateTime.now();
                contactRepository.save(contact);
                uploaded++;
              },
            );
          }
        }
      }

      return Right(uploaded);
    } catch (e) {
      return Left(SyncFailure(
        message: 'Failed to upload local changes',
        details: e,
      ));
    }
  }

  /// Download remote changes from cloud
  Future<Either<Failure, int>> _downloadRemoteChanges() async {
    try {
      final remoteContactsResult = await firebaseService.getAllContacts();
      if (remoteContactsResult.isLeft) {
        return Left(remoteContactsResult.left);
      }

      final remoteContacts = remoteContactsResult.right;
      int downloaded = 0;

      for (final remoteData in remoteContacts) {
        final remoteId = remoteData['id'] as String;
        final remoteUpdatedAt = DateTime.parse(remoteData['updatedAt'] as String);

        // Find local contact with same CRM ID
        final localContactsResult = await contactRepository.getAll();
        if (localContactsResult.isLeft) continue;

        final localContact = localContactsResult.right.firstWhere(
          (c) => c.crmId == remoteId,
          orElse: () => Contact(),
        );

        // Download if local doesn't exist or remote is newer
        if (localContact.id == 0 || // New contact
            (localContact.lastSynced == null ||
                remoteUpdatedAt.isAfter(localContact.lastSynced!))) {
          final contact = _mapToContact(remoteData, localContact);
          contact.lastSynced = DateTime.now();
          contact.crmId = remoteId;

          await contactRepository.save(contact);
          downloaded++;
        }
      }

      return Right(downloaded);
    } catch (e) {
      return Left(SyncFailure(
        message: 'Failed to download remote changes',
        details: e,
      ));
    }
  }

  /// Resolve conflicts using last-write-wins strategy
  Future<Either<Failure, int>> _resolveConflicts() async {
    try {
      // For now, using simple last-write-wins
      // In production, implement more sophisticated conflict resolution
      return const Right(0);
    } catch (e) {
      return Left(SyncFailure(
        message: 'Failed to resolve conflicts',
        details: e,
      ));
    }
  }

  /// Convert Contact to Map for Firebase
  Map<String, dynamic> _contactToMap(Contact contact) {
    return {
      'fullName': contact.fullName,
      'givenName': contact.givenName,
      'familyName': contact.familyName,
      'title': contact.title,
      'company': contact.company,
      'emails': contact.emails.map((e) => {
            'value': e.value,
            'type': e.type,
            'confidence': e.confidence,
          }).toList(),
      'phones': contact.phones.map((p) => {
            'value': p.value,
            'type': p.type,
            'confidence': p.confidence,
          }).toList(),
      'website': contact.website,
      'address': contact.address,
      'linkedIn': contact.linkedIn,
      'facebook': contact.facebook,
      'twitter': contact.twitter,
      'instagram': contact.instagram,
      'youtube': contact.youtube,
      'github': contact.github,
      'whatsapp': contact.whatsapp,
      'department': contact.department,
      'jobFunction': contact.jobFunction,
      'industry': contact.industry,
      'skills': contact.skills,
      'tags': contact.tags,
      'isFavorite': contact.isFavorite,
      'contactScore': contact.contactScore,
      'createdAt': contact.createdAt.toIso8601String(),
      'updatedAt': contact.updatedAt.toIso8601String(),
    };
  }

  /// Convert Map from Firebase to Contact
  Contact _mapToContact(Map<String, dynamic> data, Contact existing) {
    final contact = existing.id != 0 ? existing : Contact();

    contact.fullName = data['fullName'] ?? '';
    contact.givenName = data['givenName'];
    contact.familyName = data['familyName'];
    contact.title = data['title'];
    contact.company = data['company'];
    contact.website = data['website'];
    contact.address = data['address'];
    contact.linkedIn = data['linkedIn'];
    contact.facebook = data['facebook'];
    contact.twitter = data['twitter'];
    contact.instagram = data['instagram'];
    contact.youtube = data['youtube'];
    contact.github = data['github'];
    contact.whatsapp = data['whatsapp'];
    contact.department = data['department'];
    contact.jobFunction = data['jobFunction'];
    contact.industry = data['industry'];
    contact.skills = List<String>.from(data['skills'] ?? []);
    contact.tags = List<String>.from(data['tags'] ?? []);
    contact.isFavorite = data['isFavorite'] ?? false;
    contact.contactScore = data['contactScore'] ?? 0;
    contact.createdAt = DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String());
    contact.updatedAt = DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String());

    // Parse emails
    if (data['emails'] != null) {
      contact.emails = (data['emails'] as List).map((e) {
        return EmailItem()
          ..value = e['value']
          ..type = e['type']
          ..confidence = e['confidence'];
      }).toList();
    }

    // Parse phones
    if (data['phones'] != null) {
      contact.phones = (data['phones'] as List).map((p) {
        return PhoneItem()
          ..value = p['value']
          ..type = p['type']
          ..confidence = p['confidence'];
      }).toList();
    }

    return contact;
  }

  /// Enable auto-sync
  StreamSubscription? _connectivitySubscription;

  void enableAutoSync({Duration interval = const Duration(minutes: 15)}) {
    // Sync on connectivity change
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && firebaseService.isAuthenticated) {
        fullSync();
      }
    });

    // Periodic sync
    Timer.periodic(interval, (timer) {
      if (firebaseService.isAuthenticated) {
        fullSync();
      }
    });
  }

  /// Disable auto-sync
  void disableAutoSync() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}

/// Sync result summary
class SyncResult {
  int uploaded = 0;
  int downloaded = 0;
  int conflictsResolved = 0;
  List<Failure> failures = [];
  DateTime? completedAt;

  bool get hasErrors => failures.isNotEmpty;
  bool get isSuccess => failures.isEmpty;
  int get totalChanges => uploaded + downloaded + conflictsResolved;
}

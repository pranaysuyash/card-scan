import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/utils/either.dart';

/// Firebase backend service
/// Handles authentication, cloud storage, and real-time sync
class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  bool _initialized = false;

  bool get isInitialized => _initialized;
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get userId => currentUser?.uid;

  /// Initialize Firebase
  Future<Either<Failure, void>> initialize() async {
    try {
      if (_initialized) {
        return const Right(null);
      }

      await Firebase.initializeApp();

      // Enable Firestore offline persistence
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Configure Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      _initialized = true;
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(
        message: 'Failed to initialize Firebase',
        details: e,
      ));
    }
  }

  // ============================================
  // AUTHENTICATION
  // ============================================

  /// Sign in anonymously
  Future<Either<Failure, User>> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      if (result.user == null) {
        return Left(AuthFailure(
          message: 'Anonymous sign in failed',
          code: 'SIGN_IN_FAILED',
        ));
      }
      await _analytics.logLogin(loginMethod: 'anonymous');
      return Right(result.user!);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message ?? 'Authentication failed',
        code: e.code,
        details: e,
      ));
    } catch (e) {
      return Left(AuthFailure(
        message: 'Unexpected authentication error',
        details: e,
      ));
    }
  }

  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user == null) {
        return Left(AuthFailure(
          message: 'Sign in failed',
          code: 'SIGN_IN_FAILED',
        ));
      }
      await _analytics.logLogin(loginMethod: 'email');
      return Right(result.user!);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message ?? 'Authentication failed',
        code: e.code,
        details: e,
      ));
    } catch (e) {
      return Left(AuthFailure(
        message: 'Unexpected authentication error',
        details: e,
      ));
    }
  }

  /// Create account with email and password
  Future<Either<Failure, User>> createAccount({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user == null) {
        return Left(AuthFailure(
          message: 'Account creation failed',
          code: 'CREATE_FAILED',
        ));
      }

      if (displayName != null) {
        await result.user!.updateDisplayName(displayName);
      }

      await _analytics.logSignUp(signUpMethod: 'email');
      return Right(result.user!);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message ?? 'Account creation failed',
        code: e.code,
        details: e,
      ));
    } catch (e) {
      return Left(AuthFailure(
        message: 'Unexpected error creating account',
        details: e,
      ));
    }
  }

  /// Sign out
  Future<Either<Failure, void>> signOut() async {
    try {
      await _auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(
        message: 'Sign out failed',
        details: e,
      ));
    }
  }

  /// Reset password
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(
        message: e.message ?? 'Password reset failed',
        code: e.code,
        details: e,
      ));
    } catch (e) {
      return Left(AuthFailure(
        message: 'Unexpected error resetting password',
        details: e,
      ));
    }
  }

  // ============================================
  // FIRESTORE OPERATIONS
  // ============================================

  /// Get user's Firestore collection reference
  CollectionReference _userContacts() {
    if (userId == null) {
      throw AuthException(
        message: 'User not authenticated',
        code: 'NOT_AUTHENTICATED',
      );
    }
    return _firestore.collection('users').doc(userId).collection('contacts');
  }

  /// Save contact to Firestore
  Future<Either<Failure, String>> saveContact(Map<String, dynamic> contactData) async {
    try {
      if (userId == null) {
        return Left(AuthFailure(
          message: 'User not authenticated',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      final docRef = await _userContacts().add(contactData);
      return Right(docRef.id);
    } on FirebaseException catch (e) {
      return Left(NetworkFailure(
        message: e.message ?? 'Failed to save contact',
        code: e.code,
        details: e,
      ));
    } catch (e) {
      return Left(NetworkFailure(
        message: 'Unexpected error saving contact',
        details: e,
      ));
    }
  }

  /// Update contact in Firestore
  Future<Either<Failure, void>> updateContact(
    String contactId,
    Map<String, dynamic> contactData,
  ) async {
    try {
      if (userId == null) {
        return Left(AuthFailure(
          message: 'User not authenticated',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      await _userContacts().doc(contactId).update(contactData);
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(NetworkFailure(
        message: e.message ?? 'Failed to update contact',
        code: e.code,
        details: e,
      ));
    } catch (e) {
      return Left(NetworkFailure(
        message: 'Unexpected error updating contact',
        details: e,
      ));
    }
  }

  /// Delete contact from Firestore
  Future<Either<Failure, void>> deleteContact(String contactId) async {
    try {
      if (userId == null) {
        return Left(AuthFailure(
          message: 'User not authenticated',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      await _userContacts().doc(contactId).delete();
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(NetworkFailure(
        message: e.message ?? 'Failed to delete contact',
        code: e.code,
        details: e,
      ));
    } catch (e) {
      return Left(NetworkFailure(
        message: 'Unexpected error deleting contact',
        details: e,
      ));
    }
  }

  /// Get all contacts from Firestore
  Future<Either<Failure, List<Map<String, dynamic>>>> getAllContacts() async {
    try {
      if (userId == null) {
        return Left(AuthFailure(
          message: 'User not authenticated',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      final snapshot = await _userContacts().get();
      final contacts = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      return Right(contacts);
    } on FirebaseException catch (e) {
      return Left(NetworkFailure(
        message: e.message ?? 'Failed to fetch contacts',
        code: e.code,
        details: e,
      ));
    } catch (e) {
      return Left(NetworkFailure(
        message: 'Unexpected error fetching contacts',
        details: e,
      ));
    }
  }

  /// Watch contacts in real-time
  Stream<List<Map<String, dynamic>>> watchContacts() {
    if (userId == null) {
      return Stream.error(AuthException(
        message: 'User not authenticated',
        code: 'NOT_AUTHENTICATED',
      ));
    }

    return _userContacts().snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    });
  }

  // ============================================
  // STORAGE OPERATIONS
  // ============================================

  /// Upload image to Firebase Storage
  Future<Either<Failure, String>> uploadImage(
    String localPath,
    String remotePath,
  ) async {
    try {
      if (userId == null) {
        return Left(AuthFailure(
          message: 'User not authenticated',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      final ref = _storage.ref().child('users/$userId/$remotePath');
      final uploadTask = await ref.putFile(File(localPath));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return Right(downloadUrl);
    } on FirebaseException catch (e) {
      return Left(NetworkFailure(
        message: e.message ?? 'Failed to upload image',
        code: e.code,
        details: e,
      ));
    } catch (e) {
      return Left(NetworkFailure(
        message: 'Unexpected error uploading image',
        details: e,
      ));
    }
  }

  /// Delete image from Firebase Storage
  Future<Either<Failure, void>> deleteImage(String remotePath) async {
    try {
      if (userId == null) {
        return Left(AuthFailure(
          message: 'User not authenticated',
          code: 'NOT_AUTHENTICATED',
        ));
      }

      final ref = _storage.ref().child('users/$userId/$remotePath');
      await ref.delete();

      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(NetworkFailure(
        message: e.message ?? 'Failed to delete image',
        code: e.code,
        details: e,
      ));
    } catch (e) {
      return Left(NetworkFailure(
        message: 'Unexpected error deleting image',
        details: e,
      ));
    }
  }

  // ============================================
  // ANALYTICS
  // ============================================

  /// Log custom event
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      // Silently fail analytics
    }
  }

  /// Set user properties
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      // Silently fail analytics
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      // Silently fail analytics
    }
  }
}

import 'dart:io';

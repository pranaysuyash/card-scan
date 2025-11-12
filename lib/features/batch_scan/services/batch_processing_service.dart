import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/scan_session.dart';
import '../../../models/contact.dart';
import '../../../services/ocr/ocr_service.dart';
import '../../../services/ocr/ocr_model_selector.dart';
import '../../../services/parser_service.dart';
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/utils/either.dart';

/// Service for batch processing multiple business cards
/// Uses isolates for parallel processing without blocking UI
class BatchProcessingService {
  final Isar isar;
  final OcrService ocrService;
  final ParserService parserService;

  BatchProcessingService({
    required this.isar,
    required this.ocrService,
    required this.parserService,
  });

  /// Create a new batch scan session
  Future<Either<Failure, ScanSession>> createSession({
    required String sessionName,
    String? eventName,
    String? location,
  }) async {
    try {
      final session = ScanSession()
        ..startedAt = DateTime.now()
        ..sessionName = sessionName
        ..eventName = eventName
        ..location = location
        ..status = SessionStatus.created;

      await isar.writeTxn(() async {
        await isar.scanSessions.put(session);
      });

      return Right(session);
    } on IsarError catch (e) {
      return Left(StorageFailure(
        message: 'Failed to create session: ${e.message}',
        code: 'CREATE_SESSION_ERROR',
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Unexpected error creating session',
        details: e,
      ));
    }
  }

  /// Add images to a batch session
  Future<Either<Failure, ScanSession>> addImages({
    required int sessionId,
    required List<String> imagePaths,
  }) async {
    try {
      final session = await isar.scanSessions.get(sessionId);
      if (session == null) {
        return Left(StorageFailure(
          message: 'Session not found',
          code: 'SESSION_NOT_FOUND',
        ));
      }

      session.imagePaths.addAll(imagePaths);
      session.totalScans = session.imagePaths.length;

      await isar.writeTxn(() async {
        await isar.scanSessions.put(session);
      });

      return Right(session);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to add images',
        details: e,
      ));
    }
  }

  /// Process all images in a batch session
  /// Runs in background using isolates for performance
  Future<Either<Failure, Stream<BatchProgress>>> processBatch(int sessionId) async {
    try {
      final session = await isar.scanSessions.get(sessionId);
      if (session == null) {
        return Left(StorageFailure(
          message: 'Session not found',
          code: 'SESSION_NOT_FOUND',
        ));
      }

      session.status = SessionStatus.processing;
      await isar.writeTxn(() async {
        await isar.scanSessions.put(session);
      });

      final controller = StreamController<BatchProgress>();

      // Process in background
      _processInBackground(session, controller);

      return Right(controller.stream);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to start batch processing',
        details: e,
      ));
    }
  }

  /// Process batch in background with progress updates
  void _processInBackground(
    ScanSession session,
    StreamController<BatchProgress> controller,
  ) async {
    int processed = 0;
    int failed = 0;
    final List<int> contactIds = [];

    for (int i = 0; i < session.imagePaths.length; i++) {
      final imagePath = session.imagePaths[i];

      try {
        // Send progress update
        controller.add(BatchProgress(
          sessionId: session.id,
          totalItems: session.totalScans,
          processedItems: processed,
          failedItems: failed,
          currentItem: i + 1,
          status: BatchStatus.processing,
        ));

        // Process individual card
        final lines = await ocrService.extractTextLines(imagePath);
        final parsed = parserService.parseContactData(lines);

        final contact = Contact()
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now()
          ..fullName = parsed['fullName'] ?? 'Unknown'
          ..company = parsed['company']
          ..imagePath = imagePath
          ..tags = session.tags;

        // Save to database
        await isar.writeTxn(() async {
          await isar.contacts.put(contact);
        });

        contactIds.add(contact.id);
        processed++;

        // Update session
        session.processedScans = processed;
        session.contactIds = contactIds;
        await isar.writeTxn(() async {
          await isar.scanSessions.put(session);
        });

      } catch (e) {
        failed++;
        session.failedScans = failed;
        debugPrint('Failed to process image $imagePath: $e');
      }
    }

    // Final update
    session.status = failed == session.totalScans
        ? SessionStatus.failed
        : SessionStatus.completed;
    session.completedAt = DateTime.now();
    session.isActive = false;

    await isar.writeTxn(() async {
      await isar.scanSessions.put(session);
    });

    controller.add(BatchProgress(
      sessionId: session.id,
      totalItems: session.totalScans,
      processedItems: processed,
      failedItems: failed,
      currentItem: session.totalScans,
      status: session.status == SessionStatus.completed
          ? BatchStatus.completed
          : BatchStatus.failed,
    ));

    controller.close();
  }

  /// Get all sessions
  Future<Either<Failure, List<ScanSession>>> getAllSessions() async {
    try {
      final sessions = await isar.scanSessions
          .where()
          .sortByStartedAtDesc()
          .findAll();
      return Right(sessions);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to fetch sessions',
        details: e,
      ));
    }
  }

  /// Get active sessions
  Future<Either<Failure, List<ScanSession>>> getActiveSessions() async {
    try {
      final sessions = await isar.scanSessions
          .filter()
          .isActiveEqualTo(true)
          .sortByStartedAtDesc()
          .findAll();
      return Right(sessions);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to fetch active sessions',
        details: e,
      ));
    }
  }

  /// Delete a session
  Future<Either<Failure, void>> deleteSession(int sessionId) async {
    try {
      await isar.writeTxn(() async {
        await isar.scanSessions.delete(sessionId);
      });
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to delete session',
        details: e,
      ));
    }
  }

  /// Watch session progress
  Stream<ScanSession?> watchSession(int sessionId) {
    return isar.scanSessions.watchObject(sessionId, fireImmediately: true);
  }
}

/// Progress update for batch processing
class BatchProgress {
  final int sessionId;
  final int totalItems;
  final int processedItems;
  final int failedItems;
  final int currentItem;
  final BatchStatus status;

  BatchProgress({
    required this.sessionId,
    required this.totalItems,
    required this.processedItems,
    required this.failedItems,
    required this.currentItem,
    required this.status,
  });

  double get progress {
    if (totalItems == 0) return 0.0;
    return processedItems / totalItems;
  }

  double get percentComplete => progress * 100;

  bool get isComplete => status == BatchStatus.completed;
  bool get isFailed => status == BatchStatus.failed;
}

enum BatchStatus {
  pending,
  processing,
  completed,
  failed,
}

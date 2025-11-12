import 'dart:io';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import '../../../models/contact.dart';
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/utils/either.dart';

/// Service for recording and transcribing voice notes
/// Supports on-device speech-to-text for privacy
class VoiceNoteService {
  final AudioRecorder _recorder = AudioRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isRecording = false;
  bool _isInitialized = false;

  bool get isRecording => _isRecording;
  bool get isInitialized => _isInitialized;

  /// Initialize speech-to-text
  Future<Either<Failure, bool>> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          _isInitialized = false;
        },
        onStatus: (status) {
          if (status == 'done') {
            _isRecording = false;
          }
        },
      );

      return Right(_isInitialized);
    } catch (e) {
      return Left(PermissionFailure(
        message: 'Failed to initialize speech recognition',
        details: e,
      ));
    }
  }

  /// Start recording audio
  Future<Either<Failure, String>> startRecording() async {
    try {
      // Check and request permissions
      if (!await _recorder.hasPermission()) {
        return Left(PermissionFailure(
          message: 'Microphone permission denied',
          code: 'MIC_PERMISSION_DENIED',
        ));
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${tempDir.path}/voice_note_$timestamp.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _isRecording = true;

      return Right(path);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to start recording',
        details: e,
      ));
    }
  }

  /// Stop recording
  Future<Either<Failure, String>> stopRecording() async {
    try {
      if (!_isRecording) {
        return Left(ValidationFailure(
          message: 'No active recording',
          code: 'NO_RECORDING',
        ));
      }

      final path = await _recorder.stop();
      _isRecording = false;

      if (path == null) {
        return Left(UnknownFailure(
          message: 'Failed to get recording path',
          code: 'NO_PATH',
        ));
      }

      return Right(path);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to stop recording',
        details: e,
      ));
    }
  }

  /// Cancel recording
  Future<Either<Failure, void>> cancelRecording() async {
    try {
      await _recorder.stop();
      _isRecording = false;
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to cancel recording',
        details: e,
      ));
    }
  }

  /// Transcribe audio file to text
  Future<Either<Failure, String>> transcribeAudio(String audioPath) async {
    try {
      if (!_isInitialized) {
        final initResult = await initialize();
        if (initResult.isLeft) {
          return Left(initResult.left);
        }
      }

      // For now, using live transcription as file transcription
      // requires additional processing. In production, you would
      // use a service like Google Cloud Speech-to-Text or AWS Transcribe
      return Left(UnknownFailure(
        message: 'File transcription not yet implemented',
        code: 'NOT_IMPLEMENTED',
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Transcription failed',
        details: e,
      ));
    }
  }

  /// Start live transcription
  Future<Either<Failure, Stream<String>>> startLiveTranscription() async {
    try {
      if (!_isInitialized) {
        final initResult = await initialize();
        if (initResult.isLeft) {
          return Left(initResult.left);
        }
      }

      if (!await _speech.hasPermission) {
        return Left(PermissionFailure(
          message: 'Microphone permission denied',
          code: 'MIC_PERMISSION_DENIED',
        ));
      }

      // This would return a stream of transcription results
      // For now, returning an error as full implementation requires
      // platform-specific code
      return Left(UnknownFailure(
        message: 'Live transcription stream not yet implemented',
        code: 'NOT_IMPLEMENTED',
      ));
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to start live transcription',
        details: e,
      ));
    }
  }

  /// Add voice note to contact
  Future<Either<Failure, Contact>> addVoiceNoteToContact({
    required Contact contact,
    required String audioPath,
    String? transcription,
  }) async {
    try {
      // Create note item
      final note = NoteItem()
        ..content = transcription ?? 'Voice note'
        ..timestamp = DateTime.now()
        ..audioPath = audioPath;

      // Add to contact
      contact.notes.add(note);
      contact.updatedAt = DateTime.now();

      // Add activity
      final activity = Activity()
        ..type = ActivityType.note
        ..timestamp = DateTime.now()
        ..description = 'Added voice note';
      contact.activity.add(activity);

      return Right(contact);
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Failed to add voice note to contact',
        details: e,
      ));
    }
  }

  /// Extract keywords from transcription
  List<String> extractKeywords(String transcription) {
    // Simple keyword extraction
    // In production, use NLP library for better extraction
    final words = transcription.toLowerCase().split(RegExp(r'\W+'));
    final stopWords = {
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to',
      'for', 'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are',
      'were', 'been', 'be', 'have', 'has', 'had', 'do', 'does', 'did',
      'will', 'would', 'should', 'could', 'may', 'might', 'must',
      'can', 'this', 'that', 'these', 'those', 'i', 'you', 'he',
      'she', 'it', 'we', 'they', 'them', 'their', 'what', 'which',
      'who', 'when', 'where', 'why', 'how',
    };

    final keywords = words
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .toSet()
        .toList();

    return keywords.take(10).toList();
  }

  /// Clean up temporary audio files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file is File && file.path.contains('voice_note_')) {
          await file.delete();
        }
      }
    } catch (e) {
      // Silently fail cleanup
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
      }
      await _recorder.dispose();
    } catch (e) {
      // Silently fail disposal
    }
  }
}

/// Add audioPath to NoteItem
extension NoteItemAudio on NoteItem {
  String? audioPath;
}

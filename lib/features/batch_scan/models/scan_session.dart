import 'package:isar/isar.dart';

part 'scan_session.g.dart';

@collection
class ScanSession {
  Id id = Isar.autoIncrement;

  late DateTime startedAt;
  DateTime? completedAt;

  late String sessionName;
  String? eventName;
  String? location;

  List<int> contactIds = [];
  List<String> imagePaths = [];

  int totalScans = 0;
  int processedScans = 0;
  int failedScans = 0;

  @enumerated
  late SessionStatus status;

  String? notes;
  List<String> tags = [];

  @Index()
  bool isActive = true;

  double get progress {
    if (totalScans == 0) return 0.0;
    return processedScans / totalScans;
  }

  bool get isComplete => status == SessionStatus.completed;
  bool get isProcessing => status == SessionStatus.processing;
  bool get isFailed => status == SessionStatus.failed;
}

enum SessionStatus {
  created,
  processing,
  completed,
  failed,
  cancelled,
}

@embedded
class BatchScanItem {
  late String imagePath;
  int? contactId;

  @enumerated
  late BatchItemStatus status;

  String? errorMessage;
  DateTime? processedAt;

  double confidence = 0.0;
}

enum BatchItemStatus {
  pending,
  processing,
  completed,
  failed,
}

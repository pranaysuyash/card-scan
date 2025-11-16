import 'package:isar/isar.dart';

part 'contact_interaction.g.dart';

/// Tracks interactions with a contact (calls, emails, meetings, notes)
@collection
class ContactInteraction {
  Id id = Isar.autoIncrement;

  /// ID of the contact this interaction belongs to
  @Index()
  late int contactId;

  /// Type of interaction
  @Enumerated(EnumType.name)
  late InteractionType type;

  /// Date and time of the interaction
  @Index()
  late DateTime timestamp;

  /// Title or subject of the interaction
  String? title;

  /// Detailed notes about the interaction
  String? notes;

  /// Duration in minutes (for calls, meetings)
  int? durationMinutes;

  /// Location (for meetings)
  String? location;

  /// Outcome or result
  String? outcome;

  /// Follow-up required
  bool followUpRequired = false;

  /// Follow-up date
  DateTime? followUpDate;

  /// Sentiment (positive, neutral, negative)
  @Enumerated(EnumType.name)
  InteractionSentiment sentiment = InteractionSentiment.neutral;

  /// Tags for this interaction
  List<String> tags = [];

  /// Attachments or references
  List<String> attachments = [];

  /// Created timestamp
  late DateTime createdAt;

  /// Last updated timestamp
  late DateTime updatedAt;

  ContactInteraction() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    timestamp = DateTime.now();
  }
}

enum InteractionType {
  call,
  email,
  meeting,
  note,
  message,
  linkedin,
  other,
}

enum InteractionSentiment {
  positive,
  neutral,
  negative,
}

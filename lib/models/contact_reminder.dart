import 'package:isar/isar.dart';

part 'contact_reminder.g.dart';

/// Reminder to follow up with a contact
@collection
class ContactReminder {
  Id id = Isar.autoIncrement;

  /// ID of the contact
  @Index()
  late int contactId;

  /// Reminder title
  late String title;

  /// Reminder notes
  String? notes;

  /// Due date and time
  @Index()
  late DateTime dueDate;

  /// Reminder type
  @Enumerated(EnumType.name)
  late ReminderType type;

  /// Is completed
  bool isCompleted = false;

  /// Completed timestamp
  DateTime? completedAt;

  /// Priority
  @Enumerated(EnumType.name)
  ReminderPriority priority = ReminderPriority.medium;

  /// Notification sent
  bool notificationSent = false;

  /// Repeat interval (for recurring reminders)
  @Enumerated(EnumType.name)
  RepeatInterval? repeatInterval;

  /// Created timestamp
  late DateTime createdAt;

  /// Last updated timestamp
  late DateTime updatedAt;

  ContactReminder() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// Check if reminder is overdue
  @ignore
  bool get isOverdue {
    if (isCompleted) return false;
    return DateTime.now().isAfter(dueDate);
  }

  /// Check if reminder is today
  @ignore
  bool get isToday {
    if (isCompleted) return false;
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }
}

enum ReminderType {
  followUp,
  birthday,
  meeting,
  call,
  email,
  custom,
}

enum ReminderPriority {
  low,
  medium,
  high,
  urgent,
}

enum RepeatInterval {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
}

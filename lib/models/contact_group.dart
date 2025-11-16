import 'package:isar/isar.dart';

part 'contact_group.g.dart';

/// Represents a group or list of contacts
@collection
class ContactGroup {
  Id id = Isar.autoIncrement;

  /// Group name
  @Index(unique: true)
  late String name;

  /// Group description
  String? description;

  /// Color for the group (hex string)
  String? color;

  /// Icon name
  String? icon;

  /// IDs of contacts in this group
  List<int> contactIds = [];

  /// Group type
  @Enumerated(EnumType.name)
  late GroupType type;

  /// Sort order
  int sortOrder = 0;

  /// Is this a smart group (auto-populated)
  bool isSmartGroup = false;

  /// Smart group filter criteria (JSON)
  String? smartGroupCriteria;

  /// Created timestamp
  late DateTime createdAt;

  /// Last updated timestamp
  late DateTime updatedAt;

  /// Number of contacts (computed)
  @ignore
  int get contactCount => contactIds.length;

  ContactGroup() {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    type = GroupType.custom;
  }

  /// Factory for creating default groups
  static ContactGroup favorites() {
    return ContactGroup()
      ..name = 'Favorites'
      ..description = 'Your favorite contacts'
      ..color = '#FFD700'
      ..icon = 'star'
      ..type = GroupType.favorites;
  }

  static ContactGroup recent() {
    return ContactGroup()
      ..name = 'Recent'
      ..description = 'Recently added contacts'
      ..color = '#4CAF50'
      ..icon = 'access_time'
      ..type = GroupType.recent
      ..isSmartGroup = true;
  }

  static ContactGroup vip() {
    return ContactGroup()
      ..name = 'VIP'
      ..description = 'Very important contacts'
      ..color = '#9C27B0'
      ..icon = 'verified'
      ..type = GroupType.vip;
  }
}

enum GroupType {
  custom,
  favorites,
  recent,
  vip,
  work,
  personal,
  event,
}

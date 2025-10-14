import 'package:isar/isar.dart';

part 'contact.g.dart';

@collection
class Contact {
  Id id = Isar.autoIncrement;

  late DateTime createdAt;
  late DateTime updatedAt;

  @Index()
  late String fullName;

  String? givenName;
  String? familyName;
  String? title;

  @Index()
  String? company;

  List<EmailItem> emails = [];
  List<PhoneItem> phones = [];

  String? website;
  String? address;

  // Social Media & Digital Presence (HiHello, Popl inspired)
  String? linkedIn;
  String? facebook;
  String? twitter;
  String? instagram;
  String? youtube;
  String? github;
  String? whatsapp;

  // Professional Info (Covve, CamCard inspired)
  String? department;
  String? jobFunction;
  String? industry;
  List<String> skills = [];

  // Digital Card Features (HiHello, Haystack inspired)
  String? profileImageUrl;
  String? companyLogo;
  String? qrCode;
  String? digitalCardUrl;

  // CRM & Relationship (Covve, Popl inspired)
  DateTime? lastContacted;
  String? leadSource;
  String? leadStatus;
  int contactScore = 0;
  List<String> interests = [];

  // Export & Integration
  bool syncedToContacts = false;
  String? crmId;
  DateTime? lastSynced;

  @Index()
  List<String> tags = [];

  String? imagePath;
  String? thumbPath;

  List<NoteItem> notes = [];
  List<Activity> activity = [];

  bool isFavorite = false;
}

@embedded
class EmailItem {
  late String value;
  double confidence = 1.0;
  String type = 'work';
}

@embedded
class PhoneItem {
  late String value;
  double confidence = 1.0;
  String? e164;
  String type = 'work';
}

@embedded
class NoteItem {
  late DateTime createdAt;
  String? text;
  String? audioPath;
  String? transcript;
}

@embedded
class Activity {
  late DateTime timestamp;
  late String type;
  @ignore
  Map<String, String> meta = {};
}

class OcrResult {
  final List<String> lines;
  final Map<String, dynamic> parsed;
  final Map<String, double> confidence;

  OcrResult({
    required this.lines,
    required this.parsed,
    required this.confidence,
  });
}

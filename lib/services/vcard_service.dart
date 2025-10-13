import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/contact.dart';

class VCardService {
  /// Export contacts to a vCard (.vcf) file
  Future<void> exportContactsToVCard(List<Contact> contacts) async {
    if (contacts.isEmpty) {
      throw Exception('No contacts to export');
    }

    final vcfContent = _generateVCardContent(contacts);

    // Get temporary directory
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'contacts_$timestamp.vcf';
    final filePath = '${tempDir.path}/$fileName';

    // Write to file
    final file = File(filePath);
    await file.writeAsString(vcfContent, flush: true);

    // Share the file
    final result = await Share.shareXFiles(
      [XFile(filePath, mimeType: 'text/vcard')],
      subject: 'Exported Contacts',
      text: 'Here are ${contacts.length} contacts from Card Scan',
    );

    // Clean up after sharing (if not sharing anymore)
    if (result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed) {
      // Delay deletion to ensure the file is not in use
      Future.delayed(const Duration(seconds: 2), () {
        try {
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          // Ignore deletion errors
        }
      });
    }
  }

  /// Export a single contact to vCard
  Future<void> exportSingleContact(Contact contact) async {
    await exportContactsToVCard([contact]);
  }

  /// Generate vCard 4.0 content from contacts
  String _generateVCardContent(List<Contact> contacts) {
    final buffer = StringBuffer();

    for (final contact in contacts) {
      buffer.writeln('BEGIN:VCARD');
      buffer.writeln('VERSION:4.0');

      // Full name (FN) - required
      buffer.writeln('FN:${_escapeVCardValue(contact.fullName)}');

      // Structured name (N) - FAMILY;GIVEN;ADDITIONAL;PREFIX;SUFFIX
      final nameParts = _parseFullName(contact.fullName);
      buffer.writeln('N:${nameParts['family']};${nameParts['given']};;;');

      // Organization
      if (contact.company != null && contact.company!.isNotEmpty) {
        buffer.writeln('ORG:${_escapeVCardValue(contact.company!)}');
      }

      // Title/Role
      if (contact.title != null && contact.title!.isNotEmpty) {
        buffer.writeln('TITLE:${_escapeVCardValue(contact.title!)}');
      }

      // Phone numbers
      for (final phone in contact.phones) {
        final type = phone.type.toUpperCase();
        buffer.writeln('TEL;TYPE=$type:${_escapeVCardValue(phone.value)}');
      }

      // Email addresses
      for (final email in contact.emails) {
        final type = email.type.toUpperCase();
        buffer.writeln('EMAIL;TYPE=$type:${_escapeVCardValue(email.value)}');
      }

      // Website/URL
      if (contact.website != null && contact.website!.isNotEmpty) {
        buffer.writeln('URL:${_escapeVCardValue(contact.website!)}');
      }

      // Address
      if (contact.address != null && contact.address!.isNotEmpty) {
        // ADR format: ;;street;city;region;postal-code;country
        buffer.writeln(
            'ADR;TYPE=WORK:;;${_escapeVCardValue(contact.address!)};;;;');
      }

      // Notes - combine all notes
      if (contact.notes.isNotEmpty) {
        final notesText = contact.notes
            .map((note) => note.text ?? note.transcript ?? '')
            .where((text) => text.isNotEmpty)
            .join('\n---\n');
        if (notesText.isNotEmpty) {
          buffer.writeln('NOTE:${_escapeVCardValue(notesText)}');
        }
      }

      // Custom fields for our app-specific data
      if (contact.isFavorite) {
        buffer.writeln('X-CARDSCAN-FAVORITE:true');
      }

      // Created and modified timestamps
      buffer.writeln('REV:${_formatTimestamp(contact.updatedAt)}');

      buffer.writeln('END:VCARD');
    }

    return buffer.toString();
  }

  /// Import contacts from a vCard file
  Future<List<Contact>> importContactsFromVCard() async {
    // Let user pick a .vcf file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['vcf', 'vcard'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      throw Exception('Could not read file path');
    }

    final file = File(filePath);
    final content = await file.readAsString();

    return _parseVCardContent(content);
  }

  /// Parse vCard content into Contact objects
  List<Contact> _parseVCardContent(String content) {
    final contacts = <Contact>[];
    final lines = content.split('\n').map((l) => l.trim()).toList();

    Contact? currentContact;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('BEGIN:VCARD')) {
        currentContact = Contact()
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
      } else if (line.startsWith('END:VCARD') && currentContact != null) {
        if (currentContact.fullName.isNotEmpty) {
          contacts.add(currentContact);
        }
        currentContact = null;
      } else if (currentContact != null) {
        _parseVCardLine(line, currentContact);
      }
    }

    return contacts;
  }

  /// Parse a single vCard line and update the contact
  void _parseVCardLine(String line, Contact contact) {
    if (line.isEmpty || !line.contains(':')) return;

    final colonIndex = line.indexOf(':');
    final fieldPart = line.substring(0, colonIndex);
    final value = _unescapeVCardValue(line.substring(colonIndex + 1));

    // Extract field name and parameters
    final fieldParts = fieldPart.split(';');
    final fieldName = fieldParts[0];
    final params = <String, String>{};

    for (var i = 1; i < fieldParts.length; i++) {
      final parts = fieldParts[i].split('=');
      if (parts.length == 2) {
        params[parts[0].toUpperCase()] = parts[1].toUpperCase();
      }
    }

    // Parse based on field name
    switch (fieldName.toUpperCase()) {
      case 'FN':
        contact.fullName = value;
        break;

      case 'ORG':
        contact.company = value;
        break;

      case 'TITLE':
        contact.title = value;
        break;

      case 'TEL':
        final type = params['TYPE']?.toLowerCase() ?? 'work';
        contact.phones.add(PhoneItem()
          ..value = value
          ..type = type
          ..confidence = 1.0);
        break;

      case 'EMAIL':
        final type = params['TYPE']?.toLowerCase() ?? 'work';
        contact.emails.add(EmailItem()
          ..value = value
          ..type = type
          ..confidence = 1.0);
        break;

      case 'URL':
        contact.website = value;
        break;

      case 'ADR':
        // Parse address (format: ;;street;city;region;postal;country)
        final addressParts = value.split(';');
        if (addressParts.length > 2) {
          final street = addressParts[2];
          contact.address = street;
        }
        break;

      case 'NOTE':
        if (value.isNotEmpty) {
          final noteTexts = value.split('\n---\n');
          for (final noteText in noteTexts) {
            if (noteText.trim().isNotEmpty) {
              contact.notes.add(NoteItem()
                ..createdAt = DateTime.now()
                ..text = noteText.trim());
            }
          }
        }
        break;

      case 'X-CARDSCAN-FAVORITE':
        contact.isFavorite = value.toLowerCase() == 'true';
        break;
    }
  }

  /// Parse full name into family and given names
  Map<String, String> _parseFullName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty) {
      return {'family': '', 'given': ''};
    } else if (parts.length == 1) {
      return {'family': parts[0], 'given': ''};
    } else {
      // Last part is family name, rest is given name
      final givenParts = parts.sublist(0, parts.length - 1);
      final familyName = parts.last;
      return {
        'family': _escapeVCardValue(familyName),
        'given': _escapeVCardValue(givenParts.join(' ')),
      };
    }
  }

  /// Escape special characters in vCard values
  String _escapeVCardValue(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;')
        .replaceAll('\n', '\\n');
  }

  /// Unescape vCard values
  String _unescapeVCardValue(String value) {
    return value
        .replaceAll('\\n', '\n')
        .replaceAll('\\;', ';')
        .replaceAll('\\,', ',')
        .replaceAll('\\\\', '\\');
  }

  /// Format timestamp for vCard REV field
  String _formatTimestamp(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Export to CSV (secondary option for spreadsheets)
  Future<void> exportContactsToCSV(List<Contact> contacts) async {
    if (contacts.isEmpty) {
      throw Exception('No contacts to export');
    }

    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
        'Full Name,Title,Company,Email,Phone,Website,Address,Created,Updated');

    // CSV Rows
    for (final contact in contacts) {
      final email = contact.emails.isNotEmpty ? contact.emails.first.value : '';
      final phone = contact.phones.isNotEmpty ? contact.phones.first.value : '';

      buffer.writeln([
        _escapeCsvValue(contact.fullName),
        _escapeCsvValue(contact.title ?? ''),
        _escapeCsvValue(contact.company ?? ''),
        _escapeCsvValue(email),
        _escapeCsvValue(phone),
        _escapeCsvValue(contact.website ?? ''),
        _escapeCsvValue(contact.address ?? ''),
        contact.createdAt.toIso8601String(),
        contact.updatedAt.toIso8601String(),
      ].join(','));
    }

    // Get temporary directory
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'contacts_$timestamp.csv';
    final filePath = '${tempDir.path}/$fileName';

    // Write to file
    final file = File(filePath);
    await file.writeAsString(buffer.toString(), flush: true);

    // Share the file
    final result = await Share.shareXFiles(
      [XFile(filePath, mimeType: 'text/csv')],
      subject: 'Exported Contacts (CSV)',
      text: 'Here are ${contacts.length} contacts from Card Scan in CSV format',
    );

    // Clean up
    if (result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.dismissed) {
      Future.delayed(const Duration(seconds: 2), () {
        try {
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          // Ignore
        }
      });
    }
  }

  /// Escape CSV values
  String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

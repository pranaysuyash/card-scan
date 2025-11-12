import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../models/contact.dart';
import '../../../core/error/failures.dart';
import '../../../core/utils/either.dart';

/// Service for generating and handling QR codes for contacts
/// Supports vCard format for universal compatibility
class QrCodeService {
  /// Generate vCard formatted string from contact
  String generateVCard(Contact contact) {
    final buffer = StringBuffer();

    buffer.writeln('BEGIN:VCARD');
    buffer.writeln('VERSION:3.0');

    // Name
    if (contact.familyName != null && contact.givenName != null) {
      buffer.writeln('N:${contact.familyName};${contact.givenName};;;');
    }
    buffer.writeln('FN:${contact.fullName}');

    // Organization and Title
    if (contact.company != null) {
      buffer.writeln('ORG:${contact.company}');
    }
    if (contact.title != null) {
      buffer.writeln('TITLE:${contact.title}');
    }

    // Phone numbers
    for (final phone in contact.phones) {
      final type = phone.type.toUpperCase();
      buffer.writeln('TEL;TYPE=$type:${phone.value}');
    }

    // Email addresses
    for (final email in contact.emails) {
      final type = email.type.toUpperCase();
      buffer.writeln('EMAIL;TYPE=$type:${email.value}');
    }

    // Website
    if (contact.website != null) {
      buffer.writeln('URL:${contact.website}');
    }

    // Address
    if (contact.address != null) {
      buffer.writeln('ADR:;;${contact.address};;;;');
    }

    // Social media URLs
    if (contact.linkedIn != null) {
      buffer.writeln('URL;TYPE=LinkedIn:${contact.linkedIn}');
    }
    if (contact.twitter != null) {
      buffer.writeln('URL;TYPE=Twitter:${contact.twitter}');
    }
    if (contact.facebook != null) {
      buffer.writeln('URL;TYPE=Facebook:${contact.facebook}');
    }
    if (contact.instagram != null) {
      buffer.writeln('URL;TYPE=Instagram:${contact.instagram}');
    }
    if (contact.github != null) {
      buffer.writeln('URL;TYPE=GitHub:${contact.github}');
    }

    // Notes
    if (contact.notes.isNotEmpty) {
      final noteText = contact.notes.first.content;
      buffer.writeln('NOTE:$noteText');
    }

    buffer.writeln('END:VCARD');

    return buffer.toString();
  }

  /// Generate QR code image from contact
  Future<Either<Failure, Uint8List>> generateQrCodeImage({
    required Contact contact,
    int size = 512,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) async {
    try {
      final vCard = generateVCard(contact);

      final qrValidationResult = QrValidator.validate(
        data: vCard,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
      );

      if (qrValidationResult.status == QrValidationStatus.error) {
        return Left(ValidationFailure(
          message: 'Invalid QR code data',
          code: 'QR_VALIDATION_ERROR',
        ));
      }

      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: foregroundColor,
        emptyColor: backgroundColor,
        gapless: true,
        embeddedImageStyle: null,
        embeddedImage: null,
      );

      final picturRecorder = ui.PictureRecorder();
      final canvas = Canvas(picturRecorder);
      painter.paint(canvas, Size(size.toDouble(), size.toDouble()));

      final picture = picturRecorder.endRecording();
      final image = await picture.toImage(size, size);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return Left(UnknownFailure(
          message: 'Failed to generate QR code image',
          code: 'QR_IMAGE_ERROR',
        ));
      }

      return Right(byteData.buffer.asUint8List());
    } catch (e) {
      return Left(UnknownFailure(
        message: 'Error generating QR code',
        details: e,
      ));
    }
  }

  /// Generate QR code widget for display
  Widget generateQrCodeWidget({
    required Contact contact,
    double size = 280.0,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
    bool includeEmbeddedImage = false,
  }) {
    final vCard = generateVCard(contact);

    return QrImageView(
      data: vCard,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      errorCorrectionLevel: QrErrorCorrectLevel.H,
      gapless: true,
      padding: const EdgeInsets.all(16),
    );
  }

  /// Parse vCard from QR code scan result
  Future<Either<Failure, Contact>> parseVCard(String vCardData) async {
    try {
      final contact = Contact()
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final lines = vCardData.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();

        if (trimmed.startsWith('FN:')) {
          contact.fullName = trimmed.substring(3);
        } else if (trimmed.startsWith('N:')) {
          final parts = trimmed.substring(2).split(';');
          if (parts.isNotEmpty) contact.familyName = parts[0];
          if (parts.length > 1) contact.givenName = parts[1];
        } else if (trimmed.startsWith('ORG:')) {
          contact.company = trimmed.substring(4);
        } else if (trimmed.startsWith('TITLE:')) {
          contact.title = trimmed.substring(6);
        } else if (trimmed.startsWith('TEL')) {
          final value = _extractValue(trimmed);
          final type = _extractType(trimmed);
          contact.phones.add(PhoneItem()
            ..value = value
            ..type = type
            ..confidence = 1.0);
        } else if (trimmed.startsWith('EMAIL')) {
          final value = _extractValue(trimmed);
          final type = _extractType(trimmed);
          contact.emails.add(EmailItem()
            ..value = value
            ..type = type
            ..confidence = 1.0);
        } else if (trimmed.startsWith('URL:') && !trimmed.contains('TYPE=')) {
          contact.website = trimmed.substring(4);
        } else if (trimmed.contains('TYPE=LinkedIn')) {
          contact.linkedIn = _extractValue(trimmed);
        } else if (trimmed.contains('TYPE=Twitter')) {
          contact.twitter = _extractValue(trimmed);
        } else if (trimmed.contains('TYPE=Facebook')) {
          contact.facebook = _extractValue(trimmed);
        } else if (trimmed.contains('TYPE=Instagram')) {
          contact.instagram = _extractValue(trimmed);
        } else if (trimmed.contains('TYPE=GitHub')) {
          contact.github = _extractValue(trimmed);
        } else if (trimmed.startsWith('ADR:')) {
          contact.address = trimmed.substring(4).replaceAll(';;', '').replaceAll(';;;;', '');
        } else if (trimmed.startsWith('NOTE:')) {
          final note = NoteItem()
            ..content = trimmed.substring(5)
            ..timestamp = DateTime.now();
          contact.notes.add(note);
        }
      }

      // Validation
      if (contact.fullName.isEmpty) {
        return Left(ValidationFailure(
          message: 'Invalid vCard: missing name',
          code: 'INVALID_VCARD',
        ));
      }

      return Right(contact);
    } catch (e) {
      return Left(ParseFailure(
        message: 'Failed to parse vCard',
        details: e,
      ));
    }
  }

  String _extractValue(String line) {
    final colonIndex = line.lastIndexOf(':');
    if (colonIndex == -1) return '';
    return line.substring(colonIndex + 1);
  }

  String _extractType(String line) {
    final typeMatch = RegExp(r'TYPE=(\w+)').firstMatch(line);
    return typeMatch?.group(1)?.toLowerCase() ?? 'work';
  }

  /// Generate digital business card URL
  String generateDigitalCardUrl(Contact contact) {
    // This would typically point to a web view of the contact
    // For now, we'll generate a placeholder
    return 'https://cardscan.app/card/${contact.id}';
  }

  /// Save QR code to contact
  Future<Either<Failure, Contact>> saveQrCodeToContact(
    Contact contact,
    Uint8List qrCodeImage,
  ) async {
    try {
      // In a real implementation, you would save the image
      // and update the contact with the path
      contact.qrCode = 'qr_code_${contact.id}.png';
      contact.updatedAt = DateTime.now();
      return Right(contact);
    } catch (e) {
      return Left(StorageFailure(
        message: 'Failed to save QR code',
        details: e,
      ));
    }
  }
}

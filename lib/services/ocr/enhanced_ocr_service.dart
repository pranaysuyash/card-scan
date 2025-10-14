import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../models/contact.dart';
import '../parser_service.dart';
import 'ocr_service.dart';

class EnhancedLocalOcrService implements OcrService {
  final TextRecognizer _recognizer = TextRecognizer();
  final ParserService _parser = ParserService();

  // Business card specific enhancements
  static const double businessCardConfidenceThreshold = 0.7;
  static const List<String> businessCardKeywords = [
    'CEO', 'CTO', 'Manager', 'Director', 'Engineer', 'Developer',
    'Sales', 'Marketing', 'Business', 'Contact', 'Phone', 'Email',
    'www.', '.com', '.org', '.net', '@', '+', 'ext:', 'Suite', 'Apt'
  ];

  @override
  Future<List<String>> extractTextLines(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      // Pre-process image for better business card recognition
      final enhancedImage = await _enhanceImageForBusinessCards(imagePath);
      final finalInputImage = enhancedImage != null
          ? InputImage.fromFilePath(enhancedImage.path)
          : inputImage;

      final RecognizedText recognizedText = await _recognizer.processImage(finalInputImage);

      final lines = <String>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          if (line.text.trim().isNotEmpty) {
            final processedText = _postProcessLine(line.text.trim());
            if (_isBusinessCardContent(processedText)) {
              lines.add(processedText);
            }
          }
        }
      }

      // If we didn't get enough lines, try alternative processing
      if (lines.length < 2) {
        final fallbackLines = await _extractWithAlternativeMethods(imagePath);
        lines.addAll(fallbackLines);
      }

      return lines.toSet().toList(); // Remove duplicates
    } catch (e) {
      print('Enhanced OCR Error: $e');
      return _extractWithAlternativeMethods(imagePath);
    }
  }

  Future<String?> _enhanceImageForBusinessCards(String imagePath) async {
    try {
      final image = img.decodeImage(File(imagePath).readAsBytesSync())!;
      final enhanced = img.copyRotate(image, angle: -90); // Try rotation
      final tempDir = await getTemporaryDirectory();
      final enhancedPath = '${tempDir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final enhancedFile = File(enhancedPath);

      final jpegData = img.encodeJpg(enhanced, quality: 95);
      await enhancedFile.writeAsBytes(jpegData);

      return enhancedPath;
    } catch (e) {
      return null;
    }
  }

  String _postProcessLine(String text) {
    // Clean up common OCR errors in business cards
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'(\d)\s+(\d)'), r'$1$2') // Fix split numbers
        .replaceAll(RegExp(r'([a-zA-Z])\s+([a-zA-Z])'), r'$1$2') // Fix split words
        .trim();
  }

  bool _isBusinessCardContent(String text) {
    // Filter out likely non-business card content
    if (text.length < 2) return false;
    if (text.length > 100) return false; // Too long for business card

    // Check for business card indicators
    final hasKeyword = businessCardKeywords.any((keyword) =>
        text.toLowerCase().contains(keyword.toLowerCase()));

    final hasEmail = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(text);
    final hasPhone = RegExp(r'[\+]?[1-9][\d\s\-\(\)]{7,}').hasMatch(text);
    final hasUrl = text.toLowerCase().contains('www.') || text.contains('.') && text.contains('/');

    return hasKeyword || hasEmail || hasPhone || hasUrl || text.split(' ').length <= 10;
  }

  Future<List<String>> _extractWithAlternativeMethods(String imagePath) async {
    final lines = <String>[];

    // Try multiple angles
    for (final angle in [0, 90, 180, 270]) {
      try {
        final rotatedImage = await _rotateAndExtract(imagePath, angle);
        lines.addAll(rotatedImage);
        if (lines.length >= 3) break; // Found enough content
      } catch (e) {
        continue;
      }
    }

    return lines.toSet().toList();
  }

  Future<List<String>> _rotateAndExtract(String imagePath, int angle) async {
    final lines = <String>[];
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _recognizer.processImage(inputImage);

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          if (line.text.trim().isNotEmpty) {
            final processedText = _postProcessLine(line.text.trim());
            if (_isBusinessCardContent(processedText)) {
              lines.add(processedText);
            }
          }
        }
      }
    } catch (e) {
      // Ignore rotation errors
    }
    return lines;
  }

  @override
  Future<OcrResult> processImage(String imagePath) async {
    final lines = await extractTextLines(imagePath);
    final parsed = _parser.parseLines(lines);
    final confidence = _calculateBusinessCardConfidence(lines, parsed);

    return OcrResult(
      lines: lines,
      parsed: parsed,
      confidence: {'overall': confidence},
    );
  }

  double _calculateBusinessCardConfidence(List<String> lines, Map<String, dynamic> parsed) {
    var confidence = 0.0;
    var factors = 0;

    // Email confidence
    if (parsed['emails'] is List && (parsed['emails'] as List).isNotEmpty) {
      confidence += 0.3;
      factors++;
    }

    // Phone confidence
    if (parsed['phones'] is List && (parsed['phones'] as List).isNotEmpty) {
      confidence += 0.25;
      factors++;
    }

    // Name confidence
    if (parsed['fullName'] is String && (parsed['fullName'] as String).isNotEmpty) {
      confidence += 0.2;
      factors++;
    }

    // Company confidence
    if (parsed['company'] is String && (parsed['company'] as String).isNotEmpty) {
      confidence += 0.15;
      factors++;
    }

    // Website confidence
    if (parsed['website'] is String && (parsed['website'] as String).isNotEmpty) {
      confidence += 0.1;
      factors++;
    }

    return factors > 0 ? confidence / factors : 0.3; // Default low confidence
  }

  void dispose() {
    _recognizer.close();
  }
}
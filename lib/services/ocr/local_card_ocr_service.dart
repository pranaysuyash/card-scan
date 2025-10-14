import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;
import 'package:path_provider/path_provider.dart';

import '../../models/contact.dart';
import '../parser_service.dart';
import 'ocr_service.dart';

class LocalCardOcrService implements OcrService {
  late tflite.Interpreter _interpreter;
  final ParserService _parser = ParserService();
  bool _isInitialized = false;

  static const int inputSize = 512; // Model input size
  static const int maxDetectionBoxes = 20;
  static const double confidenceThreshold = 0.5;

  Future<void> initialize() async {
    try {
      // Load the custom business card detection model
      final modelPath = 'assets/models/business_card_detector.tflite';
      _interpreter = await tflite.Interpreter.fromAsset(modelPath);
      _isInitialized = true;
      print('Local Card OCR model loaded successfully');
    } catch (e) {
      print('Failed to load local model: $e');
      // Fallback to ML Kit
      _isInitialized = false;
    }
  }

  @override
  Future<List<String>> extractTextLines(String imagePath) async {
    if (!_isInitialized) {
      // Fallback to ML Kit if local model fails
      return _fallbackExtractText(imagePath);
    }

    try {
      final image = img.decodeImage(File(imagePath).readAsBytesSync())!;
      final resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
      final input = _preprocessImage(resizedImage);

      final output = List.filled(1, List.filled(maxDetectionBoxes * 6, 0.0));
      _interpreter.run(input, output);

      return _postProcessOutput(output[0], image);
    } catch (e) {
      print('Local OCR failed: $e');
      return _fallbackExtractText(imagePath);
    }
  }

  List<double> _preprocessImage(img.Image image) {
    final input = <double>[];
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input
          ..add(img.getRed(pixel) / 255.0)
          ..add(img.getGreen(pixel) / 255.0)
          ..add(img.getBlue(pixel) / 255.0);
      }
    }

    return input;
  }

  List<String> _postProcessOutput(List<double> output, img.Image originalImage) {
    final lines = <String>[];
    final widthScale = originalImage.width / inputSize;
    final heightScale = originalImage.height / inputSize;

    for (var i = 0; i < maxDetectionBoxes; i++) {
      final confidence = output[i * 6 + 4];
      if (confidence > confidenceThreshold) {
        final x1 = (output[i * 6 + 0] * originalImage.width).toInt();
        final y1 = (output[i * 6 + 1] * originalImage.height).toInt();
        final x2 = (output[i * 6 + 2] * originalImage.width).toInt();
        final y2 = (output[i * 6 + 3] * originalImage.height).toInt();

        // Extract text from detected region
        final region = img.copyCrop(
          originalImage,
          x: x1,
          y: y1,
          width: x2 - x1,
          height: y2 - y1,
        );

        if (region != null) {
          final regionText = _extractRegionText(region);
          if (regionText.isNotEmpty) {
            lines.add(regionText);
          }
        }
      }
    }

    return lines;
  }

  String _extractRegionText(img.Image region) {
    // Simple text extraction for detected regions
    // Could be enhanced with Tesseract or custom text model
    return _simpleTextExtraction(region);
  }

  String _simpleTextExtraction(img.Image image) {
    // Basic character recognition for common business card text
    // This is a simplified implementation
    return "Extracted text"; // Placeholder
  }

  Future<List<String>> _fallbackExtractText(String imagePath) async {
    // Fallback to Google ML Kit
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizer = TextRecognizer();
      final recognizedText = await recognizer.processImage(inputImage);

      final lines = <String>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          if (line.text.trim().isNotEmpty) {
            lines.add(line.text.trim());
          }
        }
      }
      recognizer.close();
      return lines;
    } catch (e) {
      print('Fallback OCR failed: $e');
      return [];
    }
  }

  @override
  Future<OcrResult> processImage(String imagePath) async {
    final lines = await extractTextLines(imagePath);
    final parsed = _parser.parseLines(lines);
    final confidence = _parser.calculateConfidence(parsed);

    return OcrResult(
      lines: lines,
      parsed: parsed,
      confidence: confidence,
    );
  }

  void dispose() {
    _interpreter.close();
  }
}
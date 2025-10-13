import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../models/contact.dart';
import '../parser_service.dart';
import 'ocr_service.dart';

class MlKitOcrService implements OcrService {
  final TextRecognizer _recognizer = TextRecognizer();
  final ParserService _parser = ParserService();

  @override
  Future<List<String>> extractTextLines(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _recognizer.processImage(inputImage);
      
      final lines = <String>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          if (line.text.trim().isNotEmpty) {
            lines.add(line.text.trim());
          }
        }
      }
      
      return lines;
    } catch (e) {
      print('OCR Error: $e');
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
    _recognizer.close();
  }
}

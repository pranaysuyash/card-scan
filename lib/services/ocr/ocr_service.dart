import '../../models/contact.dart';

abstract class OcrService {
  Future<List<String>> extractTextLines(String imagePath);
  Future<OcrResult> processImage(String imagePath);
  void dispose();
}

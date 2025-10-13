class AppConfig {
  static const String appName = 'CardScan';
  static const String version = '1.0.0';
  
  // OCR Settings
  static const double confidenceThresholdHigh = 0.90;
  static const double confidenceThresholdMedium = 0.75;
  static const double confidenceThresholdLow = 0.60;
  
  // Image Processing
  static const int maxImageSize = 1920;
  static const int thumbnailSize = 200;
  static const int imageQuality = 85;
  
  // Database
  static const String dbName = 'card_scan_db';
  
  // Secure Storage Keys
  static const String keyOpenAI = 'openai_api_key';
  static const String keyEncryption = 'db_encryption_key';
}

class AppConstants {
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static final RegExp phoneRegex = RegExp(
    r'[\+]?[(]?[0-9]{1,4}[)]?[-\s\.]?[(]?[0-9]{1,4}[)]?[-\s\.]?[0-9]{1,9}',
  );
  
  static final RegExp urlRegex = RegExp(
    r'(https?:\/\/)?([\w\-]+\.)+[\w]{2,}(\/\S*)?',
  );
}

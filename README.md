# Quantum Card Scanner 🎴✨

A beautiful, robust, and production-ready business card scanner application with advanced OCR, local-first data storage, and modern UI design.

![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B?logo=flutter)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue)

## ✨ Features

### Core Functionality
- 📸 **Advanced Business Card Scanning** - Camera integration with real-time OCR
- 🤖 **AI-Powered OCR** - Google ML Kit with intelligent text recognition
- 🔄 **Multi-Angle Processing** - Automatic rotation detection (0°, 90°, 180°, 270°)
- 💾 **Local-First Storage** - Fast Isar database with offline support
- 🔍 **Smart Search** - Find contacts instantly by name, company, or tags
- 📤 **Export/Import** - vCard (.vcf) and CSV formats
- 🏷️ **Tag Management** - Organize contacts with custom tags

### Security & Privacy
- 🔒 **Biometric Authentication** - Face ID, Touch ID, fingerprint support
- 🛡️ **App Lock** - Secure your contacts with device authentication
- 🔐 **Encrypted Storage** - Secure sensitive data with Flutter Secure Storage
- 🚫 **No Cloud Required** - All data stays on your device
- 🔏 **Privacy-First** - Complete data ownership

### User Experience
- 🎨 **Quantum Theme** - Beautiful glassmorphism design
- ✨ **Smooth Animations** - 60fps interactions and transitions
- 🎵 **Audio Feedback** - Contextual sound effects (optional)
- 📳 **Haptic Feedback** - Tactile responses on supported devices
- 🌙 **Dark Mode** - Eye-friendly interface
- ♿ **Accessibility** - Inclusive design

### Technical Excellence
- ✅ **Comprehensive Testing** - Unit, widget, and integration tests
- 📊 **Error Handling** - Centralized error management and logging
- ✔️ **Input Validation** - Robust validation for all user inputs
- 🚀 **Performance** - Optimized builds with ProGuard/R8
- 📱 **Multi-Platform** - Android, iOS, and Web support
- 🔄 **CI/CD Ready** - GitHub Actions workflows included

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/yourusername/card-scan.git
cd card-scan

# Install dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build

# Run the app
flutter run
```

## 📱 Platforms

- **Android** 7.0+ (API 24+)
- **iOS** 15.5+
- **Web** (Modern browsers)

## 🏗️ Architecture

```
lib/
├── models/           # Data models (Isar entities)
├── providers/        # Riverpod state management
├── services/         # Business logic layer
│   ├── ocr/         # OCR implementations
│   ├── audio_service.dart
│   ├── biometric_auth_service.dart
│   ├── error_handler.dart
│   ├── logger_service.dart
│   ├── storage_service.dart
│   └── validation_service.dart
├── ui/              # User interface
│   ├── screens/     # App screens
│   ├── widgets/     # Reusable widgets
│   └── quantum_theme.dart
└── main.dart        # Entry point
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

## 📦 Building

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 🔧 Configuration

### Android
- Package: `com.quantumtech.cardscanner`
- Min SDK: 24 (Android 7.0)
- Target SDK: Latest
- See `android/key.properties.template` for signing

### iOS
- Bundle ID: `com.quantumtech.cardscanner`
- Deployment Target: iOS 15.5+
- See `ios/SIGNING_SETUP.md` for signing

## 🛠️ Development

```bash
# Format code
dart format .

# Analyze code
flutter analyze

# Update dependencies
flutter pub upgrade

# Code generation
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📚 Documentation

- [Android Setup](docs/ANDROID_SETUP.md)
- [iOS Setup](ios/SIGNING_SETUP.md)
- [Architecture Guide](docs/ARCHITECTURE.md)
- [API Documentation](docs/API.md)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'feat: add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 License

MIT License - see [LICENSE](LICENSE) file

## 🙏 Acknowledgments

- Flutter team
- Google ML Kit
- Isar Database
- Open-source community

---

**Made with ❤️ using Flutter**

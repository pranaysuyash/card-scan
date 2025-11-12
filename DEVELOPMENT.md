# Development Guide

This guide provides detailed information for developers working on Quantum Card Scanner.

## Table of Contents

- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Debugging](#debugging)
- [Performance](#performance)
- [Security](#security)
- [Contributing](#contributing)

## Development Setup

### Prerequisites

- Flutter SDK 3.24+
- Dart SDK 3.2.0+
- Android Studio (for Android development)
- Xcode 15+ (for iOS development, macOS only)
- VS Code or Android Studio with Flutter extensions

### Environment Setup

1. **Install Flutter**
   ```bash
   # Verify installation
   flutter doctor

   # Enable required platforms
   flutter config --enable-web
   flutter config --enable-android
   flutter config --enable-ios  # macOS only
   ```

2. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd card-scan
   flutter pub get
   flutter pub run build_runner build
   ```

3. **IDE Setup**

   **VS Code Extensions:**
   - Flutter
   - Dart
   - Error Lens
   - Flutter Widget Snippets
   - Pubspec Assist

   **Android Studio Plugins:**
   - Flutter
   - Dart
   - Rainbow Brackets

## Project Structure

### Directory Organization

```
lib/
├── models/              # Data models and schemas
│   └── contact.dart    # Contact model with Isar annotations
├── providers/          # Riverpod state providers
│   └── contact_provider.dart
├── services/           # Business logic services
│   ├── ocr/           # OCR-related services
│   │   ├── ocr_service.dart
│   │   └── enhanced_text_recognizer.dart
│   ├── audio_service.dart
│   ├── biometric_auth_service.dart
│   ├── business_card_parser.dart
│   ├── error_handler.dart
│   ├── haptic_service.dart
│   ├── logger_service.dart
│   ├── storage_service.dart
│   ├── validation_service.dart
│   └── vcard_service.dart
├── ui/                # User interface components
│   ├── screens/       # Full-page screens
│   ├── widgets/       # Reusable widgets
│   └── quantum_theme.dart
├── config/            # App configuration
├── main.dart          # Application entry point
└── router.dart        # Navigation configuration

test/
├── models/            # Model tests
├── services/          # Service tests
├── widgets/           # Widget tests
└── widget_test.dart   # Main widget tests
```

## Architecture

### Layered Architecture

```
┌─────────────────────────────────────────┐
│         UI Layer (Screens/Widgets)      │
│  - Quantum screens                      │
│  - Reusable widgets                     │
│  - Theme and styling                    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      State Management (Riverpod)        │
│  - Providers                            │
│  - State notifiers                      │
│  - Provider overrides                   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│        Service Layer                    │
│  - Business logic                       │
│  - OCR processing                       │
│  - Data validation                      │
│  - Authentication                       │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Data Layer (Isar)               │
│  - Local database                       │
│  - Models and schemas                   │
│  - Queries and indexes                  │
└─────────────────────────────────────────┘
```

### Design Patterns

1. **Repository Pattern** - `StorageService` abstracts data access
2. **Provider Pattern** - Riverpod for dependency injection
3. **Service Locator** - Singleton services (ErrorHandler, Logger)
4. **Strategy Pattern** - Different OCR implementations
5. **Factory Pattern** - Error creation (AppErrors)

## Coding Standards

### Dart Style Guide

Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style):

- Use `lowerCamelCase` for variables, functions, parameters
- Use `UpperCamelCase` for classes, enums, typedefs
- Use `lowercase_with_underscores` for file names
- Prefer `final` over `var` when possible
- Use `const` constructors when applicable

### Code Formatting

```bash
# Format all files
dart format .

# Format specific file
dart format lib/main.dart

# Check formatting without applying
dart format --set-exit-if-changed .
```

### Linting

```bash
# Analyze entire project
flutter analyze

# Analyze specific file
flutter analyze lib/main.dart
```

### Documentation

- Add doc comments to all public APIs
- Use `///` for documentation comments
- Include examples in doc comments when helpful

Example:
```dart
/// Validates an email address.
///
/// Returns [ValidationResult.valid] if the email is valid,
/// otherwise returns [ValidationResult.invalid] with an error message.
///
/// Example:
/// ```dart
/// final result = ValidationService.validateEmail('test@example.com');
/// if (result.isValid) {
///   print('Email is valid!');
/// }
/// ```
ValidationResult validateEmail(String? email) {
  // Implementation
}
```

## Testing

### Test Types

1. **Unit Tests** - Test individual functions and classes
2. **Widget Tests** - Test individual widgets
3. **Integration Tests** - Test complete user flows

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/storage_service_test.dart

# Run with coverage
flutter test --coverage

# Run in watch mode (using test_runner)
flutter test --watch
```

### Writing Tests

**Unit Test Example:**
```dart
test('validateEmail returns valid for correct email', () {
  final result = ValidationService.validateEmail('test@example.com');
  expect(result.isValid, isTrue);
});
```

**Widget Test Example:**
```dart
testWidgets('App shows home screen', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();

  expect(find.byType(HomeScreen), findsOneWidget);
});
```

### Test Coverage Goals

- **Services**: 80%+ coverage
- **Models**: 70%+ coverage
- **Widgets**: 60%+ coverage
- **Overall**: 70%+ coverage

## Debugging

### Flutter DevTools

```bash
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Debug Print

```dart
import 'package:card_scan/services/logger_service.dart';

final logger = LoggerService();

logger.debug('Debug message');
logger.info('Info message');
logger.warning('Warning message');
logger.error('Error message', error: e, stackTrace: stackTrace);
```

### Platform-Specific Debugging

**Android:**
```bash
# View logs
adb logcat | grep flutter

# Clear logs
adb logcat -c
```

**iOS:**
```bash
# View logs (with device connected)
idevicesyslog | grep Runner
```

## Performance

### Performance Profiling

```bash
# Run in profile mode
flutter run --profile

# Build performance analysis
flutter build apk --analyze-size
```

### Performance Best Practices

1. **Use `const` widgets** - Reduces rebuilds
2. **Implement `shouldRebuild`** - Control provider updates
3. **Lazy load images** - Use `CachedNetworkImage` or similar
4. **Optimize list rendering** - Use `ListView.builder`
5. **Minimize widget tree depth** - Extract widgets to methods
6. **Profile before optimizing** - Measure actual performance

### Memory Management

```dart
// Dispose resources
@override
void dispose() {
  _controller.dispose();
  _subscription?.cancel();
  super.dispose();
}
```

## Security

### Secure Data Storage

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

// Write
await storage.write(key: 'api_key', value: 'secret');

// Read
final value = await storage.read(key: 'api_key');

// Delete
await storage.delete(key: 'api_key');
```

### Input Validation

Always validate user input:

```dart
import 'package:card_scan/services/validation_service.dart';

final result = ValidationService.validateEmail(email);
if (!result.isValid) {
  // Show error
  ErrorHandler().showErrorSnackBar(context, result.message!);
  return;
}
```

### Security Checklist

- [ ] Validate all user inputs
- [ ] Use HTTPS for network requests
- [ ] Store sensitive data in FlutterSecureStorage
- [ ] Implement biometric authentication for sensitive operations
- [ ] Enable ProGuard/R8 for release builds
- [ ] Don't log sensitive information
- [ ] Keep dependencies up to date

## Contributing

### Workflow

1. **Create branch** from `main`
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes** following coding standards

3. **Write tests** for new functionality

4. **Run checks**
   ```bash
   flutter analyze
   dart format .
   flutter test
   ```

5. **Commit changes**
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

6. **Push and create PR**
   ```bash
   git push origin feature/my-feature
   ```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting
- `refactor:` Code restructuring
- `test:` Adding tests
- `chore:` Maintenance

Examples:
```
feat: add biometric authentication
fix: resolve OCR rotation issue
docs: update README with new features
test: add storage service tests
```

### Code Review

When reviewing PRs, check for:

- [ ] Code follows style guide
- [ ] Tests are included
- [ ] Documentation is updated
- [ ] No unnecessary dependencies added
- [ ] Performance implications considered
- [ ] Security best practices followed

## Troubleshooting

### Common Issues

**Build fails with "Isar schema not found":**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Gradle sync fails:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Pod install fails (iOS):**
```bash
cd ios
rm Podfile.lock
rm -rf Pods
pod install
cd ..
```

**Hot reload not working:**
1. Stop the app
2. Run `flutter clean`
3. Restart the app

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Riverpod Documentation](https://riverpod.dev/)
- [Isar Documentation](https://isar.dev/)
- [Material Design](https://material.io/)

---

**Happy Coding! 🚀**

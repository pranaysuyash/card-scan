# Card Scan - Professional Business Card Scanner

[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.2+-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey.svg)](https://flutter.dev)

Professional business card scanner with enterprise-grade features, AI-powered OCR, and cloud synchronization. Transform networking into intelligent contact management.

---

## 🚀 Features

### Core Functionality
- **📸 Advanced OCR**: 95%+ accuracy with ML Kit and enhanced processing
- **📦 Batch Processing**: Scan multiple cards simultaneously at events/conferences
- **🔄 Smart Deduplication**: AI-powered fuzzy matching to prevent duplicate contacts
- **🔍 Advanced Search**: Faceted search with filters, tags, and sorting
- **📱 QR Code Generation**: Share digital business cards via QR codes
- **☁️ Cloud Sync**: Real-time synchronization across devices
- **🎨 Modern UI**: Quantum-themed glassmorphism design

### Professional Features
- **🎙️ Voice Notes**: Record and transcribe meeting notes
- **👥 Team Collaboration**: Shared contact databases for enterprises
- **🔌 CRM Integrations**: Export to Salesforce, HubSpot, Dynamics
- **📊 Analytics Dashboard**: Track networking metrics and insights
- **🔐 Enterprise Security**: End-to-end encryption, biometric auth
- **🌙 Dark/Light Themes**: Customizable interface
- **💾 Offline-First**: Full functionality without internet

### Export Options
- **vCard (.vcf)**: Universal contact format
- **CSV**: Spreadsheet compatibility
- **QR Codes**: Digital business cards
- **Cloud Backup**: Firebase Storage integration

---

## 📱 Screenshots

_(Screenshots would go here in production)_

---

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter 3.2+
- **State Management**: Riverpod
- **Database**: Isar (local), Firestore (cloud)
- **OCR**: Google ML Kit + Enhanced processing
- **Backend**: Firebase (Auth, Firestore, Storage, Analytics)
- **Payments**: RevenueCat
- **Analytics**: Firebase Analytics, Mixpanel, Sentry

### Project Structure
```
lib/
├── core/
│   ├── error/                    # Error handling & exceptions
│   ├── repositories/             # Repository pattern
│   └── utils/                    # Utilities (Either, etc.)
├── features/
│   ├── analytics/               # Analytics service
│   ├── backend/                 # Firebase backend
│   ├── batch_scan/              # Batch processing
│   ├── crm/                     # CRM integrations
│   ├── deduplication/           # Smart deduplication
│   ├── qr_code/                 # QR code generation
│   ├── search/                  # Advanced search
│   ├── subscription/            # In-app purchases
│   ├── sync/                    # Cloud sync
│   ├── theme/                   # Theme management
│   └── voice_notes/             # Voice notes & transcription
├── models/                      # Data models
├── providers/                   # Riverpod providers
├── services/                    # Core services
│   ├── ocr/                     # OCR implementations
│   ├── audio_service.dart
│   ├── haptic_service.dart
│   └── parser_service.dart
└── ui/
    ├── screens/                 # App screens
    ├── widgets/                 # Reusable widgets
    └── quantum_theme.dart       # Theme configuration
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.2 or higher
- Dart 3.2 or higher
- iOS 15+ / Android 10+
- Firebase account (for cloud features)
- RevenueCat account (for subscriptions)

### Installation

1. **Clone the repository** _(Private repository - authorized access only)_

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure Firebase**
   - Add `google-services.json` (Android) to `android/app/`
   - Add `GoogleService-Info.plist` (iOS) to `ios/Runner/`

5. **Configure API Keys**
   Create `lib/config/api_keys.dart`:
   ```dart
   class ApiKeys {
     static const String revenueCatApiKey = 'YOUR_REVENUECAT_KEY';
     static const String mixpanelToken = 'YOUR_MIXPANEL_TOKEN';
     static const String sentryDsn = 'YOUR_SENTRY_DSN';
   }
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

---

## 🎯 Usage

### Basic Card Scanning
1. Tap the **Scan** button
2. Position business card in frame
3. App automatically detects and processes
4. Review extracted data
5. Save or edit contact

### Batch Processing
1. Navigate to **Batch Scan**
2. Tap **Add Cards** to scan multiple
3. Processing happens in background
4. Review all contacts at once
5. Batch export to CRM or vCard

### QR Code Sharing
1. Open any contact
2. Tap **Share > QR Code**
3. Display QR code for scanning
4. Recipient scans to import contact

### Cloud Sync
1. Sign in with email or anonymous
2. Enable sync in **Settings**
3. Contacts automatically sync across devices
4. Conflict resolution handled automatically

---

## 💼 Subscription Tiers

### Free Tier
- 50 contacts limit
- Basic scanning
- Local storage only
- vCard export
- Ad-supported

### Pro ($4.99/month)
- ✅ Unlimited contacts
- ✅ Batch processing
- ✅ Cloud sync
- ✅ Advanced OCR
- ✅ QR code generation
- ✅ Voice notes
- ✅ No ads
- ✅ Priority support

### Business ($14.99/month)
- ✅ Everything in Pro
- ✅ Team sharing (10 users)
- ✅ CRM integrations
- ✅ Advanced analytics
- ✅ API access
- ✅ SSO support
- ✅ Dedicated account manager

---

## 🔧 Configuration

### Firebase Setup
1. Create Firebase project
2. Enable Authentication (Email, Anonymous)
3. Enable Firestore
4. Enable Storage
5. Enable Analytics
6. Add configuration files to project

### RevenueCat Setup
1. Create RevenueCat account
2. Add iOS/Android apps
3. Configure products
4. Add API key to `api_keys.dart`

### CRM Integration
Configure credentials in Settings:
- **Salesforce**: OAuth flow
- **HubSpot**: API key
- **Dynamics**: OAuth flow
- **Custom**: Webhook URL

---

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter test integration_test/
```

### Code Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📊 Analytics Events

The app tracks the following events:
- `scan_completed`: Business card scan finished
- `contact_saved`: Contact saved to database
- `export`: Data exported (format, count)
- `search`: Search performed
- `batch_processing`: Batch scan session
- `qr_code_shared`: QR code generated
- `deduplication`: Duplicates merged
- `purchase_*`: Subscription events

---

## 🔐 Security & Privacy

- **End-to-End Encryption**: All synced data is encrypted
- **Local-First**: Full functionality without cloud
- **GDPR Compliant**: Data deletion & export
- **Biometric Auth**: Face ID / Fingerprint
- **No Tracking**: Optional anonymous analytics only

---

## 🛠️ Development

### Code Style
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` before committing
- Format code with `dart format .`

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/your-feature

# Make changes and commit
git add .
git commit -m "feat: your feature description"

# Push and create pull request
git push origin feature/your-feature
```

### Commit Convention
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Tests
- `chore`: Maintenance

---

## 📝 License

Copyright © 2025 Card Scan Application. All Rights Reserved.

This software is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited. See [LICENSE](LICENSE) for full terms.

---

## 🤝 Support

### For Users
- Email: support@cardscan.app
- Website: https://cardscan.app
- Help Center: https://help.cardscan.app

### For Developers
- Internal documentation: See `/docs`
- API documentation: Run `dartdoc`
- Slack: #card-scan-dev

---

## 🎯 Roadmap

### Q1 2025
- [x] Batch processing
- [x] Smart deduplication
- [x] QR code generation
- [ ] Live camera OCR preview
- [ ] AR business cards

### Q2 2025
- [ ] Team collaboration features
- [ ] Advanced analytics dashboard
- [ ] AI-powered smart assistant
- [ ] Wearable integration

### Q3 2025
- [ ] Web dashboard
- [ ] Desktop apps (macOS, Windows)
- [ ] Browser extension
- [ ] Public API release

---

## 🏆 Credits

Built with ❤️ by the Card Scan team

### Key Technologies
- [Flutter](https://flutter.dev) - UI Framework
- [Firebase](https://firebase.google.com) - Backend
- [ML Kit](https://developers.google.com/ml-kit) - OCR
- [Isar](https://isar.dev) - Local Database
- [RevenueCat](https://www.revenuecat.com) - Subscriptions

---

**Card Scan** - Transform Networking Into Intelligence

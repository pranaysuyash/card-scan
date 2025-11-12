# iOS Signing and Deployment Setup

This guide explains how to configure iOS app signing and prepare for App Store deployment.

## Bundle Identifier

The app uses the bundle identifier: `com.quantumtech.cardscanner`

To change this:
1. Open `ios/Runner.xcodeproj` in Xcode
2. Select the Runner target
3. Go to Signing & Capabilities
4. Update the Bundle Identifier field

## Development Signing

For development and testing:

1. Open the project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select your development team:
   - Select the Runner target
   - Go to "Signing & Capabilities"
   - Check "Automatically manage signing"
   - Select your team from the dropdown

3. Connect your iOS device and run:
   ```bash
   flutter run --release
   ```

## Production Signing (App Store)

### Prerequisites

1. **Apple Developer Account** ($99/year)
   - Enroll at: https://developer.apple.com/programs/

2. **Certificates and Profiles**
   - Create an App Store Distribution certificate
   - Create an App Store Provisioning Profile
   - Add devices for TestFlight testing

### Setup Steps

1. **Create App ID in Apple Developer Portal**
   - Go to Certificates, Identifiers & Profiles
   - Create a new App ID with bundle identifier: `com.quantumtech.cardscanner`
   - Enable capabilities: Push Notifications, App Groups (if needed)

2. **Create Distribution Certificate**
   - In Keychain Access, generate a Certificate Signing Request (CSR)
   - Upload CSR to Apple Developer Portal
   - Download and install the distribution certificate

3. **Create Provisioning Profile**
   - Create an App Store Distribution provisioning profile
   - Link it to your App ID and distribution certificate
   - Download and install the profile

4. **Configure Xcode**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Uncheck "Automatically manage signing"
   - Select your Team
   - Choose your provisioning profile for Release configuration

## Building for Release

### Archive the App

1. In Xcode:
   - Product → Scheme → Edit Scheme
   - Select "Release" for Run
   - Product → Archive

2. Or via command line:
   ```bash
   flutter build ios --release
   ```

### Upload to App Store Connect

1. After archiving, Xcode Organizer will open
2. Select your archive
3. Click "Distribute App"
4. Choose "App Store Connect"
5. Follow the wizard to upload

### TestFlight

1. Go to App Store Connect
2. Select your app
3. Go to TestFlight tab
4. Add internal/external testers
5. Submit for Beta App Review (for external testing)

## Troubleshooting

### "Provisioning profile doesn't match"
- Ensure bundle identifier matches exactly
- Regenerate provisioning profile if needed
- Clean Xcode build folder: Shift+Cmd+K

### "Code signing error"
- Check that certificate is installed in Keychain
- Verify provisioning profile is downloaded
- Try revoking and creating new certificates

### "Build fails on real device"
- Check deployment target matches your device iOS version
- Ensure device is registered in Developer Portal
- Verify provisioning profile includes your device

## App Store Submission Checklist

- [ ] App icon (all required sizes)
- [ ] Launch screen
- [ ] Screenshots (all required device sizes)
- [ ] App description
- [ ] Keywords
- [ ] Support URL
- [ ] Privacy policy URL
- [ ] App category
- [ ] Age rating questionnaire
- [ ] Export compliance information

## Resources

- [Apple Developer Portal](https://developer.apple.com/)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [Flutter iOS Deployment Guide](https://docs.flutter.dev/deployment/ios)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

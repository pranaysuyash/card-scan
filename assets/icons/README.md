# Icon Assets

This directory is reserved for custom icon assets used throughout the app.

## App Icons

The app currently uses Material Icons from Flutter's built-in icon set.
Custom icons can be added here if needed for:

- Splash screen logo
- Custom action icons
- Brand-specific imagery
- Tutorial/onboarding illustrations

## Formats

- PNG for raster icons (provide @2x and @3x variants for different screen densities)
- SVG for vector icons (can be rendered at any size)

## Organization

Consider organizing icons by category:
- `/icons/social/` - Social media platform icons
- `/icons/actions/` - Custom action icons
- `/icons/brand/` - Brand and logo assets
- `/icons/tutorial/` - Onboarding and tutorial graphics

## App Icon Configuration

Platform-specific app icons are configured in:
- Android: `android/app/src/main/res/mipmap-*/`
- iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Web: `web/icons/`

Use Flutter launcher icons package to generate all sizes:
```bash
flutter pub add flutter_launcher_icons --dev
```

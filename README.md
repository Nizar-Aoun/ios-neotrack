# taxi_driver_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# neos-track-mobile

## Android signing notes

- `dev` flavor release builds (for example, `flutter build apk --flavor dev`) may fall back to the debug keystore when `android/key.properties` is not present.
- `prod` flavor release builds (APK/AAB for Play Console) always use release signing and require `android/key.properties`.
- Build Play artifact with release signing: `flutter build appbundle --flavor prod`.

# WalkTracker Lite

A minimal Flutter GPS walk tracker with live map and session history.

## Features

- GPS tracking with accuracy filtering and distance accumulation
- Live map (OpenStreetMap) with route polyline
- Start / Pause / Resume / Stop controls
- Distance and elapsed time display
- Session history with persistence (sqflite)

## Setup

1. Ensure Flutter is installed and in your PATH
2. From this directory, run: `flutter pub get`
3. If the project was created manually, run `flutter create .` to generate platform files (Android/iOS)
4. Run on device: `flutter run`

## Permissions

- **Android**: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`
- **iOS**: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`

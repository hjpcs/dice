# Dice

A simple Flutter Dice Roller application.

## Prerequisites

This project requires Flutter and Android SDK/Xcode.

The environment has been set up with the following components:
- Flutter SDK (via Homebrew)
- Android Command Line Tools (via Homebrew)
- OpenJDK (Java)
- CocoaPods

## Setup Environment

Before running the application, you need to set up the environment variables.
A script `setup_env.sh` is provided in the project root.

Run the following command in your terminal:

```bash
source setup_env.sh
```

## Running the App

To run the application, verify your connected devices:

```bash
flutter devices
```

Then run the app:

```bash
flutter run
```

If you don't have a physical device connected, you can run it on a simulator/emulator or Chrome (web).

To run on Chrome:

```bash
flutter run -d chrome
```

## Building for Android

To build an APK:

```bash
flutter build apk
```

## Building for iOS

To build for iOS (requires Xcode):

```bash
flutter build ios
```

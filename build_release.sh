#!/bin/bash

# Set environment variables for Android build
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export ANDROID_HOME="/opt/homebrew/share/android-commandlinetools"

# Run flutter build
flutter build apk --release --split-per-abi

echo "Build complete! APKs are located in build/app/outputs/flutter-apk/"

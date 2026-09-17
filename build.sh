#!/bin/bash
set -e

echo "=== Starting Flutter Web Build for Vercel ==="

# Check if Flutter SDK is available
if ! command -v flutter &> /dev/null
then
    echo "Flutter not found in PATH. Installing Flutter SDK..."
    if [ ! -d "flutter" ]; then
        git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
    fi
    export PATH="$PATH:$(pwd)/flutter/bin"
fi

echo "Flutter version:"
flutter --version

echo "Enabling Flutter Web..."
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

echo "Building Flutter Web release..."
flutter build web --release

echo "=== Flutter Web Build Complete ==="

#!/bin/bash
set -e

echo "=== Starting Flutter Web Build for Vercel ==="

# Configure git safe directory for CI
git config --global --add safe.directory "*" || true

# Check if Flutter SDK is available
if ! command -v flutter &> /dev/null
then
    echo "Flutter not found in PATH. Installing Flutter SDK..."
    if [ ! -d "flutter" ]; then
        git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
    fi
    export PATH="$(pwd)/flutter/bin:$PATH"
fi

echo "Flutter version:"
flutter --version || true

echo "Enabling Flutter Web..."
flutter config --enable-web || true

echo "Getting dependencies..."
flutter pub get || true

echo "Building Flutter Web release..."
flutter build web --release || {
    if [ -d "build/web" ] && [ -f "build/web/index.html" ]; then
        echo "Using pre-built web bundle from repository."
    else
        exit 1
    fi
}

echo "=== Flutter Web Build Complete ==="


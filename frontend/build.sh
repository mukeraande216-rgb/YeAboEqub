#!/bin/bash
# Install Flutter
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Build Web
flutter build web --release
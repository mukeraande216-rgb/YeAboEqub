#!/bin/bash

# 1. Install Flutter (Stable version)
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# 2. Upgrade and verify
flutter doctor

# 3. Build the web project
flutter build web --release
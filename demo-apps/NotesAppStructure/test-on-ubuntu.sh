#!/bin/bash

echo "Testing $APP_NAME structure on Ubuntu..."
echo ""

# Test if Swift is available
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found. Install Swift: https://www.swift.org/install/"
    exit 1
fi

echo "✅ Swift is available"
echo "Swift version:"
swift --version
echo ""

# Try to build the package
echo "Building package..."
if swift build; then
    echo "✅ Package builds successfully"
else
    echo "⚠️  Build failed (expected for iOS app structure on Ubuntu)"
fi
echo ""

# List all files
echo "Structure created:"
find . -type f -name "*.swift" | sort
echo ""
echo "✅ Structure created successfully!"
echo ""
echo "Next steps:"
echo "1. Add more Swift files to the appropriate folders"
echo "2. Transfer this folder to macOS"
echo "3. Follow instructions in README-macOS-Setup.md"

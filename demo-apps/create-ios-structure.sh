#!/bin/bash

# create-ios-structure.sh
# Creates a minimal iOS app structure for transfer to macOS/Xcode

if [ -z "$1" ]; then
    echo "Usage: $0 <AppName>"
    echo "Example: $0 NotesApp"
    exit 1
fi

APP_NAME="$1"
PACKAGE_NAME="${APP_NAME// /}"  # Remove spaces
DIR_NAME="${PACKAGE_NAME}Structure"

echo "Creating iOS app structure for: $APP_NAME"
echo "Package name: $PACKAGE_NAME"
echo ""

# Create directory structure
mkdir -p "$DIR_NAME"
cd "$DIR_NAME"

# Create main directories
mkdir -p Sources/$PACKAGE_NAME/Models
mkdir -p Sources/$PACKAGE_NAME/Views
mkdir -p Sources/$PACKAGE_NAME/ViewModels
mkdir -p Sources/$PACKAGE_NAME/Services
mkdir -p Resources
mkdir -p Tests/$PACKAGE_NAME
mkdir -p Documentation

# Create Package.swift with minimal configuration
cat > Package.swift << EOF
// swift-tools-version:5.7
// Package.swift - Minimal configuration for iOS app structure
// This file helps organize code on Ubuntu. On macOS, create an Xcode project.

import PackageDescription

let package = Package(
    name: "$PACKAGE_NAME",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "$PACKAGE_NAME",
            targets: ["$PACKAGE_NAME"]
        )
    ],
    targets: [
        .target(
            name: "$PACKAGE_NAME",
            path: "Sources/$PACKAGE_NAME",
            resources: [
                .copy("../Resources")
            ]
        ),
        .testTarget(
            name: "${PACKAGE_NAME}Tests",
            dependencies: ["$PACKAGE_NAME"],
            path: "Tests/$PACKAGE_NAME"
        )
    ]
)
EOF

# Create a sample model file
cat > Sources/$PACKAGE_NAME/Models/SampleModel.swift << EOF
import Foundation

public struct $PACKAGE_NAME {
    public static let name = "$APP_NAME"
    
    public static func hello() -> String {
        return "Hello from $APP_NAME!"
    }
}
EOF

# Create a sample view file
cat > Sources/$PACKAGE_NAME/Views/ContentView.swift << EOF
// ContentView.swift
// Copy this file into your Xcode iOS project

import SwiftUI

public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("$APP_NAME")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Welcome to your app!")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Created on Ubuntu")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
EOF

# Create a simple test file
cat > Tests/$PACKAGE_NAME/${PACKAGE_NAME}Tests.swift << EOF
import XCTest
@testable import $PACKAGE_NAME

final class ${PACKAGE_NAME}Tests: XCTestCase {
    func testExample() throws {
        XCTAssertEqual($PACKAGE_NAME.name, "$APP_NAME")
        XCTAssertEqual($PACKAGE_NAME.hello(), "Hello from $APP_NAME!")
    }
}
EOF

# Create a README file with macOS setup instructions
cat > README-macOS-Setup.md << EOF
# $APP_NAME - macOS Setup Instructions

## Files Created:
- \`Package.swift\` - Swift package configuration (for organization only)
- \`Sources/$PACKAGE_NAME/\` - Your Swift source code
- \`Resources/\` - Placeholder for resources (images, strings, etc.)

## How to Use on macOS:

### Option 1: Create New Xcode Project
1. Open Xcode on your Mac
2. Create a new project: \`File → New → Project\`
3. Choose "App" under iOS tab
4. Fill in:
   - Product Name: \`$APP_NAME\`
   - Interface: SwiftUI
   - Language: Swift
   - Save location: Anywhere on your Mac
5. After creating the project:
   - Delete the default \`ContentView.swift\` from Xcode
   - Copy all files from \`Sources/$PACKAGE_NAME/\` to your Xcode project
   - If you have resources, copy \`Resources/\` to Xcode
   - Build and run!

### Option 2: Use as Swift Package
1. On macOS, create a new Xcode iOS project
2. Go to \`File → Add Packages... → Add Local...\`
3. Navigate to this folder and select it
4. Import \`$PACKAGE_NAME\` in your Swift files

## Folder Structure:
\`\`\`
$DIR_NAME/
├── Package.swift                    # Swift package configuration
├── Sources/$PACKAGE_NAME/          # Your Swift source files
│   ├── Models/                     # Data models
│   ├── Views/                      # SwiftUI views
│   ├── ViewModels/                 # View models (if using MVVM)
│   └── Services/                   # Business logic
├── Resources/                      # Images, assets, strings
├── Tests/$PACKAGE_NAME/           # Unit tests
└── Documentation/                  # Documentation
\`\`\`

## What to Do Next:
1. Add more Swift files in the appropriate folders
2. Add images to \`Resources/\` folder
3. Test your business logic on Ubuntu using \`swift test\`
4. Transfer the entire folder to macOS
5. Follow the setup instructions above
EOF

# Create a bash script for quick testing on Ubuntu
cat > test-on-ubuntu.sh << 'EOF'
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
EOF

chmod +x test-on-ubuntu.sh

# Create a simple gitignore
cat > .gitignore << EOF
# Build artifacts
.build/
*.xcodeproj/
*.xcworkspace/
DerivedData/
*.swiftpm/

# macOS
.DS_Store

# Xcode
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
xcuserdata/

# Swift Package Manager
Packages/
Package.resolved
.swiftpm/
EOF

# Create a simple git setup script
cat > setup-git.sh << 'EOF'
#!/bin/bash
echo "Setting up Git repository..."
git init
git add .
git commit -m "Initial commit: $APP_NAME iOS app structure"
echo ""
echo "✅ Git repository initialized"
echo "Run: git remote add origin <your-repo-url>"
echo "Then: git push -u origin main"
EOF

chmod +x setup-git.sh

echo "✅ Structure created in: $DIR_NAME/"
echo ""
echo "�� Directory structure:"
tree -I '.git|.build' --dirsfirst
echo ""
echo "📋 Quick commands:"
echo "   cd $DIR_NAME"
echo "   ./test-on-ubuntu.sh     # Test on Ubuntu"
echo "   ./setup-git.sh          # Initialize Git repo"
echo ""
echo "📖 Setup instructions saved in: README-macOS-Setup.md"
echo ""
echo "🚀 To use on macOS:"
echo "   1. Transfer the '$DIR_NAME' folder to your Mac"
echo "   2. Create a new iOS project in Xcode"
echo "   3. Copy the Swift files from Sources/$PACKAGE_NAME/"
echo "   4. Build and run!"

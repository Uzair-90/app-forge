#!/bin/bash

# setup-ios-from-ubuntu.sh
# macOS script to convert Ubuntu Swift structure to Xcode project

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Homebrew package
install_brew_package() {
    local package=$1
    if ! command_exists "$package"; then
        print_warning "$package not found. Installing via Homebrew..."
        if command_exists brew; then
            brew install "$package"
            print_status "$package installed successfully"
        else
            print_error "Homebrew not found. Please install Homebrew first:"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    fi
}

# Function to extract app name from archive
extract_app_name() {
    local zip_file="$1"
    local filename=$(basename "$zip_file")
    
    # Remove extensions in sequence
    local name="${filename%.zip}"
    name="${name%.tar.gz}"
    name="${name%.tgz}"
    name="${name%.tar}"
    
    echo "$name"
}

# Function to find actual source directory
find_source_directory() {
    local dir="$1"
    
    # Common Swift source directories
    local possible_dirs=("Sources" "src" "Source" "app" "App" "Sources/$app_name")
    
    for possible_dir in "${possible_dirs[@]}"; do
        if [ -d "$dir/$possible_dir" ]; then
            echo "$possible_dir"
            return 0
        fi
    done
    
    # If no standard directory, look for Swift files
    local swift_dir=$(find "$dir" -type f -name "*.swift" -exec dirname {} \; | head -1 | xargs basename 2>/dev/null || echo "")
    
    if [ -n "$swift_dir" ] && [ -d "$dir/$swift_dir" ]; then
        echo "$swift_dir"
        return 0
    fi
    
    # Last resort: use the directory itself
    echo "."
}

# Function to generate project.yml for XcodeGen
generate_project_yml() {
    local app_name="$1"
    local source_dir="$2"
    
    print_info "Using source directory: $source_dir"
    
    cat > project.yml << EOF
name: $app_name
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "16.0"
  xcodeVersion: "15.0"
targets:
  $app_name:
    type: application
    platform: iOS
    deploymentTarget: "16.0"
    sources:
      - path: $source_dir
    info:
      path: Info.plist
      properties:
        CFBundleName: $app_name
        CFBundleDisplayName: $app_name
        CFBundleIdentifier: com.example.$app_name
        CFBundleShortVersionString: "1.0"
        CFBundleVersion: "1"
        LSRequiresIPhoneOS: true
        UILaunchStoryboardName: LaunchScreen
        UIRequiredDeviceCapabilities: [armv7]
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
    settings:
      base:
        PRODUCT_NAME: $app_name
        PRODUCT_BUNDLE_IDENTIFIER: com.example.$app_name
        TARGETED_DEVICE_FAMILY: "1,2"
        DEVELOPMENT_TEAM: ""
    preBuildScripts:
      - name: Create Info.plist if missing
        script: |
          if [ ! -f "\$SRCROOT/Info.plist" ]; then
            cat > "\$SRCROOT/Info.plist" << 'EOF2'
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>CFBundleDevelopmentRegion</key>
              <string>\$(DEVELOPMENT_LANGUAGE)</string>
              <key>CFBundleExecutable</key>
              <string>\$(EXECUTABLE_NAME)</string>
              <key>CFBundleIdentifier</key>
              <string>com.example.$app_name</string>
              <key>CFBundleInfoDictionaryVersion</key>
              <string>6.0</string>
              <key>CFBundleName</key>
              <string>$app_name</string>
              <key>CFBundlePackageType</key>
              <string>APPL</string>
              <key>CFBundleShortVersionString</key>
              <string>1.0</string>
              <key>CFBundleVersion</key>
              <string>1</string>
              <key>LSRequiresIPhoneOS</key>
              <true/>
              <key>UILaunchStoryboardName</key>
              <string>LaunchScreen</string>
              <key>UIRequiredDeviceCapabilities</key>
              <array>
                  <string>armv7</string>
              </array>
              <key>UISupportedInterfaceOrientations</key>
              <array>
                  <string>UIInterfaceOrientationPortrait</string>
                  <string>UIInterfaceOrientationLandscapeLeft</string>
                  <string>UIInterfaceOrientationLandscapeRight</string>
              </array>
          </dict>
          </plist>
          EOF2
          fi
EOF
    
    print_status "Created project.yml configuration"
}

# Function to create manual project if XcodeGen fails
create_manual_project() {
    local app_name="$1"
    
    print_info "Creating manual project structure..."
    
    # Create a simple Info.plist
    cat > Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>\$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>\$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$app_name</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$app_name</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF
    
    # Create setup instructions
    cat > SETUP_INSTRUCTIONS.md << EOF
# Manual Xcode Project Setup

## Option 1: Create New Xcode Project
1. Open Xcode
2. File → New → Project
3. Choose "App" under iOS
4. Configure:
   - Product Name: $app_name
   - Team: (Select your team)
   - Organization Identifier: com.example
   - Interface: SwiftUI
   - Language: Swift
5. Save it in this folder
6. Add your Swift files:
   - Drag and drop your .swift files into the Xcode project
   - Make sure "Copy items if needed" is checked
   - Add to your app target
7. Build and run

## Option 2: Open Swift Package in Xcode
1. If you have a Package.swift file, double-click it
2. Xcode will open it as a Swift Package
3. File → New → Target
4. Add an iOS App target
5. Add your source files to the target

## Current Swift files:
\`\`\`
$(find . -type f -name "*.swift" | head -20)
\`\`\`
EOF
    
    print_status "Created manual setup instructions"
}

# Function to create final setup script
create_setup_script() {
    local app_name="$1"
    
    cat > quick-start.sh << 'EOF'
#!/bin/bash

# Quick Start Script for iOS Project

echo "📱 iOS Project - Quick Start"
echo "==========================="

APP_NAME="APP_NAME_PLACEHOLDER"
PROJECT_DIR=$(pwd)

echo "Project: $APP_NAME"
echo "Location: $PROJECT_DIR"
echo ""

# Open Xcode project if it exists
if [ -d "$APP_NAME.xcodeproj" ]; then
    echo "Opening Xcode project..."
    open "$APP_NAME.xcodeproj"
elif [ -f "Package.swift" ]; then
    echo "Opening Swift Package in Xcode..."
    open Package.swift
else
    echo "No Xcode project found. Please follow SETUP_INSTRUCTIONS.md"
    echo ""
    echo "To create project with xcodegen:"
    echo "  xcodegen generate"
    echo "Then: open $APP_NAME.xcodeproj"
fi

echo ""
echo "If you need to select a team:"
echo "1. Select project in Xcode"
echo "2. Select '$APP_NAME' target"
echo "3. Go to 'Signing & Capabilities'"
echo "4. Select your team"
echo ""
echo "To run: Select simulator and click ▶️"
EOF
    
    # Insert app name into the script
    sed -i "" "s/APP_NAME_PLACEHOLDER/$app_name/g" quick-start.sh
    chmod +x quick-start.sh
    
    print_status "Created quick-start script"
}

# Main setup function
setup_xcode_project() {
    local zip_file="$1"
    
    print_info "iOS Project Setup from Ubuntu Transfer"
    echo "=========================================="
    
    # Check if zip file exists
    if [ ! -f "$zip_file" ]; then
        print_error "Zip file not found: $zip_file"
        echo "Usage: $0 <path-to-zip-file>"
        exit 1
    fi
    
    # Get absolute path of zip file
    local zip_full_path=$(cd "$(dirname "$zip_file")" && pwd)/$(basename "$zip_file")
    
    # Extract app name from zip file
    local app_name=$(extract_app_name "$zip_file")
    
    print_info "Setting up: $app_name"
    
    # Check for required tools
    print_info "Checking required tools..."
    
    # Install/check XcodeGen
    install_brew_package "xcodegen"
    
    # Check for unzip/tar
    if ! command_exists unzip && ! command_exists tar; then
        print_error "Neither unzip nor tar found. Installing..."
        brew install gnu-tar
    fi
    
    # Create a clean working directory
    local work_dir="$HOME/Desktop/iOS_Projects/$app_name"
    
    # Remove if exists and create fresh
    rm -rf "$work_dir"
    mkdir -p "$work_dir"
    
    # Copy zip file to working directory
    cp "$zip_full_path" "$work_dir/"
    cd "$work_dir"
    
    local local_zip_file=$(basename "$zip_full_path")
    
    print_status "Working directory: $work_dir"
    
    # Extract the zip file
    print_info "Extracting files..."
    if [[ "$local_zip_file" == *.zip ]]; then
        if command_exists unzip; then
            unzip -q "$local_zip_file"
        else
            print_error "unzip not available"
            exit 1
        fi
    elif [[ "$local_zip_file" == *.tar.gz ]] || [[ "$local_zip_file" == *.tgz ]]; then
        tar -xzf "$local_zip_file"
    elif [[ "$local_zip_file" == *.tar ]]; then
        tar -xf "$local_zip_file"
    else
        print_error "Unsupported archive format. Use .zip, .tar.gz, .tgz, or .tar"
        exit 1
    fi
    
    # Remove the copied zip file
    rm -f "$local_zip_file"
    
    # Find the extracted folder
    local extracted_dir="."
    local first_dir=$(find . -maxdepth 1 -type d ! -name "." ! -name "__MACOSX" | head -n1)
    if [ -n "$first_dir" ]; then
        extracted_dir="$first_dir"
        cd "$extracted_dir"
    fi
    
    print_status "Extracted to: $(pwd)"
    
    # Check for Package.swift and read app name from it
    if [ -f "Package.swift" ]; then
        local package_name=$(grep -E '^\s*name\s*:' Package.swift | head -1 | sed 's/.*"\(.*\)".*/\1/' | tr -d '[:space:]' || \
                            grep -E 'name:\s*"' Package.swift | head -1 | sed 's/.*"\(.*\)".*/\1/' | tr -d '[:space:]')
        if [ -n "$package_name" ] && [ "$package_name" != "$app_name" ]; then
            app_name="$package_name"
            print_status "Found Swift package name: $app_name"
        fi
    fi
    
    # Find source directory
    local source_dir=$(find_source_directory ".")
    print_info "Source directory: $source_dir"
    
    # Generate project.yml for XcodeGen
    print_info "Generating Xcode project configuration..."
    generate_project_yml "$app_name" "$source_dir"
    
    # Generate Xcode project
    print_info "Generating Xcode project..."
    if xcodegen generate; then
        print_status "Xcode project generated successfully!"
        
        # Create Info.plist if it doesn't exist
        if [ ! -f "Info.plist" ]; then
            print_info "Creating Info.plist..."
            cat > Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>\$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>\$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.$app_name</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$app_name</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
</dict>
</plist>
EOF
        fi
    else
        print_error "Failed to generate Xcode project"
        print_info "Creating manual setup..."
        create_manual_project "$app_name"
    fi
    
    # Create setup script for the generated project
    create_setup_script "$app_name"
    
    # Show project structure
    print_info "Project structure:"
    find . -type f -name "*.swift" | head -10 | while read file; do
        echo "  📄 $file"
    done
    
    # Open the project if Xcode is available
    if command_exists xed && [ -d "$app_name.xcodeproj" ]; then
        print_info "Opening project in Xcode..."
        xed .
    elif [ -d "$app_name.xcodeproj" ]; then
        print_info "To open project in Xcode:"
        echo "  open $app_name.xcodeproj"
    elif [ -f "Package.swift" ]; then
        print_info "To open Swift Package in Xcode:"
        echo "  open Package.swift"
    fi
    
    print_status "Setup complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Run: ./quick-start.sh"
    echo "  2. Select a simulator (iPhone 15, etc.)"
    echo "  3. Click the Run button (▶️)"
    echo ""
    print_info "Project location: $(pwd)"
}

# Function to clean up and show summary
show_summary() {
    echo ""
    print_info "📋 PROJECT SUMMARY"
    echo "=================="
    echo "App Name:    $app_name"
    echo "Location:    $(pwd)"
    echo ""
    echo "Swift files found:"
    find . -type f -name "*.swift" | head -5 | while read file; do
        echo "  • $(basename "$file")"
    done
    local total_swift=$(find . -type f -name "*.swift" | wc -l)
    echo "  Total: $total_swift Swift files"
    echo ""
    echo "To run: ./quick-start.sh"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS"
    exit 1
fi

# Check for Xcode
if ! xcode-select -p &>/dev/null; then
    print_error "Xcode command line tools not installed"
    echo "Please run: xcode-select --install"
    exit 1
fi

# Run the setup
if [ $# -eq 0 ]; then
    # If no arguments, look for zip files in Downloads
    zip_file=$(find ~/Downloads -maxdepth 1 \( -name "*.zip" -o -name "*.tar.gz" -o -name "*.tgz" -o -name "*.tar" \) | head -1)
    if [ -n "$zip_file" ]; then
        print_info "Found archive file: $zip_file"
        read -p "Use this file? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            setup_xcode_project "$zip_file"
            show_summary
        else
            print_error "Please provide archive file path:"
            echo "  $0 <path-to-archive>"
            exit 1
        fi
    else
        print_error "No archive file provided and none found in Downloads"
        echo "Usage: $0 <path-to-archive-file>"
        echo "Example: $0 ~/Downloads/MyApp.zip"
        echo "Supported formats: .zip, .tar.gz, .tgz, .tar"
        exit 1
    fi
else
    setup_xcode_project "$1"
    show_summary
fi

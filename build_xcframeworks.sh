#!/bin/bash

# Create a directory for the output
OUTPUT_DIR="./xcframeworks"
mkdir -p "$OUTPUT_DIR"

# Function to build a single framework
build_framework() {
    local scheme=$1
    
    echo "Building $scheme..."
    
    # Build for iOS
    xcodebuild archive \
      -scheme "$scheme" \
      -destination "generic/platform=iOS" \
      -archivePath "./build/$scheme-ios.xcarchive" \
      SKIP_INSTALL=NO \
      BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    
    # Build for iOS Simulator
    xcodebuild archive \
      -scheme "$scheme" \
      -destination "generic/platform=iOS Simulator" \
      -archivePath "./build/$scheme-iossimulator.xcarchive" \
      SKIP_INSTALL=NO \
      BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    
    # Create XCFramework
    xcodebuild -create-xcframework \
      -framework "./build/$scheme-ios.xcarchive/Products/Library/Frameworks/$scheme.framework" \
      -framework "./build/$scheme-iossimulator.xcarchive/Products/Library/Frameworks/$scheme.framework" \
      -output "$OUTPUT_DIR/$scheme.xcframework"
    
    echo "✅ Finished building $scheme"
}

# Start all builds in parallel
build_framework "SwiftCompilerPlugin" &
build_framework "SwiftSyntaxBuilder" &
build_framework "SwiftSyntaxMacros" &

# Wait for all background processes to complete
wait

echo "All XCFrameworks have been created in $OUTPUT_DIR"

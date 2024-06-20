#!/bin/bash

xcodebuild archive \
-workspace MLTranslate.xcworkspace -scheme MLTranslate  \
-configuration Release \
-destination 'generic/platform=iOS Simulator' \
-archivePath './build/MLTranslate.framework-iphonesimulator.xcarchive' \
SKIP_INSTALL=NO \
BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

xcodebuild archive \
-workspace MLTranslate.xcworkspace -scheme MLTranslate  \
-configuration Release \
-destination 'generic/platform=iOS' \
-archivePath './build/MLTranslate.framework-iphoneos.xcarchive' \
SKIP_INSTALL=NO \
BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

xcodebuild -create-xcframework \
-framework './build/MLTranslate.framework-iphonesimulator.xcarchive/Products/Library/Frameworks/MLTranslate.framework' \
-framework './build/MLTranslate.framework-iphoneos.xcarchive/Products/Library/Frameworks/MLTranslate.framework' \
-output './build/MLTranslate.xcframework'
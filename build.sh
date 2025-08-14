#!/bin/bash

VERSION=$(cat AudioPluginInfo.xcodeproj/project.pbxproj | \
          grep -m1 'MARKETING_VERSION' | cut -d'=' -f2 | \
          tr -d ';' | tr -d ' ')
ARCHIVE_DIR=/Users/Larry/Library/Developer/Xcode/Archives/CommandLine

rm -f make.log
touch make.log
rm -rf build

echo "Building AudioPluginInfo" 2>&1 | tee -a make.log

xcodebuild -project AudioPluginInfo.xcodeproj clean 2>&1 | tee -a make.log
xcodebuild -project AudioPluginInfo.xcodeproj \
    -scheme "AudioPluginInfo Release" -archivePath AudioPluginInfo.xcarchive \
    archive 2>&1 | tee -a make.log

rm -rf ${ARCHIVE_DIR}/AudioPluginInfo-v${VERSION}.xcarchive
cp -rf AudioPluginInfo.xcarchive \
    ${ARCHIVE_DIR}/AudioPluginInfo-v${VERSION}.xcarchive


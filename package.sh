#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $(basename $0) [package | log <submit_id>]" > /dev/stderr
    exit 1
fi

if ! [ -n "${DEV_ID_APP}" ] || ! [ -n "${DEV_ID_INST}" ]; then
    echo "Please set these variables in your environment for code signing:"
    echo "    DEV_ID_APP"
    echo "    DEV_ID_INST"
    echo "Examples:"
    echo '    DEV_ID_APP="Developer ID Application: Your Name (12345678)"'
    echo '    DEV_ID_INST="Developer ID Installer: Your Name (12345678)"'
    exit 1
fi

ACTION=$1
SUBMIT_ID=$2
VERSION=$(cat AudioPluginInfo.xcodeproj/project.pbxproj | \
          grep -m1 'MARKETING_VERSION' | cut -d'=' -f2 | \
          tr -d ';' | tr -d ' ')

APP_ENTITLEMENTS="AudioPluginInfo.entitlements"
APP=./AudioPluginInfo.xcarchive/Products/Applications/AudioPluginInfo.app

if [ "${ACTION}" == "package" ]; then
    # Remove previous artifacts
    rm -f *.pkg
    rm -rf tmp_*
    rm -f log.json

    # Copy components
    mkdir tmp_app
    cp -r ${APP} tmp_app

    # Sign app
    codesign -s "${DEV_ID_APP}" -f --timestamp -o runtime \
        --entitlements "${APP_ENTITLEMENTS}" tmp_app/AudioPluginInfo.app

    # Build component package
    pkgbuild --root tmp_app --identifier com.larrymtaylor.AudioPluginInfo \
        --version ${VERSION} --install-location /Applications \
        --min-os-version 10.11 --component-plist app.plist app.pkg

    # Build installer package
    cat distribution.plist | sed 's/VERSION/${VERSION}/' > dist.plist
    productbuild --sign "${DEV_ID_INST}" --distribution dist.plist \
        --product requirements.plist AudioPluginInfo.pkg

    # If you are using nested containers, only notarize the outermost 
    # container.  For example, if you have an app inside an installer 
    # package on a disk image, sign the app, sign the installer package,
    # and sign the disk image, but only notarize the disk image.

    # Upload for notarization
    xcrun notarytool submit AudioPluginInfo.pkg --keychain-profile \
        "LT_PASSWORD" --wait

    # Staple notary ticket to product
    xcrun stapler staple AudioPluginInfo.pkg
elif [ "${ACTION}" == "log" ]; then
    # Download notarization log file
    xcrun notarytool log ${SUBMIT_ID} --keychain-profile "LT_PASSWORD" log.json
else
    echo "Invalid action ${ACTION}"
    exit 1
fi

exit 0

#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="SleepControl"
APP_BUNDLE="${APP_NAME}.app"
BUILD_DIR=".build/release"

echo "🔨 [1/4] Building ${APP_NAME} (Release)..."
swift build -c release -Xswiftc -nonlib-dependency-scanner

if [[ ! -f ".build/AppIcon.icns" ]]; then
    echo "🎨 [2/4] Generating macOS application icon (AppIcon.icns)..."
    ICONSET_DIR=".build/AppIcon.iconset"
    swift scripts/generate_icon.swift "${ICONSET_DIR}"
    iconutil -c icns "${ICONSET_DIR}" -o ".build/AppIcon.icns"
else
    echo "🎨 [2/4] Reusing existing AppIcon.icns..."
fi

echo "📦 [3/4] Assembling ${APP_BUNDLE} bundle with i18n resources..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp ".build/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

# Copy standard i18n .lproj language bundles
cp -R Sources/SleepControl/Resources/*.lproj "${APP_BUNDLE}/Contents/Resources/"

# Copy custom status bar template icons
cp -f Resources/status_cat_*.png "${APP_BUNDLE}/Contents/Resources/"

cat > "${APP_BUNDLE}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>zh-Hans</string>
        <string>zh-Hant-TW</string>
        <string>zh-Hant-HK</string>
        <string>ja</string>
    </array>
    <key>CFBundleDisplayName</key>
    <string>SleepControl</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.himanzero.SleepControl</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo "🔏 [4/4] Applying ad-hoc codesign signature..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "✅ Build completed successfully: $(pwd)/${APP_BUNDLE}"

# WindDown Notarization Guide

**For: Developer Account Holder**

This guide is for someone with an Apple Developer account to build, sign, and notarize WindDown.

---

## What You Need

- Mac with Xcode installed
- Apple Developer account ($99/year membership)
- Your Developer ID Application certificate installed

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/ghosharnab00/WindDown.git
cd WindDown
```

---

## Step 2: Open in Xcode and Configure Signing

1. Open `WindDown.xcodeproj` in Xcode
2. Select **WindDown** project in the sidebar
3. Select **WindDown** target
4. Go to **Signing & Capabilities** tab
5. Check **Automatically manage signing**
6. Select your **Team** from the dropdown
7. Ensure **Hardened Runtime** is enabled (add it via + Capability if not)

---

## Step 3: Build the Release Archive

```bash
xcodebuild -scheme WindDown -configuration Release -archivePath ~/Desktop/WindDown.xcarchive archive
```

Or in Xcode:
1. Product → Archive
2. Wait for build to complete

---

## Step 4: Export the Signed App

**Option A: Using Xcode**
1. Window → Organizer
2. Select the WindDown archive
3. Click **Distribute App**
4. Choose **Developer ID** → Next
5. Choose **Upload** (for notarization) → Next
6. Select your team → Next
7. Click **Upload** and wait for notarization
8. Once complete, click **Export Notarized App**
9. Save to Desktop

**Option B: Using Command Line**

Create `ExportOptions.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

Then run:
```bash
xcodebuild -exportArchive \
    -archivePath ~/Desktop/WindDown.xcarchive \
    -exportPath ~/Desktop/WindDown-Export \
    -exportOptionsPlist ExportOptions.plist
```

---

## Step 5: Notarize (if not done via Xcode)

```bash
# Store credentials (first time only)
xcrun notarytool store-credentials "notarize-profile" \
    --apple-id "YOUR_APPLE_ID" \
    --team-id "YOUR_TEAM_ID"
# Enter your app-specific password when prompted

# Create and sign DMG
mkdir -p ~/Desktop/DMG-Contents
cp -R ~/Desktop/WindDown-Export/WindDown.app ~/Desktop/DMG-Contents/
ln -s /Applications ~/Desktop/DMG-Contents/Applications

hdiutil create -volname "WindDown" -srcfolder ~/Desktop/DMG-Contents -ov -format UDZO ~/Desktop/WindDown.dmg

# Sign the DMG
codesign --force --sign "Developer ID Application" ~/Desktop/WindDown.dmg

# Notarize
xcrun notarytool submit ~/Desktop/WindDown.dmg --keychain-profile "notarize-profile" --wait

# Staple the ticket
xcrun stapler staple ~/Desktop/WindDown.dmg
```

---

## Step 6: Verify

```bash
# Check notarization
spctl --assess --type open --context context:primary-signature -v ~/Desktop/WindDown.dmg
```

Should output: `accepted`

---

## Step 7: Send Back

Send the notarized `WindDown.dmg` file back. It's ready for public distribution!

---

## Quick Xcode Method (Easiest)

1. Clone repo → Open in Xcode
2. Set your Team in Signing & Capabilities
3. Product → Archive
4. Distribute App → Developer ID → Upload
5. Wait for notarization (~5-10 min)
6. Export Notarized App
7. Create DMG:
   ```bash
   mkdir -p ~/Desktop/DMG && cp -R WindDown.app ~/Desktop/DMG/ && ln -s /Applications ~/Desktop/DMG/
   hdiutil create -volname "WindDown" -srcfolder ~/Desktop/DMG -ov -format UDZO ~/Desktop/WindDown.dmg
   ```
8. Send DMG back

---

## Troubleshooting

**"No signing certificate found"**
- Ensure you have a Developer ID Application certificate
- Download from developer.apple.com → Certificates

**Notarization rejected**
- Check logs: `xcrun notarytool log <id> --keychain-profile "notarize-profile"`
- Usually means hardened runtime not enabled

**"App is damaged"**
- Notarization didn't complete or stapling failed
- Re-run stapler: `xcrun stapler staple WindDown.dmg`

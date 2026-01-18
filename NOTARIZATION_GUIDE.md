# WindDown Notarization Guide

This guide explains how to notarize WindDown using an Apple Developer account.

## What You Need From Your Friend (Developer Account Holder)

Ask your friend to provide:

1. **Developer ID Application Certificate** (exported as .p12 file with password)
2. **Apple ID** associated with the developer account
3. **App-Specific Password** (generated from appleid.apple.com)
4. **Team ID** (found in developer account membership details)

---

## Step-by-Step Process for Your Friend

### Step 1: Export the Developer ID Certificate

Your friend needs to do this on their Mac:

1. Open **Keychain Access**
2. Go to **login** keychain → **My Certificates**
3. Find **"Developer ID Application: [Name]"**
4. Right-click → **Export**
5. Save as `DeveloperID.p12`
6. Set a password (share this password with you securely)

### Step 2: Create an App-Specific Password

1. Go to https://appleid.apple.com
2. Sign in with the Apple ID linked to the developer account
3. Go to **Sign-In and Security** → **App-Specific Passwords**
4. Click **Generate** → Name it "WindDown Notarization"
5. Copy the generated password (format: xxxx-xxxx-xxxx-xxxx)

### Step 3: Find the Team ID

1. Go to https://developer.apple.com/account
2. Click **Membership** in the sidebar
3. Copy the **Team ID** (10-character string)

### Step 4: Share With You

Your friend should securely share:
- `DeveloperID.p12` file
- Password for the .p12 file
- Apple ID email
- App-Specific Password
- Team ID

---

## Steps You Need to Do (After Receiving Credentials)

### Step 1: Import the Certificate

```bash
# Import the certificate to your keychain
security import DeveloperID.p12 -k ~/Library/Keychains/login.keychain-db -P "PASSWORD_HERE" -T /usr/bin/codesign

# Verify it's installed
security find-identity -v -p codesigning
```

You should see something like:
```
1) ABCD1234... "Developer ID Application: Friend Name (TEAM_ID)"
```

### Step 2: Update Xcode Project Signing

1. Open `WindDown.xcodeproj` in Xcode
2. Select the **WindDown** target
3. Go to **Signing & Capabilities**
4. Uncheck **Automatically manage signing**
5. Set **Team** to your friend's team
6. Set **Signing Certificate** to "Developer ID Application"

Or do it via command line - create an `ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>TEAM_ID_HERE</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
</dict>
</plist>
```

### Step 3: Build and Sign the App

```bash
# Clean and archive
xcodebuild clean -scheme WindDown
xcodebuild -scheme WindDown -configuration Release -archivePath ./WindDown.xcarchive archive

# Export signed app
xcodebuild -exportArchive -archivePath ./WindDown.xcarchive -exportPath ./Export -exportOptionsPlist ExportOptions.plist
```

### Step 4: Create a Signed DMG

```bash
# Create DMG folder
mkdir -p DMG-Contents
cp -R ./Export/WindDown.app DMG-Contents/
ln -s /Applications DMG-Contents/Applications

# Create unsigned DMG first
hdiutil create -volname "WindDown" -srcfolder DMG-Contents -ov -format UDRW WindDown-temp.dmg

# Convert to compressed DMG
hdiutil convert WindDown-temp.dmg -format UDZO -o WindDown.dmg
rm WindDown-temp.dmg

# Sign the DMG
codesign --force --sign "Developer ID Application: FRIEND_NAME (TEAM_ID)" WindDown.dmg
```

### Step 5: Notarize the App

```bash
# Store credentials (one-time setup)
xcrun notarytool store-credentials "WindDown-Notarize" \
    --apple-id "APPLE_ID_EMAIL" \
    --password "APP_SPECIFIC_PASSWORD" \
    --team-id "TEAM_ID"

# Submit for notarization
xcrun notarytool submit WindDown.dmg \
    --keychain-profile "WindDown-Notarize" \
    --wait

# Check status (if needed)
xcrun notarytool history --keychain-profile "WindDown-Notarize"
```

This usually takes 2-15 minutes. You'll see:
```
Successfully received submission info
  status: Accepted
```

### Step 6: Staple the Notarization Ticket

```bash
# Staple to DMG
xcrun stapler staple WindDown.dmg

# Verify
xcrun stapler validate WindDown.dmg
spctl --assess --type open --context context:primary-signature -v WindDown.dmg
```

### Step 7: Verify Everything Works

```bash
# Check the app signature
codesign -dv --verbose=4 ./Export/WindDown.app

# Check Gatekeeper approval
spctl --assess --verbose ./Export/WindDown.app
```

You should see: `./Export/WindDown.app: accepted`

---

## Quick Reference Commands

```bash
# Full notarization flow (after setup)
xcodebuild clean -scheme WindDown
xcodebuild -scheme WindDown -configuration Release -archivePath ./WindDown.xcarchive archive
xcodebuild -exportArchive -archivePath ./WindDown.xcarchive -exportPath ./Export -exportOptionsPlist ExportOptions.plist

mkdir -p DMG-Contents
cp -R ./Export/WindDown.app DMG-Contents/
ln -s /Applications DMG-Contents/Applications
hdiutil create -volname "WindDown" -srcfolder DMG-Contents -ov -format UDZO WindDown.dmg
codesign --force --sign "Developer ID Application: NAME (TEAM_ID)" WindDown.dmg

xcrun notarytool submit WindDown.dmg --keychain-profile "WindDown-Notarize" --wait
xcrun stapler staple WindDown.dmg
```

---

## Troubleshooting

### "The signature is invalid"
- Make sure the certificate is properly imported
- Run `security find-identity -v -p codesigning` to verify

### "Notarization failed"
- Check the log: `xcrun notarytool log <submission-id> --keychain-profile "WindDown-Notarize"`
- Common issues: hardened runtime not enabled, unsigned frameworks

### "App is damaged and can't be opened"
- The app wasn't properly signed or notarization failed
- Re-sign and re-notarize

### Enable Hardened Runtime (if needed)

In Xcode:
1. Select target → **Signing & Capabilities**
2. Click **+ Capability**
3. Add **Hardened Runtime**

Or in `project.pbxproj`, ensure:
```
ENABLE_HARDENED_RUNTIME = YES;
```

---

## Security Notes

- Never share certificates publicly
- Use secure channels (Signal, encrypted email) to transfer .p12 files
- App-specific passwords can be revoked anytime
- Your friend retains full control of the developer account

---

## Cost

Apple Developer Program costs $99/year. The certificate your friend provides will work for all apps signed under their account.

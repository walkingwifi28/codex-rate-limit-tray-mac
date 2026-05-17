# macOS Release Checklist

This repository keeps the Windows app untouched and ships the native macOS menu bar app from `macos/`.

## Required Local Tools

- Xcode 16 or later selected with `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- XcodeGen: `brew install xcodegen`
- Sparkle 2 signing tools, including `generate_keys` and `sign_update`. `generate-appcast.sh` passes `SPARKLE_PRIVATE_KEY` to `sign_update --ed-key-file -`.
- Apple Developer ID Application certificate installed in the build keychain

## Required Secrets

- `MACOS_DEVELOPER_ID_APPLICATION_CERT_BASE64`
- `MACOS_DEVELOPER_ID_APPLICATION_CERT_PASSWORD`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `SPARKLE_PRIVATE_KEY`

Store the Sparkle public EdDSA key in `SUPublicEDKey` inside `macos/CodexRateLimitTrayMac/Info.plist`. Keep the private key only in CI secrets or a local password manager.

## Manual Build

```bash
cd macos
xcodegen generate
xcodebuild test -scheme CodexRateLimitTrayMac -destination 'platform=macOS'
xcodebuild -scheme CodexRateLimitTrayMac -configuration Release -destination 'platform=macOS' archive -archivePath ../artifacts/macos/CodexRateLimitTray.xcarchive
```

Export the signed app from the archive, then package:

```bash
APP_PATH=/path/to/CodexRateLimitTray.app VERSION=0.1.0 macos/Scripts/package-dmg.sh
APP_PATH=/path/to/CodexRateLimitTray.app VERSION=0.1.0 macos/Scripts/package-zip.sh
VERSION=0.1.0 SPARKLE_PRIVATE_KEY="$SPARKLE_PRIVATE_KEY" RELEASE_BASE_URL=https://github.com/walkingwifi28/codex-rate-limit-tray-win/releases/download/v0.1.0 macos/Scripts/generate-appcast.sh
```

If `sign_update` is not on `PATH`, pass `SIGN_UPDATE_PATH=/path/to/Sparkle/bin/sign_update`.

Notarize the DMG:

```bash
APPLE_ID="$APPLE_ID" APPLE_TEAM_ID="$APPLE_TEAM_ID" APPLE_APP_SPECIFIC_PASSWORD="$APPLE_APP_SPECIFIC_PASSWORD" macos/Scripts/notarize.sh artifacts/macos/CodexRateLimitTray-0.1.0-macos-universal.dmg
```

Verify an installed app:

```bash
spctl --assess --type execute --verbose /Applications/CodexRateLimitTray.app
xcrun stapler validate /Applications/CodexRateLimitTray.app
```

## Homebrew Tap

After publishing the DMG and updating the SHA256 in the tap repository:

```bash
brew tap walkingwifi28/codex-rate-limit-tray
brew install --cask codex-rate-limit-tray
brew uninstall --cask codex-rate-limit-tray
```

Validate from the tap repository:

```bash
brew audit --cask --new codex-rate-limit-tray
brew install --cask ./Casks/codex-rate-limit-tray.rb
```

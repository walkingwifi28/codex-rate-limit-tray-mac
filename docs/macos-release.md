# macOS Release Checklist

This repository ships the native macOS menu bar app from `macos/`.

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
- `SPARKLE_PUBLIC_ED_KEY`
- `SPARKLE_PRIVATE_KEY`

Store the Sparkle public EdDSA key in `SPARKLE_PUBLIC_ED_KEY` and the matching private key in `SPARKLE_PRIVATE_KEY`. The release workflow injects the public key into `SUPublicEDKey` before archiving and fails if it is missing. Keep the private key only in CI secrets or a local password manager.

Generate a Sparkle EdDSA key pair locally:

```bash
SPARKLE_VERSION=2.7.0
mkdir -p /tmp/sparkle-tools
curl -L "https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-${SPARKLE_VERSION}.tar.xz" -o /tmp/Sparkle.tar.xz
tar -xJf /tmp/Sparkle.tar.xz -C /tmp/sparkle-tools
GENERATE_KEYS="$(find /tmp/sparkle-tools -type f -name generate_keys | head -n 1)"
"$GENERATE_KEYS"
```

Add the generated public key to the GitHub repository secret `SPARKLE_PUBLIC_ED_KEY`.

For CI signing, export the private key and store the file contents in the GitHub repository secret `SPARKLE_PRIVATE_KEY`:

```bash
"$GENERATE_KEYS" -x /tmp/sparkle-private-key.txt
pbcopy < /tmp/sparkle-private-key.txt
rm /tmp/sparkle-private-key.txt
```

## Manual Build

```bash
cd macos
xcodegen generate
xcodebuild test -scheme CodexRateLimitTrayMac -destination 'platform=macOS'
/usr/libexec/PlistBuddy -c "Set :SUPublicEDKey $SPARKLE_PUBLIC_ED_KEY" CodexRateLimitTrayMac/Info.plist
xcodebuild -scheme CodexRateLimitTrayMac -configuration Release -destination 'platform=macOS' archive -archivePath ../artifacts/macos/CodexRateLimitTray.xcarchive
```

Export the signed app from the archive, then package:

```bash
APP_PATH=/path/to/CodexRateLimitTray.app VERSION=0.1.0 macos/Scripts/package-dmg.sh
APP_PATH=/path/to/CodexRateLimitTray.app VERSION=0.1.0 macos/Scripts/package-zip.sh
VERSION=0.1.0 SPARKLE_PRIVATE_KEY="$SPARKLE_PRIVATE_KEY" RELEASE_BASE_URL=https://github.com/<owner>/<repo>/releases/download/v0.1.0 macos/Scripts/generate-appcast.sh
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

After publishing the DMG and updating `sha256` in `Casks/codex-rate-limit-tray.rb`, use this repository as a custom remote tap:

```bash
brew tap walkingwifi28/codex-rate-limit-tray https://github.com/walkingwifi28/codex-rate-limit-tray-mac.git
brew install --cask codex-rate-limit-tray
brew uninstall --cask codex-rate-limit-tray
```

Validate from this repository:

```bash
brew tap walkingwifi28/codex-rate-limit-tray "$PWD"
brew audit --cask --new codex-rate-limit-tray
brew install --cask codex-rate-limit-tray
```

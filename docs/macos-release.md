# macOS Preview Release Checklist

This repository currently ships unsigned preview builds of the native macOS menu bar app from `macos/`.

## Required Local Tools

- Xcode 16 or later selected with `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- XcodeGen: `brew install xcodegen`

## Required Secrets

None for unsigned preview releases.

The preview workflow intentionally does not require Apple Developer ID certificates, Apple notarization credentials, or Sparkle signing keys. It only applies an ad hoc signature with `codesign --sign -` before packaging. Because `SUPublicEDKey` remains set to the placeholder value, the app disables Sparkle update checks at runtime.

## Manual Preview Build

```bash
cd macos
xcodegen generate
xcodebuild test \
  -scheme CodexRateLimitTrayMac \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""
xcodebuild \
  -scheme CodexRateLimitTrayMac \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath ../artifacts/macos/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
```

Package the unsigned app:

```bash
APP_PATH="$PWD/../artifacts/macos/DerivedData/Build/Products/Release/CodexRateLimitTray.app"
codesign --force --deep --sign - "$APP_PATH"
APP_PATH="$APP_PATH" VERSION=0.1.0 OUTPUT_DIR="$PWD/../artifacts/macos" ../macos/Scripts/package-dmg.sh
APP_PATH="$APP_PATH" VERSION=0.1.0 OUTPUT_DIR="$PWD/../artifacts/macos" ../macos/Scripts/package-zip.sh
```

## GitHub Release

Push a tag such as `v0.1.0` to run the preview release workflow. It uploads:

- `CodexRateLimitTray-<version>-macos-universal.dmg`
- `CodexRateLimitTray-<version>-macos-universal.zip`
- matching `.sha256` files

The GitHub release is marked as a prerelease because the app is not Developer ID signed or notarized.

## Gatekeeper

Unsigned preview builds may be blocked on first launch. Users can first try opening the app from Finder by right-clicking `CodexRateLimitTray.app` and choosing `Open`.

If macOS still shows `"CodexRateLimitTray.app" は開いていません`, remove the quarantine attribute from the installed app and open it again:

```bash
xattr -dr com.apple.quarantine /Applications/CodexRateLimitTray.app
open /Applications/CodexRateLimitTray.app
```

Do not present unsigned preview builds as a fully trusted macOS distribution. Once Apple Developer Program access is available, restore Developer ID signing, notarization, and Sparkle appcast generation before calling the release stable.

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

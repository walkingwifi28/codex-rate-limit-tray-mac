# Codexレート制限トレイ

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0%2B-000000?logo=apple&logoColor=white" alt="macOS 13.0+" />
  <img src="https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white" alt="Swift 5.0" />
  <img src="https://img.shields.io/badge/Homebrew-Cask-FBB040?logo=homebrew&logoColor=black" alt="Homebrew Cask" />
</p>

## Installation

### Quick Start (Recommended)

```bash
brew tap walkingwifi28/codex-rate-limit-tray https://github.com/walkingwifi28/codex-rate-limit-tray-mac.git
brew install --cask codex-rate-limit-tray
xattr -dr com.apple.quarantine /Applications/CodexRateLimitTray.app # Apple Developer 未署名のため、quarantine属性を削除して起動
open /Applications/CodexRateLimitTray.app
```

アンインストールする場合:

```bash
brew uninstall --cask codex-rate-limit-tray
```

## Overview

macOS メニューバーに Codex/ChatGPT の `wham/usage` 使用率、残り率、リセット時刻を表示するネイティブアプリです。

現在の macOS 版は `macos/` 配下の Swift/SwiftUI アプリとして実装されています。現時点の配布は GitHub Releases の unsigned preview DMG と Homebrew Cask を想定しています。

## Requirements

- macOS Ventura 13.0 以降
- Homebrew
- Codex/ChatGPT の認証情報が保存されたローカル環境

## Development

開発には Xcode 16 以降と XcodeGen が必要です。

```bash
brew install xcodegen
cd macos
xcodegen generate
xcodebuild test -scheme CodexRateLimitTrayMac -destination 'platform=macOS'
```

preview build の作成手順は [docs/macos-release.md](docs/macos-release.md) にまとめています。

## Distribution

配布は GitHub Releases 上の DMG/ZIP と Homebrew Cask で行います。タグ `vX.Y.Z` を push すると GitHub Actions が test、Release build、ad hoc signing、DMG/ZIP 生成、SHA256 生成、GitHub prerelease 添付を実行します。

Homebrew Cask の `sha256` はリリースで生成された `.sha256` の値に置き換えてから `Casks/codex-rate-limit-tray.rb` に反映します。このリポジトリ自体を Homebrew tap として使うため、`brew tap` には Git URL を明示します。tap の検証例:

```bash
brew tap walkingwifi28/codex-rate-limit-tray "$PWD"
brew audit --cask --new codex-rate-limit-tray
brew install --cask codex-rate-limit-tray
```

### Unsigned Preview Builds

preview build は Apple Developer ID で署名されておらず、notarization も通していません。証明書不要の ad hoc signing のみ行います。初回起動時に Gatekeeper の警告が出る場合は、Finder でアプリを右クリックして `開く` を選択してください。

それでも `開いていません` と表示される場合は、Homebrew でインストールしたアプリの quarantine 属性を削除してから起動します。

```bash
xattr -dr com.apple.quarantine /Applications/CodexRateLimitTray.app
open /Applications/CodexRateLimitTray.app
```

Apple Developer Program を使えるようになったら、Developer ID 署名、notarization、Sparkle appcast を release workflow に戻します。

## License

[MIT](LICENSE) © [@walkingwifi28](https://github.com/walkingwifi28)

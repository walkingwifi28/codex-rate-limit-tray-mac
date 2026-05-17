# Codexレート制限トレイ

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0%2B-000000?logo=apple&logoColor=white" alt="macOS 13.0+" />
  <img src="https://img.shields.io/badge/Swift-5.0-F05138?logo=swift&logoColor=white" alt="Swift 5.0" />
  <img src="https://img.shields.io/badge/Homebrew-Cask-FBB040?logo=homebrew&logoColor=black" alt="Homebrew Cask" />
</p>

## Installation

### Quick Start (Recommended)

```bash
brew tap walkingwifi28/codex-rate-limit-tray
brew install --cask codex-rate-limit-tray
```

アンインストールする場合:

```bash
brew uninstall --cask codex-rate-limit-tray
```

## Overview

macOS メニューバーに Codex/ChatGPT の `wham/usage` 使用率、残り率、リセット時刻を表示するネイティブアプリです。

現在の macOS 版は `macos/` 配下の Swift/SwiftUI アプリとして実装されています。自動更新には Sparkle 2 を使用し、配布は GitHub Releases の notarized DMG と Homebrew Cask を想定しています。

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

リリース用の archive や notarization 手順は [docs/macos-release.md](docs/macos-release.md) にまとめています。

## Distribution

配布は GitHub Releases 上の DMG/ZIP と Homebrew Cask で行います。タグ `vX.Y.Z` を push すると GitHub Actions が test、archive、署名、notarization、DMG/ZIP 生成、Sparkle appcast 生成、SHA256 生成、GitHub Release 添付を実行します。

Homebrew Cask の `sha256` はリリースで生成された `.sha256` の値に置き換えてから tap に反映します。tap の検証例:

```bash
brew audit --cask --new codex-rate-limit-tray
brew install --cask ./Casks/codex-rate-limit-tray.rb
```

### Code signing

macOS 版は Apple Developer ID Application 証明書で署名し、Apple notarization を通した成果物だけを配布する方針です。Sparkle の更新検証には EdDSA key を使用します。

release workflow には Apple Developer ID 証明書、notarization 用 Apple ID、Sparkle の公開鍵/秘密鍵を repository secrets として設定します。必要な secret 名とローカル検証手順は [docs/macos-release.md](docs/macos-release.md) を参照してください。

## License

[MIT](LICENSE) © [@walkingwifi28](https://github.com/walkingwifi28)

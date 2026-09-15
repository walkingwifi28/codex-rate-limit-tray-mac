cask "codex-rate-limit-tray" do
  version "0.2.0"
  sha256 "82024f727a1e508ea7ec4ec0748d6f2aa717ee0f0e015ce2428306aeab9c6ae9"

  url "https://github.com/walkingwifi28/codex-rate-limit-tray-mac/releases/download/v#{version}/CodexRateLimitTray-#{version}-macos-universal.dmg"
  name "Codex Rate Limit Tray"
  desc "Menu bar app showing Codex and ChatGPT rate limit usage"
  homepage "https://github.com/walkingwifi28/codex-rate-limit-tray-mac"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates false
  depends_on macos: :ventura

  app "CodexRateLimitTray.app"

  caveats <<~EOS
    This preview build is not Developer ID signed or notarized.
    If macOS blocks the app on first launch, run:
      xattr -dr com.apple.quarantine /Applications/CodexRateLimitTray.app
  EOS

  zap trash: [
    "~/Library/Preferences/jp.walkingwifi.CodexRateLimitTrayMac.plist",
    "~/Library/Application Support/CodexRateLimitTray",
    "~/Library/Caches/jp.walkingwifi.CodexRateLimitTrayMac",
  ]
end

cask "codex-rate-limit-tray" do
  version "0.1.14"
  sha256 "4e0ec5462da571046ab63f8ec373a05c7621ef4c66b8e6da8e605d122407d7d3"

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

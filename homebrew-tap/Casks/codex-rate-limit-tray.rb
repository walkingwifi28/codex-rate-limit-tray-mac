cask "codex-rate-limit-tray" do
  version "0.1.0"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/walkingwifi28/codex-rate-limit-tray-win/releases/download/v#{version}/CodexRateLimitTray-#{version}-macos-universal.dmg"
  name "Codex Rate Limit Tray"
  desc "Menu bar app showing Codex and ChatGPT rate limit usage"
  homepage "https://github.com/walkingwifi28/codex-rate-limit-tray-win"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :ventura"

  app "CodexRateLimitTray.app"

  zap trash: [
    "~/Library/Preferences/jp.walkingwifi.CodexRateLimitTrayMac.plist",
    "~/Library/Application Support/CodexRateLimitTray",
    "~/Library/Caches/jp.walkingwifi.CodexRateLimitTrayMac",
  ]
end

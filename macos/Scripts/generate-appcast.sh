#!/usr/bin/env bash
set -euo pipefail

: "${VERSION:?VERSION is required}"
: "${SPARKLE_PRIVATE_KEY:?SPARKLE_PRIVATE_KEY is required}"
: "${RELEASE_BASE_URL:?RELEASE_BASE_URL is required}"

OUTPUT_DIR="${OUTPUT_DIR:-artifacts/macos}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${OUTPUT_DIR}/CodexRateLimitTray-${VERSION}-macos-universal.zip}"
APPCAST_PATH="${APPCAST_PATH:-${OUTPUT_DIR}/appcast.xml}"
PUB_DATE="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S %z')"
ARCHIVE_NAME="$(basename "${ARCHIVE_PATH}")"
ARCHIVE_SIZE="$(stat -f%z "${ARCHIVE_PATH}")"

SIGN_UPDATE="${SIGN_UPDATE_PATH:-sign_update}"

if ! command -v "${SIGN_UPDATE}" >/dev/null 2>&1; then
  echo "sign_update is required. Set SIGN_UPDATE_PATH or add Sparkle/bin to PATH." >&2
  exit 69
fi

SIGN_OUTPUT="$(printf '%s' "${SPARKLE_PRIVATE_KEY}" | "${SIGN_UPDATE}" --ed-key-file - "${ARCHIVE_PATH}")"
SIGNATURE="$(printf '%s\n' "${SIGN_OUTPUT}" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p' | head -n 1)"

if [[ -z "${SIGNATURE}" ]]; then
  echo "Could not parse sparkle:edSignature from sign_update output:" >&2
  printf '%s\n' "${SIGN_OUTPUT}" >&2
  exit 70
fi

cat > "${APPCAST_PATH}" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Codex Rate Limit Tray Updates</title>
    <item>
      <title>Version ${VERSION}</title>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:version>${VERSION}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <enclosure
        url="${RELEASE_BASE_URL}/${ARCHIVE_NAME}"
        sparkle:edSignature="${SIGNATURE}"
        length="${ARCHIVE_SIZE}"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
XML

shasum -a 256 "${APPCAST_PATH}" > "${APPCAST_PATH}.sha256"
echo "${APPCAST_PATH}"

#!/usr/bin/env bash
set -euo pipefail

: "${APP_PATH:?APP_PATH is required}"
: "${VERSION:?VERSION is required}"

OUTPUT_DIR="${OUTPUT_DIR:-artifacts/macos}"
APP_NAME="$(basename "${APP_PATH}" .app)"
DMG_PATH="${OUTPUT_DIR}/${APP_NAME}-${VERSION}-macos-universal.dmg"
STAGING_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${STAGING_DIR}"
}
trap cleanup EXIT

mkdir -p "${OUTPUT_DIR}"
cp -R "${APP_PATH}" "${STAGING_DIR}/"

hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

shasum -a 256 "${DMG_PATH}" > "${DMG_PATH}.sha256"
echo "${DMG_PATH}"

#!/usr/bin/env bash
set -euo pipefail

: "${APP_PATH:?APP_PATH is required}"
: "${VERSION:?VERSION is required}"

OUTPUT_DIR="${OUTPUT_DIR:-artifacts/macos}"
APP_NAME="$(basename "${APP_PATH}" .app)"
ZIP_PATH="${OUTPUT_DIR}/${APP_NAME}-${VERSION}-macos-universal.zip"

mkdir -p "${OUTPUT_DIR}"
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"
shasum -a 256 "${ZIP_PATH}" > "${ZIP_PATH}.sha256"
echo "${ZIP_PATH}"

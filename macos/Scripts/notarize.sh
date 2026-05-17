#!/usr/bin/env bash
set -euo pipefail

: "${APPLE_ID:?APPLE_ID is required}"
: "${APPLE_TEAM_ID:?APPLE_TEAM_ID is required}"
: "${APPLE_APP_SPECIFIC_PASSWORD:?APPLE_APP_SPECIFIC_PASSWORD is required}"

ARTIFACT_PATH="${1:-${DMG_PATH:-}}"
if [[ -z "${ARTIFACT_PATH}" ]]; then
  echo "Usage: DMG_PATH=path/to/app.dmg $0 or $0 path/to/app.dmg" >&2
  exit 64
fi

xcrun notarytool submit "${ARTIFACT_PATH}" \
  --apple-id "${APPLE_ID}" \
  --team-id "${APPLE_TEAM_ID}" \
  --password "${APPLE_APP_SPECIFIC_PASSWORD}" \
  --wait

xcrun stapler staple "${ARTIFACT_PATH}"
xcrun stapler validate "${ARTIFACT_PATH}"

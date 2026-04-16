#!/usr/bin/env bash
# Build and release a new version of the diary app to R2.
#
# Usage:
#   ./scripts/release.sh <version> <buildNumber> "<release notes>"
#
# Example:
#   ./scripts/release.sh 1.1.0 2 "Fixed task list sort order"
#
# Prereqs:
#   - ~/.aws/credentials [r2] profile configured
#   - .r2.env at repo root with R2_BUCKET, R2_ENDPOINT, R2_PUBLIC_BASE
#   - android/key.properties in place for release signing

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <version> <buildNumber> \"<notes>\"" >&2
  exit 1
fi

VERSION="$1"
BUILD_NUMBER="$2"
NOTES="$3"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [[ ! -f .r2.env ]]; then
  echo "ERROR: .r2.env not found at repo root" >&2
  exit 1
fi

set -a
source .r2.env
set +a

echo "==> Bumping pubspec.yaml to $VERSION+$BUILD_NUMBER"
# Portable sed -i on macOS + Linux
if [[ "$(uname)" == "Darwin" ]]; then
  sed -i '' "s/^version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml
else
  sed -i "s/^version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml
fi

echo "==> Building release APK"
flutter build apk --release

APK_LOCAL="build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK_LOCAL" ]]; then
  echo "ERROR: expected APK at $APK_LOCAL" >&2
  exit 1
fi

APK_KEY="v$VERSION/app-release.apk"
APK_URL="$R2_PUBLIC_BASE/$APK_KEY"

echo "==> Uploading APK to s3://$R2_BUCKET/$APK_KEY"
aws --profile r2 --endpoint-url "$R2_ENDPOINT" s3 cp \
  "$APK_LOCAL" "s3://$R2_BUCKET/$APK_KEY" \
  --content-type application/vnd.android.package-archive

echo "==> Writing latest.json"
MANIFEST="$(mktemp)"
cat >"$MANIFEST" <<EOF
{
  "version": "$VERSION",
  "buildNumber": $BUILD_NUMBER,
  "apkUrl": "$APK_URL",
  "notes": $(python3 -c 'import json,sys;print(json.dumps(sys.argv[1]))' "$NOTES")
}
EOF

aws --profile r2 --endpoint-url "$R2_ENDPOINT" s3 cp \
  "$MANIFEST" "s3://$R2_BUCKET/latest.json" \
  --content-type application/json \
  --cache-control "no-cache, max-age=0"

rm -f "$MANIFEST"

echo ""
echo "Released v$VERSION (build $BUILD_NUMBER)"
echo "APK:      $APK_URL"
echo "Manifest: $R2_PUBLIC_BASE/latest.json"

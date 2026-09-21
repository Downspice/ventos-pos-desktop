#!/usr/bin/env bash
# Build release Ventos POS desktop for macOS and/or Windows against a deployed API.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$APP_DIR"

usage() {
  cat <<'EOF'
Usage: scripts/build-release.sh [--platform macos|windows|all]

Reads API URLs from .env.build (see .env.build.example) or the environment.

Environment:
  ENV_FILE          Path to env file (default: .env.build in app root)
  VENTOS_API_URL    GraphQL HTTP endpoint (required)
  VENTOS_WEB_URL    Ventos Web origin (optional)
  BUILD_VERSION     Override semver from pubspec.yaml
  BUILD_NUMBER      Override build number from pubspec.yaml

Outputs zip archives under dist/<version>/
EOF
}

PLATFORM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

ENV_FILE="${ENV_FILE:-$APP_DIR/.env.build}"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

VENTOS_API_URL="${VENTOS_API_URL:-}"
if [[ -z "$VENTOS_API_URL" ]]; then
  echo "VENTOS_API_URL is required. Copy .env.build.example to .env.build or export it." >&2
  exit 1
fi

if [[ "$VENTOS_API_URL" != */graphql ]]; then
  VENTOS_API_URL="${VENTOS_API_URL%/}/graphql"
fi

read -r PUBSPEC_VERSION _ <<<"$(grep '^version:' pubspec.yaml | awk '{print $2}')"
BUILD_VERSION="${BUILD_VERSION:-${PUBSPEC_VERSION%%+*}}"
BUILD_NUMBER="${BUILD_NUMBER:-${PUBSPEC_VERSION##*+}}"

DART_DEFINES=(--dart-define="VENTOS_API_URL=${VENTOS_API_URL}")
if [[ -n "${VENTOS_WEB_URL:-}" ]]; then
  DART_DEFINES+=(--dart-define="VENTOS_WEB_URL=${VENTOS_WEB_URL}")
fi

DIST="$APP_DIR/dist/${BUILD_VERSION}"
mkdir -p "$DIST"

echo "→ Ventos POS release ${BUILD_VERSION}+${BUILD_NUMBER}"
echo "  API: ${VENTOS_API_URL}"
[[ -n "${VENTOS_WEB_URL:-}" ]] && echo "  Web: ${VENTOS_WEB_URL}"

flutter pub get

build_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "macOS build skipped (requires Darwin host)." >&2
    return 0
  fi
  echo "→ Building macOS…"
  flutter build macos --release \
    "${DART_DEFINES[@]}" \
    --build-name="$BUILD_VERSION" \
    --build-number="$BUILD_NUMBER"
  local app="build/macos/Build/Products/Release/ventos_pos.app"
  local zip="$DIST/VentosPOS-macOS-${BUILD_VERSION}.zip"
  ditto -c -k --keepParent "$app" "$zip"
  echo "  $zip"
}

is_windows_host() {
  case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*) return 0 ;;
  esac
  [[ "${OS:-}" == "Windows_NT" ]]
}

build_windows() {
  if ! is_windows_host; then
    echo "Windows build skipped (requires a Windows host or GitHub Actions release workflow)." >&2
    return 0
  fi
  if ! flutter config --list 2>/dev/null | grep -q "enable-windows-desktop: true"; then
    flutter config --enable-windows-desktop >/dev/null 2>&1 || true
  fi
  echo "→ Building Windows…"
  flutter build windows --release \
    "${DART_DEFINES[@]}" \
    --build-name="$BUILD_VERSION" \
    --build-number="$BUILD_NUMBER"
  local out="build/windows/x64/runner/Release"
  local zip="$DIST/VentosPOS-Windows-${BUILD_VERSION}.zip"
  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command \
      "Compress-Archive -Path '${out}/*' -DestinationPath '${zip}' -Force"
  elif command -v zip >/dev/null 2>&1; then
    (cd "$out" && zip -r "$zip" .)
  else
    echo "No zip tool found; artifacts in $out" >&2
    return 0
  fi
  echo "  $zip"
}

if [[ -z "$PLATFORM" ]]; then
  case "$(uname -s)" in
    Darwin) PLATFORM="macos" ;;
    MINGW* | *_NT*) PLATFORM="windows" ;;
    *) PLATFORM="macos" ;;
  esac
fi

case "$PLATFORM" in
  macos) build_macos ;;
  windows) build_windows ;;
  all)
    build_macos
    build_windows
    ;;
  *)
    echo "Unknown platform: $PLATFORM" >&2
    exit 1
    ;;
esac

echo "Done. Distributables: $DIST"

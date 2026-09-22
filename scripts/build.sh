#!/usr/bin/env bash
set -euo pipefail

# Tally Build Script
# Usage:
#   ./scripts/build.sh web          # Build production PWA / Web bundle
#   ./scripts/build.sh apk          # Build Android APK (release)
#   ./scripts/build.sh appbundle    # Build Android App Bundle (release)
#   ./scripts/build.sh ios          # Build iOS release bundle (no codesign)
#   ./scripts/build.sh macos        # Build macOS desktop release
#   ./scripts/build.sh all          # Build web and mobile artifacts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}             Tally — Production Build          ${NC}"
echo -e "${CYAN}===============================================${NC}"

TARGET="${1:-web}"

build_web() {
  echo -e "\n${YELLOW}Building Web / PWA release...${NC}"
  flutter build web --release --pwa-strategy offline-first
  echo -e "${GREEN}✓ Web build completed in build/web/${NC}"
}

build_apk() {
  echo -e "\n${YELLOW}Building Android APK (release)...${NC}"
  flutter build apk --release
  echo -e "${GREEN}✓ APK build completed in build/app/outputs/flutter-apk/${NC}"
}

build_appbundle() {
  echo -e "\n${YELLOW}Building Android App Bundle (release)...${NC}"
  flutter build appbundle --release
  echo -e "${GREEN}✓ App Bundle completed in build/app/outputs/bundle/release/${NC}"
}

build_ios() {
  echo -e "\n${YELLOW}Building iOS release (no-codesign)...${NC}"
  flutter build ios --release --no-codesign
  echo -e "${GREEN}✓ iOS build completed in build/ios/iphoneos/${NC}"
}

build_macos() {
  echo -e "\n${YELLOW}Building macOS desktop release...${NC}"
  flutter build macos --release
  echo -e "${GREEN}✓ macOS build completed in build/macos/Build/Products/Release/${NC}"
}

case "${TARGET}" in
  web)
    build_web
    ;;
  apk)
    build_apk
    ;;
  appbundle)
    build_appbundle
    ;;
  ios)
    build_ios
    ;;
  macos)
    build_macos
    ;;
  all)
    build_web
    build_apk
    build_appbundle
    ;;
  *)
    echo -e "${RED}Unknown build target: ${TARGET}${NC}"
    echo "Valid targets: web, apk, appbundle, ios, macos, all"
    exit 1
    ;;
esac

echo -e "\n${GREEN}===============================================${NC}"
echo -e "${GREEN}             Build Succeeded                   ${NC}"
echo -e "${GREEN}===============================================${NC}"

#!/usr/bin/env bash
set -euo pipefail

# Tally Clean Script
# Cleans Flutter build cache, temporary files, and reinstalls pub packages.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}             Tally — Clean Cache               ${NC}"
echo -e "${CYAN}===============================================${NC}"

echo -e "${YELLOW}Cleaning Flutter build cache...${NC}"
flutter clean

echo -e "${YELLOW}Resolving dependencies...${NC}"
flutter pub get

echo -e "${GREEN}✓ Clean & dependency resolution completed.${NC}"

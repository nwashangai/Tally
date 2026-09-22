#!/usr/bin/env bash
set -euo pipefail

# Tally Test Runner
# Usage:
#   ./scripts/test.sh              # Run all unit and widget tests
#   ./scripts/test.sh --coverage   # Run with coverage report

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}             Tally — Test Suite                ${NC}"
echo -e "${CYAN}===============================================${NC}"

COVERAGE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --coverage|-c)
      COVERAGE=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [ "$COVERAGE" = true ]; then
  echo -e "${YELLOW}Running tests with coverage...${NC}"
  flutter test --coverage
  echo -e "${GREEN}✓ Coverage report generated at coverage/lcov.info${NC}"
else
  echo -e "${YELLOW}Running unit & widget tests...${NC}"
  flutter test
  echo -e "${GREEN}✓ All tests passed!${NC}"
fi

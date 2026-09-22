#!/usr/bin/env bash
set -euo pipefail

# Tally Quality Gate Audit Runner
# Executes Gate 0, Gate 1, and Gate 2 checks before commits/PRs.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}          Tally — Quality Gate Audit           ${NC}"
echo -e "${CYAN}===============================================${NC}"

echo -e "\n${YELLOW}[1/4] Checking code formatting (dart format)...${NC}"
if dart format --output=none --set-exit-if-changed .; then
  echo -e "${GREEN}✓ Code formatting passed.${NC}"
else
  echo -e "${RED}✗ Code formatting failed. Run: dart format .${NC}"
  exit 1
fi

echo -e "\n${YELLOW}[2/4] Running static analysis (dart analyze)...${NC}"
if dart analyze; then
  echo -e "${GREEN}✓ Static analysis passed (0 warnings, 0 errors).${NC}"
else
  echo -e "${RED}✗ Static analysis reported issues.${NC}"
  exit 1
fi

echo -e "\n${YELLOW}[3/4] Running test suite (flutter test)...${NC}"
if flutter test; then
  echo -e "${GREEN}✓ All automated tests passed.${NC}"
else
  echo -e "${RED}✗ Tests failed.${NC}"
  exit 1
fi

echo -e "\n${YELLOW}[4/4] Verifying secret exposure guardrails...${NC}"
if git grep -i -E '(AIza[0-9A-Za-z-_]{35}|sk_[live|test]_[0-9a-zA-Z]{24}|ghp_[0-9a-zA-Z]{36})' -- ':!pubspec.lock' ':!scripts/gate.sh' > /dev/null 2>&1; then
  echo -e "${RED}✗ Potential secret detected in codebase!${NC}"
  exit 1
else
  echo -e "${GREEN}✓ No plain-text API secrets detected.${NC}"
fi

echo -e "\n${GREEN}===============================================${NC}"
echo -e "${GREEN}       ✓ ALL QUALITY GATES PASSED!            ${NC}"
echo -e "${GREEN}===============================================${NC}"

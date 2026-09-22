#!/usr/bin/env bash
set -eo pipefail

# Tally Smart Development Runner
# 
# Fallback Hierarchy (when no target is specified):
#   1. Android Emulator (uses running emulator/device, else boots available Android AVD)
#   2. iOS Simulator (uses running simulator, else boots available iOS Simulator)
#   3. Google Chrome (Web/PWA on port 3000)
#
# Usage:
#   ./scripts/dev.sh                                # Auto-detect with cascade fallback (Android -> iOS -> Chrome)
#   ./scripts/dev.sh --device="Pixel 9 Pro"         # Target Android or iOS device/simulator by name
#   ./scripts/dev.sh --device="iPhone 17 Pro"       # Target specific iOS simulator by name
#   ./scripts/dev.sh -d <device_id_or_name>         # Short device flag
#   ./scripts/dev.sh --android                      # Target Android (starts AVD if needed)
#   ./scripts/dev.sh --ios                          # Target iOS (starts Simulator if needed)
#   ./scripts/dev.sh --chrome                       # Target Chrome (Web/PWA)
#   ./scripts/dev.sh --macos                        # Target macOS Desktop

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}===============================================${NC}"
echo -e "${CYAN}           Tally — Development Runner          ${NC}"
echo -e "${CYAN}===============================================${NC}"

EXPLICIT_DEVICE=""
EXPLICIT_PLATFORM=""
PORT="3000"
EXTRA_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --device=*)
      EXPLICIT_DEVICE="${1#*=}"
      shift
      ;;
    -d=*)
      EXPLICIT_DEVICE="${1#*=}"
      shift
      ;;
    --device|-d)
      EXPLICIT_DEVICE="$2"
      shift 2
      ;;
    --android)
      EXPLICIT_PLATFORM="android"
      shift
      ;;
    --ios)
      EXPLICIT_PLATFORM="ios"
      shift
      ;;
    --chrome|--web)
      EXPLICIT_PLATFORM="chrome"
      shift
      ;;
    --macos)
      EXPLICIT_PLATFORM="macos"
      shift
      ;;
    --port=*)
      PORT="${1#*=}"
      shift
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

# Python helper to query connected devices safely from JSON
query_running_device() {
  local platform_or_name="$1"
  python3 -c "
import json, subprocess, sys
target = sys.argv[1].lower()
try:
    out = subprocess.check_output(['flutter', 'devices', '--machine'], stderr=subprocess.DEVNULL)
    devices = json.loads(out)
    # Match by targetPlatform or id or name
    for d in devices:
        plat = d.get('targetPlatform', '').lower()
        dev_id = d.get('id', '').lower()
        name = d.get('name', '').lower()
        if target in plat or target == dev_id or target in name:
            print(d.get('id'))
            sys.exit(0)
except Exception:
    pass
" "${platform_or_name}" 2>/dev/null || true
}

# Helper: Wait for a device/platform to appear in `flutter devices`
wait_for_running_device() {
  local pattern="$1"
  local max_seconds="${2:-30}"
  local count=0
  echo -n -e "${YELLOW}Waiting for device (${pattern}) to boot and register...${NC}"
  while [ $count -lt "$max_seconds" ]; do
    local dev_id
    dev_id=$(query_running_device "${pattern}")
    if [ -n "${dev_id}" ]; then
      echo -e "\n${GREEN}✓ Device is ready: ${dev_id}${NC}"
      echo "${dev_id}"
      return 0
    fi
    sleep 2
    count=$((count + 2))
    echo -n "."
  done
  echo -e "\n${YELLOW}Device did not register within ${max_seconds}s.${NC}"
  return 1
}

# Helper: Get available Android emulator ID
get_available_android_emulator() {
  flutter emulators 2>/dev/null | grep -i "android" | grep -v "Platform" | awk '{print $1}' | head -n 1 || true
}

# Helper: Get available iOS simulator ID
get_available_ios_emulator() {
  flutter emulators 2>/dev/null | grep -i "ios" | grep -v "Platform" | awk '{print $1}' | head -n 1 || true
}

# Run Flutter on resolved device ID
run_flutter_with_device() {
  local dev_id="$1"
  echo -e "${GREEN}▶ Launching Flutter on device: ${CYAN}${dev_id}${NC}\n"
  if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
    exec flutter run -d "${dev_id}" "${EXTRA_ARGS[@]}"
  else
    exec flutter run -d "${dev_id}"
  fi
}

# Run Flutter Web / Chrome
run_flutter_chrome() {
  echo -e "${GREEN}▶ Launching Flutter Web on Chrome (http://localhost:${PORT})${NC}\n"
  if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
    exec flutter run -d chrome --web-port "${PORT}" "${EXTRA_ARGS[@]}"
  else
    exec flutter run -d chrome --web-port "${PORT}"
  fi
}

# -------------------------------------------------------------
# CASE 1: User explicitly specified a device (--device or -d)
# -------------------------------------------------------------
if [ -n "${EXPLICIT_DEVICE}" ]; then
  echo -e "${YELLOW}Looking for requested device: ${GREEN}${EXPLICIT_DEVICE}${NC}"
  
  # Check if already connected/running
  MATCHING_RUNNING=$(query_running_device "${EXPLICIT_DEVICE}")
  if [ -n "${MATCHING_RUNNING}" ]; then
    echo -e "${GREEN}✓ Found running device ID: ${MATCHING_RUNNING}${NC}"
    run_flutter_with_device "${MATCHING_RUNNING}"
  fi

  # Check if matches an emulator in `flutter emulators`
  EMU_MATCH=$(flutter emulators 2>/dev/null | grep -i "${EXPLICIT_DEVICE}" | awk '{print $1}' | head -n 1 || true)
  if [ -n "${EMU_MATCH}" ]; then
    echo -e "${YELLOW}Starting emulator: ${GREEN}${EMU_MATCH}${NC}..."
    flutter emulators --launch "${EMU_MATCH}" > /dev/null 2>&1 &
    BOOTED_ID=$(wait_for_running_device "${EMU_MATCH}" 30 || true)
    if [ -n "${BOOTED_ID}" ]; then
      run_flutter_with_device "${BOOTED_ID}"
    fi
  fi

  # Check if iOS Simulator name (via xcrun simctl)
  if command -v xcrun >/dev/null 2>&1; then
    SIM_ID=$(xcrun simctl list devices available 2>/dev/null | grep -i "${EXPLICIT_DEVICE}" | head -n 1 | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' || true)
    if [ -n "${SIM_ID}" ]; then
      echo -e "${YELLOW}Booting iOS Simulator (${EXPLICIT_DEVICE}: ${SIM_ID})...${NC}"
      xcrun simctl boot "${SIM_ID}" 2>/dev/null || true
      open -a Simulator 2>/dev/null || true
      BOOTED_ID=$(wait_for_running_device "${SIM_ID}" 25 || true)
      if [ -n "${BOOTED_ID}" ]; then
        run_flutter_with_device "${BOOTED_ID}"
      fi
    fi
  fi

  echo -e "${YELLOW}Attempting direct flutter run with target: '${EXPLICIT_DEVICE}'...${NC}"
  run_flutter_with_device "${EXPLICIT_DEVICE}"
fi

# -------------------------------------------------------------
# CASE 2: User explicitly specified a platform flag
# -------------------------------------------------------------
if [ "${EXPLICIT_PLATFORM}" = "chrome" ]; then
  run_flutter_chrome
elif [ "${EXPLICIT_PLATFORM}" = "macos" ]; then
  run_flutter_with_device "macos"
elif [ "${EXPLICIT_PLATFORM}" = "android" ]; then
  RUNNING_ANDROID=$(query_running_device "android")
  if [ -n "${RUNNING_ANDROID}" ]; then
    echo -e "${GREEN}✓ Found running Android device: ${RUNNING_ANDROID}${NC}"
    run_flutter_with_device "${RUNNING_ANDROID}"
  fi
  ANDROID_EMU=$(get_available_android_emulator)
  if [ -n "${ANDROID_EMU}" ]; then
    echo -e "${YELLOW}Starting Android emulator: ${GREEN}${ANDROID_EMU}${NC}..."
    flutter emulators --launch "${ANDROID_EMU}" > /dev/null 2>&1 &
    BOOTED_ID=$(wait_for_running_device "android" 30 || true)
    if [ -n "${BOOTED_ID}" ]; then
      run_flutter_with_device "${BOOTED_ID}"
    else
      echo -e "${RED}Android emulator failed to start or register in time.${NC}"
      exit 1
    fi
  else
    echo -e "${RED}No Android emulators found.${NC}"
    exit 1
  fi
elif [ "${EXPLICIT_PLATFORM}" = "ios" ]; then
  RUNNING_IOS=$(query_running_device "ios")
  if [ -n "${RUNNING_IOS}" ]; then
    echo -e "${GREEN}✓ Found running iOS Simulator: ${RUNNING_IOS}${NC}"
    run_flutter_with_device "${RUNNING_IOS}"
  fi
  IOS_EMU=$(get_available_ios_emulator)
  if [ -n "${IOS_EMU}" ]; then
    echo -e "${YELLOW}Starting iOS simulator: ${GREEN}${IOS_EMU}${NC}..."
    flutter emulators --launch "${IOS_EMU}" > /dev/null 2>&1 &
    BOOTED_ID=$(wait_for_running_device "ios" 25 || true)
    if [ -n "${BOOTED_ID}" ]; then
      run_flutter_with_device "${BOOTED_ID}"
    else
      echo -e "${RED}iOS simulator failed to start or register in time.${NC}"
      exit 1
    fi
  else
    echo -e "${RED}No iOS simulators found.${NC}"
    exit 1
  fi
fi

# -------------------------------------------------------------
# CASE 3: Automatic Auto-Detect with Cascade Fallback
# Order: 1) Android Emulator -> 2) iOS Simulator -> 3) Chrome
# -------------------------------------------------------------
echo -e "${YELLOW}[Auto-Detect] Searching for preferred development targets...${NC}"

# 1. Try Android
echo -e "${CYAN}→ [1/3] Checking Android...${NC}"
RUNNING_ANDROID=$(query_running_device "android")
if [ -n "${RUNNING_ANDROID}" ]; then
  echo -e "${GREEN}✓ Found active Android device/emulator: ${RUNNING_ANDROID}${NC}"
  run_flutter_with_device "${RUNNING_ANDROID}"
fi

ANDROID_EMU=$(get_available_android_emulator)
if [ -n "${ANDROID_EMU}" ]; then
  echo -e "${YELLOW}Android emulator '${ANDROID_EMU}' available. Launching...${NC}"
  flutter emulators --launch "${ANDROID_EMU}" > /dev/null 2>&1 &
  BOOTED_ANDROID=$(wait_for_running_device "android" 25 || true)
  if [ -n "${BOOTED_ANDROID}" ]; then
    run_flutter_with_device "${BOOTED_ANDROID}"
  fi
  echo -e "${YELLOW}Android emulator startup took too long, trying fallback...${NC}"
else
  echo -e "${YELLOW}No Android emulators configured.${NC}"
fi

# 2. Try iOS
echo -e "${CYAN}→ [2/3] Checking iOS Simulator...${NC}"
RUNNING_IOS=$(query_running_device "ios")
if [ -n "${RUNNING_IOS}" ]; then
  echo -e "${GREEN}✓ Found active iOS Simulator: ${RUNNING_IOS}${NC}"
  run_flutter_with_device "${RUNNING_IOS}"
fi

IOS_EMU=$(get_available_ios_emulator)
if [ -n "${IOS_EMU}" ]; then
  echo -e "${YELLOW}iOS simulator available. Launching...${NC}"
  flutter emulators --launch "${IOS_EMU}" > /dev/null 2>&1 &
  BOOTED_IOS=$(wait_for_running_device "ios" 20 || true)
  if [ -n "${BOOTED_IOS}" ]; then
    run_flutter_with_device "${BOOTED_IOS}"
  fi
  echo -e "${YELLOW}iOS simulator startup took too long, trying fallback...${NC}"
else
  echo -e "${YELLOW}No iOS simulators available.${NC}"
fi

# 3. Fallback to Chrome
echo -e "${CYAN}→ [3/3] Falling back to Web / Google Chrome...${NC}"
run_flutter_chrome

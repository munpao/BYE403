#!/bin/bash

# ============================================================
#  BYE403 — HTTP 403 Bypass Header Fuzzer
#  Author : CoreFlareSec
#  GitHub : https://github.com/YOUR_USERNAME/BYE403
#  Usage  : bash bye403.sh -u URL [options]
# ============================================================

# === COLORS ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# === DEFAULTS ===
TARGET=""
COOKIE=""
WORDLIST="wordlists/403-bypass-clean.txt"
SKIP_CODE="403"
THREADS=4
OUTPUT=""
TIMEOUT=10

# === BANNER ===
banner() {
echo -e "${RED}${BOLD}"
cat << 'EOF'
    ____  __  ______ ___  ____  _____
   / __ )\ \/ / __  / _ \|___ \|__  /
  / __  | \  / /_/ /  __/ ___) | / /
 /_/ /_/  /_/\____/\___/ /____(_)_/

EOF
echo -e "${NC}${CYAN}  HTTP 403 Bypass Header Fuzzer${NC}"
echo -e "${CYAN}  by CoreFlareSec — AI-Augmented ICS Security${NC}"
echo -e "${CYAN}  https://github.com/YOUR_USERNAME/BYE403${NC}"
echo ""
}

# === USAGE ===
usage() {
  banner
  echo -e "${BOLD}Usage:${NC}"
  echo "  bash bye403.sh -u <URL> [options]"
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo "  -u  URL target (required)"
  echo "  -w  wordlist path (default: wordlists/403-bypass-clean.txt)"
  echo "  -c  cookie string"
  echo "  -t  threads 1-10 (default: 4)"
  echo "  -s  skip HTTP code (default: 403)"
  echo "  -o  output file"
  echo "  -T  timeout seconds (default: 10)"
  echo "  -h  show help"
  echo ""
  echo -e "${BOLD}Examples:${NC}"
  echo "  bash bye403.sh -u http://192.168.1.100/admin"
  echo "  bash bye403.sh -u http://192.168.1.100/admin -t 5"
  echo "  bash bye403.sh -u http://192.168.1.100/admin -c 'PHPSESSID=abc123' -t 5 -o out.txt"
  echo "  bash bye403.sh -u http://192.168.1.100:631/admin -t 4"
  exit 0
}

# === PARSE ARGS ===
while getopts "u:w:c:t:s:o:T:h" opt; do
  case $opt in
    u) TARGET="$OPTARG" ;;
    w) WORDLIST="$OPTARG" ;;
    c) COOKIE="$OPTARG" ;;
    t) THREADS="$OPTARG" ;;
    s) SKIP_CODE="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    T) TIMEOUT="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# === VALIDATE ===
banner

if [[ -z "$TARGET" ]]; then
  echo -e "${RED}[!] Error: URL required. Use -u <URL>${NC}"
  echo "    Example: bash bye403.sh -u http://192.168.1.100/admin"
  exit 1
fi

if [[ ! -f "$WORDLIST" ]]; then
  echo -e "${RED}[!] Error: Wordlist not found: $WORDLIST${NC}"
  echo "    Use -w to specify path"
  exit 1
fi

# cap threads
if (( THREADS > 10 )); then THREADS=10; fi
if (( THREADS < 1 )); then THREADS=1; fi

# === TEMP FILES ===
TMPDIR_BASE=$(mktemp -d /tmp/bye403.XXXXXX)
RESULT_FILE="$TMPDIR_BASE/results.txt"
PROGRESS_FILE="$TMPDIR_BASE/progress.txt"
LOCK_FILE="$TMPDIR_BASE/lock"
echo "0" > "$PROGRESS_FILE"
touch "$RESULT_FILE"

# === SPLIT WORDLIST INTO CHUNKS ===
TOTAL=$(grep -c "." "$WORDLIST")
CHUNK_SIZE=$(( (TOTAL + THREADS - 1) / THREADS ))
split -l "$CHUNK_SIZE" "$WORDLIST" "$TMPDIR_BASE/chunk_"
CHUNKS=("$TMPDIR_BASE"/chunk_*)

# === PRINT CONFIG ===
echo -e "${BOLD}┌─────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}│                 Configuration                │${NC}"
echo -e "${BOLD}├─────────────────────────────────────────────┤${NC}"
printf "${BOLD}│${NC}  ${CYAN}%-12s${NC} : %-30s${BOLD}│${NC}\n" "Target"    "$TARGET"
printf "${BOLD}│${NC}  ${CYAN}%-12s${NC} : %-30s${BOLD}│${NC}\n" "Wordlist"  "$(basename $WORDLIST) ($TOTAL headers)"
printf "${BOLD}│${NC}  ${CYAN}%-12s${NC} : %-30s${BOLD}│${NC}\n" "Threads"   "$THREADS"
printf "${BOLD}│${NC}  ${CYAN}%-12s${NC} : %-30s${BOLD}│${NC}\n" "Skip Code" "HTTP $SKIP_CODE"
printf "${BOLD}│${NC}  ${CYAN}%-12s${NC} : %-30s${BOLD}│${NC}\n" "Timeout"   "${TIMEOUT}s/request"
[[ -n "$COOKIE" ]] && \
printf "${BOLD}│${NC}  ${CYAN}%-12s${NC} : %-30s${BOLD}│${NC}\n" "Cookie"    "${COOKIE:0:28}..."
[[ -n "$OUTPUT" ]] && \
printf "${BOLD}│${NC}  ${CYAN}%-12s${NC} : %-30s${BOLD}│${NC}\n" "Output"    "$OUTPUT"
echo -e "${BOLD}└─────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${GREEN}[*] START — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}[*] Splitting into $THREADS chunks (~$CHUNK_SIZE headers each)${NC}"
echo -e "${CYAN}[*] Fuzzing... Press Ctrl+C to stop${NC}"
echo -e "─────────────────────────────────────────────────"

START_TIME=$(date +%s)

# === WORKER FUNCTION ===
worker() {
  local chunk_file="$1"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    # increment counter (with simple lock)
    (
      flock 9
      local n=$(cat "$PROGRESS_FILE")
      echo $((n + 1)) > "$PROGRESS_FILE"
    ) 9>"$LOCK_FILE"

    # build curl args
    local curl_args=(-s -o /dev/null -w "%{http_code}"
      --max-time "$TIMEOUT"
      --connect-timeout 5
      -H "$line")

    [[ -n "$COOKIE" ]] && curl_args+=(-H "Cookie: $COOKIE")

    local code
    code=$(curl "${curl_args[@]}" "$TARGET" 2>/dev/null)

    # hit ถ้าไม่ใช่ skip code
    if [[ "$code" != "$SKIP_CODE" && "$code" =~ ^[0-9]+$ ]]; then
      local msg="[HIT] HTTP $code → $line"
      (
        flock 9
        echo "$msg" >> "$RESULT_FILE"
      ) 9>"$LOCK_FILE"
      echo -e "${GREEN}${BOLD}$msg${NC}"
    fi

  done < "$chunk_file"
}

# === PROGRESS MONITOR ===
monitor() {
  while true; do
    sleep 5
    local done
    done=$(cat "$PROGRESS_FILE" 2>/dev/null || echo 0)
    (( done >= TOTAL )) && break
    local pct=$(( done * 100 / TOTAL ))
    local bar_done=$(( pct / 5 ))
    local bar=""
    for ((i=0; i<bar_done; i++)); do bar+="█"; done
    for ((i=bar_done; i<20; i++)); do bar+="░"; done
    printf "${YELLOW}[~] [%s] %d/%d (%d%%)${NC}\n" "$bar" "$done" "$TOTAL" "$pct" >&2
  done
}
monitor &
MONITOR_PID=$!

# === TRAP Ctrl+C ===
cleanup() {
  echo ""
  echo -e "${YELLOW}[!] Interrupted by user${NC}"
  kill "$MONITOR_PID" 2>/dev/null
  for pid in "${WORKER_PIDS[@]}"; do
    kill "$pid" 2>/dev/null
  done
  rm -rf "$TMPDIR_BASE"
  exit 130
}
trap cleanup INT

# === LAUNCH WORKERS ===
WORKER_PIDS=()
for chunk in "${CHUNKS[@]}"; do
  worker "$chunk" &
  WORKER_PIDS+=($!)
done

# === WAIT ALL ===
for pid in "${WORKER_PIDS[@]}"; do
  wait "$pid" 2>/dev/null
done

kill "$MONITOR_PID" 2>/dev/null
wait "$MONITOR_PID" 2>/dev/null

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
FOUND=$(grep -c "." "$RESULT_FILE" 2>/dev/null || echo 0)

# === FINAL REPORT ===
echo ""
echo -e "─────────────────────────────────────────────────"
echo -e "${GREEN}[*] STOP  — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${CYAN}[*] Elapsed    : ${ELAPSED}s${NC}"
echo -e "${CYAN}[*] Tested     : $TOTAL headers${NC}"
echo -e "${CYAN}[*] Threads    : $THREADS${NC}"

if [[ $FOUND -eq 0 ]]; then
  echo -e "${RED}[!] Bypasses   : 0 found${NC}"
  echo ""
  echo -e "${YELLOW}[?] Tips:${NC}"
  echo "    → ลอง path อื่น (/ , /admin/, /manager)"
  echo "    → ลอง methods: GET, POST, HEAD"
  echo "    → เพิ่ม wordlist หรือ value อื่น"
else
  echo -e "${GREEN}[✓] Bypasses   : $FOUND found!${NC}"
  echo ""
  echo -e "${GREEN}${BOLD}──── RESULTS ────${NC}"
  cat "$RESULT_FILE"
  echo -e "${GREEN}${BOLD}─────────────────${NC}"
  echo ""
  echo -e "${GREEN}[✓] ลอง header ด้านบนใน Burp Repeater${NC}"
fi

# === SAVE OUTPUT ===
if [[ -n "$OUTPUT" ]]; then
  {
    echo "# BYE403 Results"
    echo "# Target  : $TARGET"
    echo "# Date    : $(date)"
    echo "# Threads : $THREADS"
    echo "# Elapsed : ${ELAPSED}s"
    echo "# Found   : $FOUND"
    echo ""
    cat "$RESULT_FILE"
  } > "$OUTPUT"
  echo -e "${CYAN}[*] Saved to   : $OUTPUT${NC}"
fi

# === CLEANUP ===
rm -rf "$TMPDIR_BASE"
echo ""

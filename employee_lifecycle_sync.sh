#!/usr/bin/env bash
set -euo pipefail

INPUT="${1:-}"
OUTPUT_DIR="./output"
TMP_DIR="${OUTPUT_DIR}/tmp"
SNAPSHOT="${OUTPUT_DIR}/last_employees.csv"

if [[ -z "$INPUT" ]]; then
  echo "Usage: $0 <path/to/employees.csv>"
  exit 1
fi

mkdir -p "$TMP_DIR"

CURRENT_USERS="${TMP_DIR}/current_users.txt"
SNAPSHOT_USERS="${TMP_DIR}/snapshot_users.txt"
ADDED="${TMP_DIR}/added.txt"
REMOVED="${TMP_DIR}/removed.txt"
TERMINATED="${TMP_DIR}/terminated.txt"

# 1) current_users.txt (username list, sorted)
tail -n +2 "$INPUT" \
  | awk -F',' 'NF>=5 {gsub(/\r/,""); print $2}' \
  | sed '/^[[:space:]]*$/d' \
  | sort -u > "$CURRENT_USERS"

# 2) snapshot_users.txt (if snapshot missing -> empty file)
if [[ -f "$SNAPSHOT" ]]; then
  tail -n +2 "$SNAPSHOT" \
    | awk -F',' 'NF>=5 {gsub(/\r/,""); print $2}' \
    | sed '/^[[:space:]]*$/d' \
    | sort -u > "$SNAPSHOT_USERS"
else
  : > "$SNAPSHOT_USERS"
fi

# 3) added.txt (in current, not in snapshot)
comm -23 "$CURRENT_USERS" "$SNAPSHOT_USERS" > "$ADDED"

# 4) removed.txt (in snapshot, not in current)
comm -13 "$CURRENT_USERS" "$SNAPSHOT_USERS" > "$REMOVED"

# 5) terminated.txt (status=terminated in current)
tail -n +2 "$INPUT" \
  | awk -F',' 'NF>=5 {gsub(/\r/,""); if (tolower($5)=="terminated") print $2}' \
  | sed '/^[[:space:]]*$/d' \
  | sort -u > "$TERMINATED"

echo "Generated:"
echo " - $CURRENT_USERS"
echo " - $SNAPSHOT_USERS"
echo " - $ADDED"
echo " - $REMOVED"
echo " - $TERMINATED"

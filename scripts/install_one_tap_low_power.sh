#!/bin/bash
set -euo pipefail

RULE_PATH="/etc/sudoers.d/notchclick-pmset"
TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/notchclick-pmset.XXXXXX")"
USERNAME="$(id -un)"

cleanup() {
  rm -f "$TMP_FILE"
}
trap cleanup EXIT

cat >"$TMP_FILE" <<EOF
# Installed by NotchClick — grants passwordless Low Power Mode toggling.
# Remove this file to revoke: sudo rm -f $RULE_PATH
$USERNAME ALL=(root) NOPASSWD: /usr/bin/pmset -a lowpowermode 0
$USERNAME ALL=(root) NOPASSWD: /usr/bin/pmset -a lowpowermode 1
EOF

/usr/sbin/visudo -cf "$TMP_FILE"
/usr/sbin/chown root:wheel "$TMP_FILE"
/bin/chmod 440 "$TMP_FILE"
/bin/mv "$TMP_FILE" "$RULE_PATH"

echo "Installed $RULE_PATH"
echo "NotchClick can now toggle Low Power Mode without repeated password prompts on this Mac."

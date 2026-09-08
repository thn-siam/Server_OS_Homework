#!/bin/bash
# ============================================================
#  DHCP Lab - Submission Collector  (runs in KillerCoda terminal)
#  Usage:  bash submit_dhcp.sh <YOUR_STUDENT_ID> <YOUR_GITHUB_REPO_URL>
#  Example: bash submit_dhcp.sh 6412345 https://github.com/you/os-labs.git
# ============================================================
set -e
SID="$1"
REPO="$2"
if [ -z "$SID" ] || [ -z "$REPO" ]; then
  echo "Usage: bash submit_dhcp.sh <STUDENT_ID> <GITHUB_REPO_URL>"
  exit 1
fi

OUT="dhcp_submission_${SID}.txt"
CONF="/etc/dhcp/dhcpd.conf"

{
  echo "===BEGIN DHCP SUBMISSION==="
  echo "student_id: ${SID}"
  echo "timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "hostname: $(hostname)"
  echo "---[dhcpd.conf]---"
  if [ -f "$CONF" ]; then cat "$CONF"; else echo "(MISSING: $CONF not found)"; fi
  echo "---[config syntax test: dhcpd -t]---"
  # capture real validator output (stderr+stdout); don't abort if it fails
  dhcpd -t -cf "$CONF" 2>&1 || true
  echo "---[service status]---"
  systemctl is-active isc-dhcp-server 2>/dev/null || systemctl is-active dhcpd 2>/dev/null || echo "inactive/unknown"
  echo "---[integrity]---"
  echo "conf_sha256: $( [ -f "$CONF" ] && sha256sum "$CONF" | awk '{print $1}' || echo none )"
  echo "===END DHCP SUBMISSION==="
} > "$OUT"

echo "Wrote $OUT"
echo "Pushing to GitHub..."

WORK=$(mktemp -d)
git clone --depth 1 "$REPO" "$WORK/repo" 2>/dev/null || { echo "Clone failed - check repo URL and that it exists"; exit 1; }
mkdir -p "$WORK/repo/dhcp"
cp "$OUT" "$WORK/repo/dhcp/"
cd "$WORK/repo"
git config user.email "student@lab.local"
git config user.name "$SID"
git add "dhcp/$OUT"
git commit -m "DHCP lab submission: $SID" >/dev/null 2>&1 || { echo "Nothing to commit"; }
if git push 2>/dev/null; then
  echo "SUCCESS: submission pushed to your repo under dhcp/$OUT"
else
  echo "PUSH FAILED. You can instead copy the block below and send it to the instructor:"
  echo "--------------------------------------------------------"
  cat "$OLDPWD/$OUT"
fi


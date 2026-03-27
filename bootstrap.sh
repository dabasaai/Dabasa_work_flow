#!/usr/bin/env bash
set -euo pipefail

# 輕量引導腳本：下載 setup.sh 到本地再執行，確保 stdin 可互動
SETUP_URL="https://raw.githubusercontent.com/dabasaai/Dabasa_work_flow/main/setup.sh"
TMP_SCRIPT="$(mktemp /tmp/dabasa_setup.XXXXXX.sh)"

echo "下載部署腳本..."
curl -fsSL "$SETUP_URL" -o "$TMP_SCRIPT"
chmod +x "$TMP_SCRIPT"

echo "開始部署..."
echo ""
bash "$TMP_SCRIPT"

rm -f "$TMP_SCRIPT"

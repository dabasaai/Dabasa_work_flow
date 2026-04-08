#!/usr/bin/env bash
set -euo pipefail

echo "=== Dabasa 新設備一鍵部署 ==="
echo ""

# ---------- 1. 基本工具檢查 ----------
check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo "❌ 未找到 $1，正在安裝..."
    return 1
  else
    echo "✅ $1 已安裝"
    return 0
  fi
}

ensure_path() {
  local dir="$1"
  PATH_LINE="export PATH=\"$dir:\$PATH\""
  for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc_file" ]] && ! grep -qF "$dir" "$rc_file"; then
      echo "" >> "$rc_file"
      echo "$PATH_LINE" >> "$rc_file"
      echo "  已將 $dir 加入 $rc_file"
    fi
  done
  export PATH="$dir:$PATH"
}

INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"
WORK_DIR="$HOME/Developer/Dabasa_work_flow"
mkdir -p "$WORK_DIR"

# 安裝 Homebrew（macOS）
if [[ "$(uname)" == "Darwin" ]]; then
  if ! check_cmd brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

# 安裝 gh CLI
if ! check_cmd gh; then
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install gh
  elif command -v apt &>/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update && sudo apt install -y gh
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y gh
  else
    echo "❌ 無法自動安裝 gh，請手動安裝: https://cli.github.com/"
    exit 1
  fi
fi

# 安裝 jq（claudehook-notion 需要）
if ! check_cmd jq; then
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install jq
  elif command -v apt &>/dev/null; then
    sudo apt install -y jq
  fi
fi

# 安裝 screen
if ! check_cmd screen; then
  if [[ "$(uname)" == "Darwin" ]]; then
    brew install screen
  elif command -v apt &>/dev/null; then
    sudo apt install -y screen
  fi
fi

# ---------- 2. GitHub 認證（互動式） ----------
echo ""
echo "--- GitHub 認證 ---"
if gh auth status &>/dev/null; then
  echo "✅ 已登入 GitHub"
else
  echo "開始 GitHub 登入..."
  gh auth login
fi
gh auth setup-git
echo "✅ Git 認證已設定"

# ---------- 3. gm (github_menu) ----------
echo ""
echo "--- 安裝 gm ---"
echo "下載最新版 gm..."
curl -fsSL https://raw.githubusercontent.com/dabasaai/github_menu/main/github_menu.py -o "$INSTALL_DIR/gm"
chmod +x "$INSTALL_DIR/gm"
ensure_path "$INSTALL_DIR"
echo "✅ gm 已安裝（最新版）"

# ---------- 4. claude-here ----------
echo ""
echo "--- 部署 claude-here ---"
cd "$WORK_DIR"
if [[ -d "claude-here" ]]; then
  echo "更新中..."
  cd claude-here && git pull && cd ..
else
  gh repo clone dabasaai/claude-here
fi
cd claude-here && bash install.sh && cd "$WORK_DIR"
echo "✅ claude-here 已安裝"

# ---------- 5. telegram_notify ----------
echo ""
echo "--- 部署 telegram_notify ---"
cd "$WORK_DIR"
if [[ -d "telegram_notify" ]]; then
  echo "更新中..."
  cd telegram_notify && git pull && cd "$WORK_DIR"
else
  gh repo clone dabasaai/telegram_notify
fi
cd telegram_notify && bash install.sh && cd "$WORK_DIR"
echo "✅ tg-notify 已安裝"

# 提醒設定 .env
if [[ ! -f "$HOME/.telegram_notify.env" ]] && [[ ! -f "$WORK_DIR/telegram_notify/.env" ]]; then
  echo ""
  echo "  ⚠ 記得設定 Telegram 環境變數："
  echo "    TELEGRAM_BOT_TOKEN=你的bot_token"
  echo "    TELEGRAM_CHAT_ID=你的chat_id"
  echo "    （寫入 ~/.bashrc 或 .env 檔案）"
fi

# ---------- 6. claudehook-notion ----------
echo ""
echo "--- 部署 claudehook-notion ---"
cd "$WORK_DIR"
if [[ -d "claudehook-notion" ]]; then
  echo "更新中..."
  cd claudehook-notion && git pull && cd "$WORK_DIR"
else
  gh repo clone dabasaai/claudehook-notion
fi
cd claudehook-notion && bash deploy.sh && cd "$WORK_DIR"
echo "✅ claudehook-notion 已安裝"

# ---------- 7. Claude Code CLI ----------
echo ""
echo "--- Claude Code ---"
if command -v claude &>/dev/null; then
  echo "✅ claude 已安裝"
else
  echo "安裝 Claude Code..."
  if command -v npm &>/dev/null; then
    npm install -g @anthropic-ai/claude-code
  else
    echo "⚠ 未找到 npm，請先安裝 Node.js 再手動執行："
    echo "  npm install -g @anthropic-ai/claude-code"
  fi
fi

# ---------- 完成 ----------
echo ""
echo "========================================="
echo "  ✅ 全部部署完成！"
echo "========================================="
echo ""
echo "  已安裝工具："
echo "    gm           — GitHub 專案選擇器"
echo "    claude-here   — 在專案目錄啟動 Claude"
echo "    tg-notify     — Telegram 通知"
echo "    claudehook    — Claude Code → Notion 任務記錄"
echo "    claude        — Claude Code CLI"
echo ""
echo "  如果是新終端，請先執行："
echo "    source ~/.bashrc  # 或 source ~/.zshrc"
echo ""

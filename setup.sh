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

# ---------- 3. 安裝/更新 gm (github_menu) ----------
echo ""
echo "--- 安裝 gm ---"
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

echo "下載最新版 gm..."
curl -fsSL https://raw.githubusercontent.com/dabasaai/github_menu/main/github_menu.py -o "$INSTALL_DIR/gm"
chmod +x "$INSTALL_DIR/gm"

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
  if [[ -f "$rc_file" ]] && ! grep -qF '.local/bin' "$rc_file"; then
    echo "" >> "$rc_file"
    echo "# gm (github_menu)" >> "$rc_file"
    echo "$PATH_LINE" >> "$rc_file"
    echo "已將 PATH 加入 $rc_file"
  fi
done
export PATH="$INSTALL_DIR:$PATH"
echo "✅ gm 已安裝（最新版）"

# ---------- 4. 建立工作目錄並部署 claude-here ----------
echo ""
echo "--- 部署 claude-here ---"
WORK_DIR="$HOME/Developer/Dabasa_work_flow"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if [[ -d "claude-here" ]]; then
  echo "✅ claude-here 已存在，更新中..."
  cd claude-here && git pull && cd ..
else
  gh repo clone dabasaai/claude-here
fi

cd claude-here
bash install.sh
cd "$WORK_DIR"

# ---------- 5. 安裝 Claude Code CLI ----------
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
echo "  ✅ 部署完成！"
echo "========================================="
echo ""
echo "  使用方式："
echo "    gm          — 選擇/clone GitHub 專案"
echo "    claude-here  — 在專案目錄啟動 Claude"
echo ""
echo "  如果是新終端，請先執行："
echo "    source ~/.bashrc  # 或 source ~/.zshrc"
echo ""

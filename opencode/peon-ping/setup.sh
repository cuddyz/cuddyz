#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Peon Ping + Zelda Mix Setup ==="
echo ""

# --- 1. Install peon-ping ---
if command -v peon &>/dev/null; then
  echo "[OK] peon-ping already installed"
else
  echo "[*] Installing peon-ping..."
  if command -v brew &>/dev/null; then
    brew install PeonPing/tap/peon-ping
  else
    curl -fsSL https://raw.githubusercontent.com/PeonPing/peon-ping/main/install.sh | bash
  fi
fi

# --- 2. Run peon-ping-setup (detects IDEs, installs default packs) ---
echo ""
echo "[*] Running peon-ping-setup..."
peon-ping-setup

# --- 3. Build zelda-mix pack (download sounds from source repos) ---
PACK_DIR="$HOME/.openpeon/packs/zelda-mix"
SOUNDS_DIR="$PACK_DIR/sounds"
mkdir -p "$SOUNDS_DIR"

cp "$SCRIPT_DIR/zelda-mix/openpeon.json" "$PACK_DIR/openpeon.json"

echo ""
echo "[*] Downloading Zelda sound files..."
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

git clone --depth 1 https://github.com/PeonPing/og-packs.git "$TMP_DIR/og-packs"
git clone --depth 1 https://github.com/hrokling/zelda-a-link-to-the-past.git "$TMP_DIR/lttp"

OOT="$TMP_DIR/og-packs/ocarina_of_time/sounds"
LTTP="$TMP_DIR/lttp/sounds"

cp "$OOT/OOT_Navi_Hello1.wav"    "$SOUNDS_DIR/"
cp "$OOT/OOT_Navi_Hey1.wav"      "$SOUNDS_DIR/"
cp "$OOT/OOT_6amRooster.wav"     "$SOUNDS_DIR/"
cp "$OOT/OOT_Fairy.wav"          "$SOUNDS_DIR/"
cp "$OOT/OOT_Secret.wav"         "$SOUNDS_DIR/"
cp "$OOT/OOT_Navi_WatchOut1.wav" "$SOUNDS_DIR/"
cp "$OOT/OOT_Navi_Look1.wav"     "$SOUNDS_DIR/"
cp "$OOT/OOT_Navi_Listen1.wav"   "$SOUNDS_DIR/"
cp "$OOT/OOT_Dialogue_No.wav"    "$SOUNDS_DIR/"

cp "$LTTP/select_screen_start.wav"        "$SOUNDS_DIR/"
cp "$LTTP/triforce_chamber_start.wav"     "$SOUNDS_DIR/"
cp "$LTTP/crystal_start.wav"              "$SOUNDS_DIR/"
cp "$LTTP/the_goddess_appears_start.wav"  "$SOUNDS_DIR/"
cp "$LTTP/item_get_1.wav"                 "$SOUNDS_DIR/"
cp "$LTTP/boss_clear_fanfare.wav"         "$SOUNDS_DIR/"
cp "$LTTP/guessing_game_house_start.wav"  "$SOUNDS_DIR/"
cp "$LTTP/secret.wav"                     "$SOUNDS_DIR/"
cp "$LTTP/church_start.wav"               "$SOUNDS_DIR/"
cp "$LTTP/link_falls.wav"                 "$SOUNDS_DIR/"
cp "$LTTP/low_hp.wav"                     "$SOUNDS_DIR/"
cp "$LTTP/cucco.wav"                      "$SOUNDS_DIR/"

echo "[OK] 21 sound files installed to $SOUNDS_DIR"

# --- 4. Activate zelda-mix ---
echo ""
echo "[*] Activating zelda-mix pack..."
peon packs use zelda-mix

# --- 5. Set OpenCode config to use zelda-mix ---
OPENCODE_PEON_DIR="$HOME/.config/opencode/peon-ping"
if [ -d "$HOME/.config/opencode" ]; then
  mkdir -p "$OPENCODE_PEON_DIR"
  cp "$SCRIPT_DIR/opencode-config.json" "$OPENCODE_PEON_DIR/config.json"
  echo "[OK] OpenCode peon-ping config set to zelda-mix"
else
  echo "[SKIP] OpenCode config dir not found — install OpenCode first, then re-run"
fi

echo ""
echo "=== Done! Restart OpenCode and enjoy your Zelda sounds ==="

#!/bin/bash
set -e

BINARY_NAME="GeminiChecker"
INSTALL_DIR="$HOME/.local/bin"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="com.geminichecker.plist"

echo "=== GeminiChecker Deinstallation ==="
echo ""

# 1. LaunchAgent entladen
echo "[1/3] Entlade LaunchAgent..."
launchctl bootout "gui/$(id -u)/com.geminichecker" 2>/dev/null || true
echo "      LaunchAgent entladen."

# 2. LaunchAgent-Plist loeschen
echo "[2/3] Loesche LaunchAgent-Plist..."
rm -f "$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_PLIST"
echo "      $LAUNCH_AGENT_DIR/$LAUNCH_AGENT_PLIST entfernt."

# 3. Binary loeschen
echo "[3/3] Loesche Binary..."
rm -f "$INSTALL_DIR/$BINARY_NAME"
echo "      $INSTALL_DIR/$BINARY_NAME entfernt."

echo ""
echo "=== Deinstallation abgeschlossen ==="
echo "GeminiChecker wurde vollständig entfernt."

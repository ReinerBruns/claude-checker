#!/bin/bash
set -e

BINARY_NAME="ClaudeChecker"
INSTALL_DIR="$HOME/.local/bin"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="com.claudechecker.plist"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== ClaudeChecker Installer ==="
echo ""

# 1. Release Build
echo "[1/4] Baue Release-Version..."
cd "$SCRIPT_DIR"
swift build -c release
echo "      Build erfolgreich."

# 2. Binary kopieren
echo "[2/4] Kopiere Binary nach $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
cp -f ".build/release/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"
echo "      $INSTALL_DIR/$BINARY_NAME installiert."

# 3. LaunchAgent erstellen
echo "[3/4] Erstelle LaunchAgent..."
mkdir -p "$LAUNCH_AGENT_DIR"
cat > "$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claudechecker</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_DIR/$BINARY_NAME</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF
echo "      $LAUNCH_AGENT_DIR/$LAUNCH_AGENT_PLIST erstellt."

# 4. LaunchAgent laden
echo "[4/4] Registriere LaunchAgent..."
# Erst entladen, falls bereits geladen
launchctl bootout "gui/$(id -u)/com.claudechecker" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT_DIR/$LAUNCH_AGENT_PLIST"
echo "      LaunchAgent registriert."

echo ""
echo "=== Installation abgeschlossen ==="
echo "ClaudeChecker startet jetzt automatisch bei der Anmeldung."
echo "Zum sofortigen Starten: $INSTALL_DIR/$BINARY_NAME &"
echo "Zum Deinstallieren:     ./uninstall.sh"

# ClaudeChecker

Eine native macOS MenuBar-App, die deine **claude.ai Plan-Nutzungslimits** in Echtzeit anzeigt – genau wie auf der claude.ai-Website.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Was wird angezeigt?

- **Current Session** (innerer Balken): 5-Stunden-Nutzungsfenster mit Reset-Countdown
- **Woechentliche Limits** (aeusserer Balken): 7-Tage-Gesamtnutzung ueber alle Modelle
- **Farbskala**: Gruen (<50%), Gelb (50-75%), Rot (>75%)

Klick auf den Balken oeffnet ein Popover mit Details, Reset-Zeiten und Aktionen.

## Installation

### Voraussetzungen

- macOS 13 (Ventura) oder neuer
- Swift 5.9+ (mit Xcode Command Line Tools: `xcode-select --install`)
- Ein aktiver claude.ai Account (Pro/Max)

### Bauen

```bash
git clone https://github.com/ReinerBruns/claude-checker.git
cd claude-checker
swift build -c release
```

Die fertige Binary liegt unter `.build/release/ClaudeChecker`.

## Einrichtung (Session-Key)

Die App benoetigt deinen **Session-Key** von claude.ai (nicht den API-Key!).

### Session-Key finden

1. Oeffne [claude.ai](https://claude.ai) im Browser und logge dich ein
2. Oeffne die **DevTools** (F12 oder Cmd+Option+I)
3. Gehe zu **Application** → **Cookies** → `https://claude.ai`
4. Kopiere den Wert von **`sessionKey`** (beginnt mit `sk-ant-sid01-...`)

### Session-Key speichern

**Variante A – Ueber die App:** Beim ersten Start oeffnet sich ein Setup-Fenster. Dort den Key einfuegen und "Speichern" klicken.

**Variante B – Ueber das Terminal** (falls Paste im UI nicht funktioniert):

```bash
security add-generic-password \
  -s "com.claudechecker.apikey" \
  -a "anthropic-api-key" \
  -w "sk-ant-sid01-DEIN_KEY_HIER" \
  -U
```

Der Key wird sicher im macOS Keychain gespeichert.

### Session-Key aktualisieren

Der Session-Key laeuft nach einiger Zeit ab. Wenn die App "Session abgelaufen" anzeigt:

1. Neuen Key aus dem Browser holen (wie oben)
2. Per Terminal aktualisieren:

```bash
security add-generic-password \
  -s "com.claudechecker.apikey" \
  -a "anthropic-api-key" \
  -w "sk-ant-sid01-NEUER_KEY_HIER" \
  -U
```

3. App neu starten oder im Popover "Aktualisieren" klicken

## App starten

### Manuell starten

```bash
# Debug-Version
swift build && .build/debug/ClaudeChecker

# Release-Version (empfohlen)
swift build -c release && .build/release/ClaudeChecker
```

### Nach Rechner-Neustart

Die App startet nicht automatisch. Optionen:

**Option 1 – Shell-Alias** (einfachste Loesung):

In `~/.zshrc` oder `~/.bash_profile` hinzufuegen:

```bash
alias claudechecker='/Users/DEIN_USER/src/claude-checker/.build/release/ClaudeChecker &'
```

Dann einfach `claudechecker` im Terminal eingeben.

**Option 2 – macOS Login-Item** (automatisch bei Anmeldung):

1. Release bauen: `swift build -c release`
2. Binary an festen Ort kopieren: `cp .build/release/ClaudeChecker /usr/local/bin/`
3. System Settings → General → Login Items → "+" → `/usr/local/bin/ClaudeChecker` hinzufuegen

**Option 3 – LaunchAgent** (professionellste Loesung):

Datei `~/Library/LaunchAgents/com.claudechecker.plist` erstellen:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claudechecker</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/ClaudeChecker</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
```

Aktivieren:

```bash
cp .build/release/ClaudeChecker /usr/local/bin/
launchctl load ~/Library/LaunchAgents/com.claudechecker.plist
```

## Aktualisierungsintervall

- **Standard**: Alle **5 Minuten** (300 Sekunden)
- Manuell ueber das Popover jederzeit moeglich ("Aktualisieren"-Button)
- Aenderbar in `AppDelegate.swift` (`pollingInterval`)

## Kosten

**Keine.** Die App nutzt die interne claude.ai Web-API (gleicher Endpoint wie die claude.ai-Website selbst). Es werden keine Anthropic-API-Tokens verbraucht. Es entstehen keinerlei Kosten – weder pro Aufruf noch taeglich, woechentlich oder monatlich.

| Zeitraum | Kosten |
|----------|--------|
| Pro Abfrage | 0,00 $ |
| Pro Tag | 0,00 $ |
| Pro Woche | 0,00 $ |
| Pro Monat | 0,00 $ |

## App beenden

- Ueber das Popover: Klick auf den Balken → "Beenden"-Button
- Oder im Terminal: `pkill ClaudeChecker`

## Sicherheit

- Der Session-Key wird ausschliesslich im **macOS Keychain** gespeichert (verschluesselt)
- Keine Daten werden an Dritte gesendet
- Die App kommuniziert nur mit `claude.ai` (HTTPS)
- Es werden nur Nutzungsstatistiken gelesen – kein Zugriff auf Konversationen

## Projektstruktur

```
Sources/ClaudeChecker/
  main.swift                   App-Bootstrap (.accessory, kein Dock-Icon)
  AppDelegate.swift            Lifecycle, Polling-Timer, Setup-Fenster
  StatusBarController.swift    MenuBar-Item + Popover-Steuerung
  ProgressBarView.swift        Custom NSView mit zwei ueberlagerten Balken
  DropdownView.swift           SwiftUI-Detailansicht im Popover
  DropdownViewController.swift SwiftUI-zu-AppKit Bridge
  AnthropicAPIService.swift    claude.ai Web-API Kommunikation
  RateLimitData.swift          Datenmodell (Session + Weekly Usage)
  KeychainHelper.swift         Sichere Key-Speicherung
  SetupView.swift              Ersteinrichtung / Key-Eingabe
```

## Troubleshooting

| Problem | Loesung |
|---------|---------|
| "CC?" in der MenuBar | Kein Session-Key hinterlegt → Setup ausfuehren |
| "Session abgelaufen" | Neuen Session-Key aus dem Browser holen |
| Balken zeigt 0/0% | Auf "Aktualisieren" im Popover klicken |
| App nicht in MenuBar sichtbar | Terminal pruefen ob Prozess laeuft: `pgrep ClaudeChecker` |

## Hinweis

Diese App nutzt die interne, nicht-dokumentierte Web-API von claude.ai. Sie ist nicht von Anthropic autorisiert oder unterstuetzt. Nutzung auf eigenes Risiko. Die API-Endpunkte koennten sich ohne Vorwarnung aendern.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Debug build + run
swift build && .build/debug/ClaudeChecker

# Release build
swift build -c release && .build/release/ClaudeChecker
```

Keine externen Dependencies – nur System-Frameworks (Cocoa, SwiftUI, Security).

Swift Package mit `swift-tools-version:5.9`, Zielplattform macOS 13+.

Es gibt keine Tests. Verifikation erfolgt manuell durch Starten der App.

## Architektur

macOS MenuBar-App (Accessory-App ohne Dock-Icon), die **claude.ai Plan-Nutzungslimits** (Session + Woechentlich) ueber die interne claude.ai Web-API anzeigt.

### Datenfluss

```
AppDelegate (Orchestrator, Polling-Timer 5min)
    │
    ├── ClaudeWebAPIService
    │     ├── GET claude.ai/api/organizations → Org-ID holen (einmalig, gecacht)
    │     └── GET claude.ai/api/organizations/{id}/usage → Session + Weekly Usage
    │
    └── StatusBarController
            ├── ProgressBarView (NSView, Custom draw())
            │     ├── Aeusserer Balken: Weekly Usage (7-Tage)
            │     └── Innerer Balken: Session Usage (5-Stunden)
            └── NSPopover → DropdownViewController → DropdownView (SwiftUI)
```

### Authentifizierung

Die App nutzt den **Session-Cookie** von claude.ai (nicht den Anthropic API-Key). Gespeichert im macOS Keychain unter `com.claudechecker.apikey` / `anthropic-api-key`. Auth-Header: `Cookie: sessionKey=sk-ant-sid01-...`.

### API-Antwortformat

Der `/usage`-Endpoint liefert JSON mit `five_hour` (Session) und `seven_day` (Weekly), jeweils mit `utilization` (Prozentzahl 0-100) und `resets_at` (ISO 8601 Datum).

### Zentrale Patterns

- **UI-Hybrid**: AppKit fuer MenuBar (NSStatusItem, NSPopover), Custom NSView fuer Fortschrittsbalken, SwiftUI fuer Popover-Inhalte und Setup-Dialog. Bridging via `NSHostingView`.
- **State-Management**: Gesamter State in `AppDelegate`. Kein Reactive-Framework – direkte Methodenaufrufe.
- **Org-ID Caching**: Wird einmalig beim ersten API-Call geholt und im Service gecacht.

### Farblogik der Fortschrittsbalken

Nutzung: <50% Gruen, 50-75% Gelb/Orange, >75% Rot. Aeusserer Balken (Weekly) dunkler, innerer (Session) heller.

## Sprache

UI-Texte und Fehlermeldungen sind auf Deutsch.

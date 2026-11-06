# GeminiChecker

Native macOS-Menüleisten-App zur Echtzeit-Überwachung der Nutzungslimits von **Google Gemini & Antigravity** im **Apple-Watch-Aktivitätsringe-Design**:
- **Ring 1 (`G` – Gemini Models)** – Außenring = Wochenkontingent, Innenring = 5-Stunden-Sitzung
- **Ring 2 (`A` – Gemini 4 Argon)** – Außenring = Wochenkontingent (kein innerer 5h-Ring)
- **Ring 3 (`C` – Claude and GPT models)** – Außenring = Wochenkontingent, Innenring = 5-Stunden-Sitzung

## Features

- **3 konzentrische Apple-Watch-Ringe (Gauges) nebeneinander** in der macOS-Menüleiste mit `G`, `A`, `C` und **integrierter Reset-Uhr (Ozean-Blau)** im Zentrum:
  - **Ring `G` (links)**: Gemini Models (Außenring = Wochenkontingent, Innenring = 5h-Sitzung, blaue Uhr innen = verstrichene Zeit bis zum 5h-Reset)
  - **Ring `A` (Mitte)**: Gemini 4 Argon (Außenring = Wochenkontingent, blaue Uhr innen = verstrichene Zeit bis zum Wochen-Reset)
  - **Ring `C` (rechts)**: Claude & GPT Models (Außenring = Wochenkontingent, Innenring = 5h-Sitzung, blaue Uhr innen = verstrichene Zeit bis zum 5h-Reset)
- **Dynamischer Farbwechsel**:
  - `< 50 %` verwendet: **Grün**
  - `50 % - 75 %` verwendet: **Orange**
  - `> 75 %` verwendet: **Rot**
- **Detail-Ansicht (Popover bei Klick)**:
  - Vollständige Aufschlüsselung aller Kontingente (Gemini Modelle, Gemini 4 Argon, Claude & GPT Modelle)
  - Genaue Prozentangaben & farbige Verlaufsbalken
  - Exakte Rücksetzzeiten (z. B. *"Zurücksetzung in 3 Std. 54 Min."* bzw. *"Zurücksetzung Fr. 22:35"*)
  - Account-Informationen (E-Mail & aktiver Google AI Plan)
  - Dreh-Animation beim Aktualisieren
  - Einstellungsdialog & Beenden-Button
- **Zero-Config Authentifizierung**:
  - Nutzt automatisch das existierende macOS Keychain Token von Antigravity (`service: gemini, account: antigravity`)
  - Automatische Abfrage und Token-Refresh über `agy --output-format json -p "/usage"` mit Fallback auf die direkte Google Cloud Code REST API.

## Build & Ausführung

```bash
cd GeminiChecker

# Debug-Build testen
swift build && .build/debug/GeminiChecker

# Release-Build erstellen
swift build -c release
```

## Installation als Autostart-App

```bash
cd GeminiChecker
./install.sh
```

Installiert die Release-Version nach `~/.local/bin/GeminiChecker` und richtet den LaunchAgent `com.geminichecker.plist` ein.

## Deinstallation

```bash
cd GeminiChecker
./uninstall.sh
```

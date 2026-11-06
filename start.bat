# Startbefehle

## Programm im Hintergrund starten, entkoppelt vom Terminal
nohup .build/debug/ClaudeChecker > /dev/null 2>&1 &

## Entkoppeltes Programm im Hintergrund beenden
pkill ClaudeChecker

## Der "offizielle" Weg für dieses Projekt
Da das Projekt eine macOS-App ist, empfiehlt sich das mitgelieferte Installationsskript. Es sorgt dafür, dass die App im Hintergrund läuft und bei jedem Systemstart automatisch lädt:
./install.sh
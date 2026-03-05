import SwiftUI
import AppKit

struct SetupView: View {
    @State private var sessionKey: String = ""
    @State private var isValidating: Bool = false
    @State private var errorMessage: String?
    @State private var showKey: Bool = true

    let onComplete: (String) -> Void
    let onCancel: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("ClaudeChecker Setup")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 4) {
                Text("Session-Key von claude.ai eingeben:")
                    .font(.body)
                    .fontWeight(.medium)

                Text("Browser → claude.ai → DevTools (F12)\n→ Application → Cookies → sessionKey")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack {
                if showKey {
                    TextField("sk-ant-sid01-...", text: $sessionKey)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField("sk-ant-sid01-...", text: $sessionKey)
                        .textFieldStyle(.roundedBorder)
                }

                Button(action: { showKey.toggle() }) {
                    Image(systemName: showKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
                .help(showKey ? "Key verbergen" : "Key anzeigen")
            }
            .frame(width: 400)

            HStack(spacing: 8) {
                Button(action: pasteFromClipboard) {
                    Label("Aus Zwischenablage einfuegen", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)

                if !sessionKey.isEmpty {
                    Text("\(sessionKey.count) Zeichen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                if let cancel = onCancel {
                    Button("Abbrechen") {
                        cancel()
                    }
                    .keyboardShortcut(.cancelAction)
                }

                Button(action: validateAndSave) {
                    if isValidating {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.trailing, 4)
                    }
                    Text(isValidating ? "Validiere..." : "Speichern")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(sessionKey.isEmpty || isValidating)
            }
        }
        .padding(24)
        .frame(width: 480)
        .onAppear {
            autoFillFromClipboard()
        }
    }

    private func pasteFromClipboard() {
        if let text = NSPasteboard.general.string(forType: .string) {
            sessionKey = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func autoFillFromClipboard() {
        if let text = NSPasteboard.general.string(forType: .string) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("sk-ant-") {
                sessionKey = trimmed
            }
        }
    }

    private func validateAndSave() {
        isValidating = true
        errorMessage = nil

        Task {
            let service = ClaudeWebAPIService(sessionKey: sessionKey)
            do {
                let valid = try await service.validateSessionKey(sessionKey)
                await MainActor.run {
                    isValidating = false
                    if valid {
                        let _ = KeychainHelper.save(apiKey: sessionKey)
                        onComplete(sessionKey)
                    } else {
                        errorMessage = "Session-Key ist ungueltig oder abgelaufen."
                    }
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    errorMessage = "Fehler: \(error.localizedDescription)"
                }
            }
        }
    }
}

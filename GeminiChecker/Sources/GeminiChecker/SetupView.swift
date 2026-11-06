import SwiftUI
import AppKit

struct SetupView: View {
    @State private var email: String = ""
    @State private var isConnected: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: String?
    @State private var pollingMinutes: Int = 5

    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            Text("GeminiChecker Einstellungen")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 10) {
                // Status Box
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: isConnected ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(isConnected ? .green : .orange)
                        .imageScale(.large)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isConnected ? "Antigravity Anmeldung aktiv" : "Keine Anmeldung gefunden")
                            .font(.body)
                            .fontWeight(.medium)

                        if !email.isEmpty {
                            Text("Konto: \(email)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Führe 'agy' im Terminal aus, um dich anzumelden.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Polling Interval
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aktualisierungsintervall:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("", selection: $pollingMinutes) {
                        Text("Jede Minute").tag(1)
                        Text("Alle 2 Minuten").tag(2)
                        Text("Alle 5 Minuten (Standard)").tag(5)
                        Text("Alle 10 Minuten").tag(10)
                    }
                    .pickerStyle(.menu)
                }

                if let result = testResult {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(result.contains("Erfolgreich") ? .green : .red)
                }
            }
            .frame(width: 360)

            HStack {
                Button("Verbindung testen") {
                    testConnection()
                }
                .disabled(isTesting)

                Spacer()

                Button("Abbrechen", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Fertig", action: onSave)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
            .frame(width: 360)
        }
        .padding(20)
        .frame(width: 400)
        .onAppear {
            checkStatus()
        }
    }

    private func checkStatus() {
        if let auth = KeychainHelper.loadAntigravityAuth() {
            email = auth.email ?? "Angemeldet"
            isConnected = true
        } else {
            isConnected = false
        }
    }

    private func testConnection() {
        isTesting = true
        testResult = "Prüfe..."

        Task {
            let service = GeminiAPIService()
            do {
                let data = try await service.fetchUsage()
                await MainActor.run {
                    isTesting = false
                    testResult = "Erfolgreich! \(data.groups.count) Kontingent-Gruppen geladen."
                    if let mail = data.accountEmail {
                        self.email = mail
                        self.isConnected = true
                    }
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    testResult = "Fehler: \(error.localizedDescription)"
                }
            }
        }
    }
}

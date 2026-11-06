import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var apiService: GeminiAPIService?
    private var pollingTimer: Timer?
    private var clockTimer: Timer?
    private var setupWindow: NSWindow?

    private var currentUsage: GeminiUsageData = .empty
    private var lastUpdated: Date?
    private var lastError: String?

    private let pollingInterval: TimeInterval = 300 // 5 Minuten

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()

        statusBarController?.setDropdownCallbacks(
            onSettings: { [weak self] in self?.showSetup() },
            onQuit: { NSApplication.shared.terminate(nil) },
            onRefresh: { [weak self] in self?.fetchUsage() }
        )

        apiService = GeminiAPIService()
        statusBarController?.showInitialText("GC")

        startPolling()
        fetchUsage()
    }

    private func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.fetchUsage()
        }

        // Aktualisiert jede Minute die Uhr-Anzeige für die verbleibende Reset-Zeit
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateUI()
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        clockTimer?.invalidate()
        clockTimer = nil
    }

    private func fetchUsage() {
        guard let apiService = apiService else { return }
        print("[GeminiChecker] Abfrage der Gemini-Nutzungslimits gestartet...")

        Task {
            do {
                let data = try await apiService.fetchUsage()
                print("[GeminiChecker] Erfolgreich geladen: \(data.groups.count) Gruppen. Gemini W: \(Int((data.geminiWeeklyFraction*100).rounded()))%, Gemini 5h: \(Int((data.gemini5hFraction*100).rounded()))%, Argon: \(Int((data.argonWeeklyFraction*100).rounded()))%, Claude/GPT W: \(Int((data.thirdPartyWeeklyFraction*100).rounded()))%, Claude/GPT 5h: \(Int((data.thirdParty5hFraction*100).rounded()))%")
                await MainActor.run {
                    self.currentUsage = data
                    self.lastUpdated = Date()
                    self.lastError = nil
                    self.updateUI()
                }
            } catch {
                print("[GeminiChecker] Fehler bei der Abfrage: \(error.localizedDescription)")
                await MainActor.run {
                    self.lastError = error.localizedDescription
                    self.updateUI()
                }
            }
        }
    }

    private func updateUI() {
        statusBarController?.showProgressBars()
        statusBarController?.updateProgressBars(
            geminiWeeklyFraction: currentUsage.geminiWeeklyFraction,
            gemini5hFraction: currentUsage.gemini5hFraction,
            geminiClockFraction: currentUsage.geminiResetClockFraction,
            argonWeeklyFraction: currentUsage.argonWeeklyFraction,
            argonClockFraction: currentUsage.argonResetClockFraction,
            thirdPartyWeeklyFraction: currentUsage.thirdPartyWeeklyFraction,
            thirdParty5hFraction: currentUsage.thirdParty5hFraction,
            thirdPartyClockFraction: currentUsage.thirdPartyResetClockFraction
        )
        statusBarController?.updateDropdownData(
            usage: currentUsage,
            lastUpdated: lastUpdated,
            errorMessage: lastError
        )
    }

    private func showSetup() {
        if let existingWindow = setupWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let setupView = SetupView(
            onSave: { [weak self] in
                self?.setupWindow?.close()
                self?.setupWindow = nil
                self?.fetchUsage()
            },
            onCancel: { [weak self] in
                self?.setupWindow?.close()
                self?.setupWindow = nil
            }
        )

        let hostingVC = NSHostingController(rootView: setupView)
        let window = NSWindow(contentViewController: hostingVC)
        window.title = "GeminiChecker Einstellungen"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.setupWindow = window
    }
}

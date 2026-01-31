import Cocoa
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var apiService: ClaudeWebAPIService?
    private var pollingTimer: Timer?
    private var setupWindow: NSWindow?

    private var currentUsage: ClaudeUsageData = .empty
    private var lastUpdated: Date?
    private var lastError: String?

    private let pollingInterval: TimeInterval = 300 // 5 minutes

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()

        statusBarController?.setDropdownCallbacks(
            onSettings: { [weak self] in self?.showSetup() },
            onQuit: { NSApplication.shared.terminate(nil) },
            onRefresh: { [weak self] in self?.fetchUsage() }
        )

        // Check for session key
        if let sessionKey = KeychainHelper.load(), !sessionKey.isEmpty {
            apiService = ClaudeWebAPIService(sessionKey: sessionKey)
            statusBarController?.showInitialText("CC")
            startPolling()
            fetchUsage()
        } else {
            statusBarController?.showInitialText("CC?")
            showSetup()
        }
    }

    private func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.fetchUsage()
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func fetchUsage() {
        guard let apiService = apiService else { return }

        Task {
            do {
                let data = try await apiService.fetchUsage()
                await MainActor.run {
                    self.currentUsage = data
                    self.lastUpdated = Date()
                    self.lastError = nil
                    self.updateUI()
                }
            } catch {
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
            sessionFraction: currentUsage.sessionFraction,
            weeklyFraction: currentUsage.weeklyFraction
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
            onComplete: { [weak self] sessionKey in
                guard let self = self else { return }
                self.apiService = ClaudeWebAPIService(sessionKey: sessionKey)
                self.setupWindow?.close()
                self.setupWindow = nil
                self.startPolling()
                self.fetchUsage()
            },
            onCancel: { [weak self] in
                self?.setupWindow?.close()
                self?.setupWindow = nil
            }
        )

        let hostingView = NSHostingView(rootView: setupView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.title = "ClaudeChecker Setup"
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        setupWindow = window
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopPolling()
    }
}

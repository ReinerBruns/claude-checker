import Cocoa

final class StatusBarController {
    private var statusItem: NSStatusItem
    private var progressBarView: ProgressBarView
    private var popover: NSPopover
    private var dropdownVC: DropdownViewController
    private var eventMonitor: Any?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: 90)
        progressBarView = ProgressBarView(frame: NSRect(x: 0, y: 0, width: 90, height: 24))
        dropdownVC = DropdownViewController()
        popover = NSPopover()
        popover.contentViewController = dropdownVC
        popover.behavior = .transient
        popover.animates = true

        setupStatusItem()
    }

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }

        progressBarView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(progressBarView)

        NSLayoutConstraint.activate([
            progressBarView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            progressBarView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            progressBarView.topAnchor.constraint(equalTo: button.topAnchor),
            progressBarView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])

        button.action = #selector(togglePopover)
        button.target = self
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        dropdownVC.updateContent()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    func updateProgressBars(
        sessionFraction: Double,
        weeklyFraction: Double,
        sessionResetFraction: Double,
        weeklyResetFraction: Double
    ) {
        progressBarView.sessionFraction = sessionFraction
        progressBarView.weeklyFraction = weeklyFraction
        progressBarView.sessionResetFraction = sessionResetFraction
        progressBarView.weeklyResetFraction = weeklyResetFraction
    }

    func updateDropdownData(usage: ClaudeUsageData, lastUpdated: Date?, errorMessage: String?) {
        dropdownVC.usage = usage
        dropdownVC.lastUpdated = lastUpdated
        dropdownVC.errorMessage = errorMessage
    }

    func setDropdownCallbacks(onSettings: @escaping () -> Void, onQuit: @escaping () -> Void, onRefresh: @escaping () -> Void) {
        dropdownVC.onSettings = onSettings
        dropdownVC.onQuit = onQuit
        dropdownVC.onRefresh = onRefresh
    }

    func showInitialText(_ text: String) {
        guard let button = statusItem.button else { return }
        progressBarView.isHidden = true
        button.title = text
    }

    func showProgressBars() {
        guard let button = statusItem.button else { return }
        button.title = ""
        progressBarView.isHidden = false
    }
}

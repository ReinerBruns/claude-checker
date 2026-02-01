import Cocoa

final class StatusBarController {
    private var statusItem: NSStatusItem
    private var progressBarView: ProgressBarView
    private var popover: NSPopover
    private var dropdownVC: DropdownViewController
    private var eventMonitor: Any?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: 84)
        progressBarView = ProgressBarView(frame: NSRect(x: 0, y: 0, width: 80, height: 18))
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
            progressBarView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            progressBarView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            progressBarView.widthAnchor.constraint(equalToConstant: 80),
            progressBarView.heightAnchor.constraint(equalToConstant: 18)
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
        dropdownVC.updatePreferredContentSize()
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

    func updateProgressBars(sessionFraction: Double, weeklyFraction: Double) {
        progressBarView.sessionFraction = sessionFraction
        progressBarView.weeklyFraction = weeklyFraction
    }

    func updateDropdownData(usage: ClaudeUsageData, lastUpdated: Date?, errorMessage: String?) {
        dropdownVC.viewModel.usage = usage
        dropdownVC.viewModel.lastUpdated = lastUpdated
        dropdownVC.viewModel.errorMessage = errorMessage
    }

    func setDropdownCallbacks(onSettings: @escaping () -> Void, onQuit: @escaping () -> Void, onRefresh: @escaping () -> Void) {
        dropdownVC.viewModel.onSettings = onSettings
        dropdownVC.viewModel.onQuit = onQuit
        dropdownVC.viewModel.onRefresh = onRefresh
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

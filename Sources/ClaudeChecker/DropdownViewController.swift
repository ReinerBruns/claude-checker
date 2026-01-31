import Cocoa
import SwiftUI

final class DropdownViewController: NSViewController {
    var usage: ClaudeUsageData = .empty
    var lastUpdated: Date?
    var errorMessage: String?

    var onSettings: (() -> Void)?
    var onQuit: (() -> Void)?
    var onRefresh: (() -> Void)?

    private var hostingView: NSHostingView<DropdownView>?

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 300))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateContent()
    }

    func updateContent() {
        hostingView?.removeFromSuperview()

        let dropdownView = DropdownView(
            usage: usage,
            lastUpdated: lastUpdated,
            errorMessage: errorMessage,
            onSettings: { [weak self] in self?.onSettings?() },
            onQuit: { [weak self] in self?.onQuit?() },
            onRefresh: { [weak self] in self?.onRefresh?() }
        )

        let hosting = NSHostingView(rootView: dropdownView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting)

        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingView = hosting
        self.preferredContentSize = hosting.fittingSize
    }
}

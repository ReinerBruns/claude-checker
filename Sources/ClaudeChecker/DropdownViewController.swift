import Cocoa
import SwiftUI

final class DropdownViewModel: ObservableObject {
    @Published var usage: ClaudeUsageData = .empty
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?

    var onSettings: (() -> Void)?
    var onQuit: (() -> Void)?
    var onRefresh: (() -> Void)?
}

final class DropdownViewController: NSViewController {
    let viewModel = DropdownViewModel()
    private var hostingView: NSHostingView<DropdownView>?

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 300))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingView()
    }

    private func setupHostingView() {
        let dropdownView = DropdownView(viewModel: viewModel)

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
    }

    func updatePreferredContentSize() {
        if let hosting = hostingView {
            self.preferredContentSize = hosting.fittingSize
        }
    }
}

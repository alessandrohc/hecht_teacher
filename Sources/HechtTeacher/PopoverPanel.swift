import AppKit

final class PopoverPanel: NSPanel {

    private let textView = NSTextView()
    private let scrollView = NSScrollView()
    private let titleLabel = NSTextField(labelWithString: "Me Write Good")
    private let spinner = NSProgressIndicator()
    private let closeButton = NSButton(title: "✕", target: nil, action: nil)

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 320),
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.title = "Me Write Good"
        self.level = .floating
        self.isFloatingPanel = true
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = true
        self.worksWhenModal = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        buildUI()
    }

    private func buildUI() {
        guard let content = self.contentView else { return }

        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .secondaryLabelColor

        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false

        closeButton.bezelStyle = .accessoryBarAction
        closeButton.isBordered = false
        closeButton.target = self
        closeButton.action = #selector(closeTapped)

        let header = NSStackView(views: [titleLabel, spinner, NSView(), closeButton])
        header.orientation = .horizontal
        header.spacing = 8
        header.alignment = .centerY

        textView.isEditable = false
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isRichText = true
        textView.drawsBackground = false

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let stack = NSStackView(views: [header, scrollView])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 10, right: 10)
        stack.translatesAutoresizingMaskIntoConstraints = false

        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),

            header.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 10),
            header.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -10),

            scrollView.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: -10),
        ])
    }

    func showLoading(near point: NSPoint, for snippet: String) {
        titleLabel.stringValue = "Teaching “\(snippet.prefix(40))\(snippet.count > 40 ? "…" : "")”"
        setPlain("Asking the model…")
        spinner.startAnimation(nil)
        position(near: point)
        orderFrontRegardless()
    }

    func show(result: String) {
        spinner.stopAnimation(nil)
        let attr = MarkdownRenderer.render(result, baseSize: 13)
        textView.textStorage?.setAttributedString(attr)
    }

    func showError(_ message: String) {
        spinner.stopAnimation(nil)
        setPlain("⚠️ " + message)
    }

    private func setPlain(_ text: String) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.labelColor
        ]
        textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: attrs))
    }

    private func position(near point: NSPoint) {
        let size = self.frame.size
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(point, $0.frame, false) }) ?? NSScreen.main else {
            self.setFrameOrigin(point)
            return
        }
        let visible = screen.visibleFrame

        var origin = NSPoint(x: point.x + 12, y: point.y - size.height - 12)
        if origin.x + size.width > visible.maxX { origin.x = visible.maxX - size.width - 8 }
        if origin.x < visible.minX { origin.x = visible.minX + 8 }
        if origin.y < visible.minY { origin.y = point.y + 12 }
        if origin.y + size.height > visible.maxY { origin.y = visible.maxY - size.height - 8 }

        self.setFrameOrigin(origin)
    }

    @objc private func closeTapped() {
        self.orderOut(nil)
    }

    override func cancelOperation(_ sender: Any?) {
        self.orderOut(nil)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

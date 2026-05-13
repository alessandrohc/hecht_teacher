import AppKit

final class MainWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Hecht Teacher"
        window.minSize = NSSize(width: 600, height: 500)
        window.center()
        window.contentViewController = MainViewController()
        self.init(window: window)
    }
}

final class MainViewController: NSViewController {

    private let contextScrollView = NSScrollView()
    private let answerScrollView = NSScrollView()
    private let resultScrollView = NSScrollView()
    private let contextTextView = NSTextView()
    private let answerTextView = NSTextView()
    private let resultTextView = NSTextView()
    private let improveButton = NSButton(title: "Improve my answer", target: nil, action: nil)
    private let clearButton = NSButton(title: "Clear", target: nil, action: nil)
    private let spinner = NSProgressIndicator()
    private let modelLabel = NSTextField(labelWithString: "")

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 760, height: 760))
        root.autoresizingMask = [.width, .height]

        configureTextView(contextTextView, scrollView: contextScrollView, placeholder: "Paste the context here (in any language) — for example, the email or message you are replying to.")
        configureTextView(answerTextView, scrollView: answerScrollView, placeholder: "Write your answer in English here. The AI will rewrite it more naturally and explain why.")
        configureTextView(resultTextView, scrollView: resultScrollView, placeholder: "The improved version and the explanations will appear here.")
        resultTextView.isEditable = false

        let contextLabel = sectionLabel("1. Context")
        let answerLabel = sectionLabel("2. Your English answer")
        let resultLabel = sectionLabel("3. AI coaching")

        improveButton.bezelStyle = .rounded
        improveButton.keyEquivalent = "\r"
        improveButton.target = self
        improveButton.action = #selector(improveTapped)

        clearButton.bezelStyle = .rounded
        clearButton.target = self
        clearButton.action = #selector(clearTapped)

        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false

        modelLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        modelLabel.textColor = .secondaryLabelColor
        refreshModelLabel()

        let buttonRow = NSStackView(views: [improveButton, clearButton, spinner, NSView(), modelLabel])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 10
        buttonRow.alignment = .centerY
        buttonRow.distribution = .fill

        let stack = NSStackView(views: [
            contextLabel, contextScrollView,
            answerLabel, answerScrollView,
            buttonRow,
            resultLabel, resultScrollView
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor),

            contextScrollView.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 16),
            contextScrollView.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -16),
            contextScrollView.heightAnchor.constraint(equalToConstant: 140),

            answerScrollView.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 16),
            answerScrollView.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -16),
            answerScrollView.heightAnchor.constraint(equalToConstant: 160),

            buttonRow.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 16),
            buttonRow.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -16),

            resultScrollView.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 16),
            resultScrollView.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -16),
            resultScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220),
        ])

        self.view = root
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        refreshModelLabel()
    }

    private func refreshModelLabel() {
        modelLabel.stringValue = "Model: \(Settings.model)"
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        return label
    }

    private func configureTextView(_ textView: NSTextView, scrollView: NSScrollView, placeholder: String) {
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.autoresizingMask = [.width]
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainerInset = NSSize(width: 6, height: 6)
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        textView.string = ""
        applyPlaceholder(textView, placeholder: placeholder)
    }

    private func applyPlaceholder(_ textView: NSTextView, placeholder: String) {
        textView.setValue(
            NSAttributedString(
                string: placeholder,
                attributes: [
                    .foregroundColor: NSColor.placeholderTextColor,
                    .font: NSFont.systemFont(ofSize: 13)
                ]
            ),
            forKey: "placeholderAttributedString"
        )
    }

    @objc private func improveTapped() {
        let context = contextTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        let attempt = answerTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !attempt.isEmpty else {
            resultTextView.string = "Please write something in the “Your English answer” area first."
            return
        }

        refreshModelLabel()
        improveButton.isEnabled = false
        spinner.startAnimation(nil)
        resultTextView.string = "Asking the model…"

        Task { @MainActor in
            do {
                let response = try await OpenAIClient.shared.improveAnswer(context: context, attempt: attempt)
                resultTextView.string = response
            } catch {
                resultTextView.string = "⚠️ \(error.localizedDescription)"
            }
            spinner.stopAnimation(nil)
            improveButton.isEnabled = true
        }
    }

    @objc private func clearTapped() {
        contextTextView.string = ""
        answerTextView.string = ""
        resultTextView.string = ""
    }
}

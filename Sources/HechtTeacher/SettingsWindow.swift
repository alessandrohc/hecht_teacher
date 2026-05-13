import AppKit

final class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 220),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()
        window.contentViewController = SettingsViewController()
        self.init(window: window)
    }
}

final class SettingsViewController: NSViewController {

    private let apiKeyField = NSSecureTextField()
    private let modelPopup = NSPopUpButton()
    private let statusLabel = NSTextField(labelWithString: "")

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 220))

        let title = NSTextField(labelWithString: "OpenAI configuration")
        title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)

        let keyLabel = NSTextField(labelWithString: "API key:")
        apiKeyField.placeholderString = "sk-..."
        apiKeyField.stringValue = Settings.apiKey ?? ""

        let modelLabel = NSTextField(labelWithString: "Model:")
        modelPopup.addItems(withTitles: Settings.availableModels)
        modelPopup.selectItem(withTitle: Settings.model)

        let saveButton = NSButton(title: "Save", target: self, action: #selector(save))
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"

        let getKeyButton = NSButton(title: "Get an API key…", target: self, action: #selector(openKeyPage))
        getKeyButton.bezelStyle = .accessoryBarAction
        getKeyButton.isBordered = false

        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor

        let keyRow = NSStackView(views: [keyLabel, apiKeyField])
        keyRow.orientation = .horizontal
        keyRow.spacing = 8
        keyRow.alignment = .firstBaseline
        keyLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true
        apiKeyField.translatesAutoresizingMaskIntoConstraints = false

        let modelRow = NSStackView(views: [modelLabel, modelPopup])
        modelRow.orientation = .horizontal
        modelRow.spacing = 8
        modelRow.alignment = .firstBaseline
        modelLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true

        let buttonRow = NSStackView(views: [getKeyButton, NSView(), saveButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 8
        buttonRow.alignment = .centerY

        let stack = NSStackView(views: [title, keyRow, modelRow, buttonRow, statusLabel])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        stack.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            stack.topAnchor.constraint(equalTo: root.topAnchor),
            stack.bottomAnchor.constraint(equalTo: root.bottomAnchor),

            keyRow.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 18),
            keyRow.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -18),
            apiKeyField.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),

            modelRow.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 18),
            modelRow.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -18),

            buttonRow.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 18),
            buttonRow.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -18),
        ])

        self.view = root
    }

    @objc private func save() {
        let key = apiKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty {
            Keychain.deleteAPIKey()
        } else {
            Keychain.saveAPIKey(key)
        }
        if let selected = modelPopup.selectedItem?.title {
            Settings.model = selected
        }
        statusLabel.stringValue = "Saved at \(timestamp())."
    }

    @objc private func openKeyPage() {
        if let url = URL(string: "https://platform.openai.com/api-keys") {
            NSWorkspace.shared.open(url)
        }
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: Date())
    }
}

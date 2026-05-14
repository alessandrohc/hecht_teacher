import AppKit

final class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 560),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.minSize = NSSize(width: 540, height: 460)
        window.center()
        window.contentViewController = SettingsViewController()
        self.init(window: window)
    }
}

final class SettingsViewController: NSViewController {

    private let tabView = NSTabView()

    private let apiKeyField = NSSecureTextField()
    private let modelPopup = NSPopUpButton()
    private let menuBarToggle = NSButton(checkboxWithTitle: "Run as menu-bar app (no Dock icon)", target: nil, action: nil)
    private let restartHint = NSTextField(labelWithString: "")
    private var initialMenuBarMode: Bool = Settings.runAsMenuBarApp

    private let improvePromptTextView = NSTextView()
    private let improvePromptScroll = NSScrollView()
    private let improveTempSlider = NSSlider()
    private let improveTempValueLabel = NSTextField(labelWithString: "")
    private let teachPromptTextView = NSTextView()
    private let teachPromptScroll = NSScrollView()
    private let teachTempSlider = NSSlider()
    private let teachTempValueLabel = NSTextField(labelWithString: "")

    private let saveButton = NSButton(title: "Save", target: nil, action: nil)
    private let statusLabel = NSTextField(labelWithString: "")

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 640, height: 560))

        tabView.translatesAutoresizingMaskIntoConstraints = false
        tabView.addTabViewItem(makeGeneralTab())
        tabView.addTabViewItem(makeAPITab())
        tabView.addTabViewItem(makePromptsTab())

        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        saveButton.target = self
        saveButton.action = #selector(save)

        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor

        let footer = NSStackView(views: [statusLabel, NSView(), saveButton])
        footer.orientation = .horizontal
        footer.spacing = 8
        footer.alignment = .centerY
        footer.translatesAutoresizingMaskIntoConstraints = false

        root.addSubview(tabView)
        root.addSubview(footer)

        NSLayoutConstraint.activate([
            tabView.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            tabView.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            tabView.topAnchor.constraint(equalTo: root.topAnchor, constant: 16),
            tabView.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -10),

            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            footer.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            footer.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -16),
        ])

        self.view = root
    }

    // MARK: - General tab

    private func makeGeneralTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "general")
        item.label = "General"

        let container = NSView()

        let title = NSTextField(labelWithString: "Behavior")
        title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)

        menuBarToggle.state = Settings.runAsMenuBarApp ? .on : .off
        menuBarToggle.target = self
        menuBarToggle.action = #selector(menuBarToggleChanged)

        let toggleHint = NSTextField(labelWithString: "When enabled, the app lives only in the menu bar (top-right of the screen) and has no Dock icon. Click the menu-bar icon to open the main window, Settings, or quit.")
        toggleHint.font = NSFont.systemFont(ofSize: 11)
        toggleHint.textColor = .secondaryLabelColor
        toggleHint.maximumNumberOfLines = 4

        restartHint.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        restartHint.textColor = .systemOrange
        restartHint.stringValue = ""
        restartHint.maximumNumberOfLines = 2

        let stack = NSStackView(views: [title, menuBarToggle, toggleHint, restartHint])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),

            toggleHint.widthAnchor.constraint(lessThanOrEqualToConstant: 540),
            restartHint.widthAnchor.constraint(lessThanOrEqualToConstant: 540),
        ])

        item.view = container
        return item
    }

    // MARK: - API tab

    private func makeAPITab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "api")
        item.label = "OpenAI"

        let container = NSView()

        let title = NSTextField(labelWithString: "OpenAI configuration")
        title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)

        let keyLabel = NSTextField(labelWithString: "API key:")
        apiKeyField.placeholderString = "sk-..."
        apiKeyField.stringValue = Settings.apiKey ?? ""

        let modelLabel = NSTextField(labelWithString: "Model:")
        modelPopup.addItems(withTitles: Settings.availableModels)
        modelPopup.selectItem(withTitle: Settings.model)

        let getKeyButton = NSButton(title: "Get an API key…", target: self, action: #selector(openKeyPage))
        getKeyButton.bezelStyle = .accessoryBarAction
        getKeyButton.isBordered = false

        let hint = NSTextField(labelWithString: "Your API key is stored in the macOS Keychain. Leave it empty to remove a stored key.")
        hint.font = NSFont.systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        hint.maximumNumberOfLines = 2

        let keyRow = NSStackView(views: [keyLabel, apiKeyField])
        keyRow.orientation = .horizontal
        keyRow.spacing = 8
        keyRow.alignment = .firstBaseline
        keyLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true

        let modelRow = NSStackView(views: [modelLabel, modelPopup])
        modelRow.orientation = .horizontal
        modelRow.spacing = 8
        modelRow.alignment = .firstBaseline
        modelLabel.widthAnchor.constraint(equalToConstant: 80).isActive = true

        let stack = NSStackView(views: [title, keyRow, modelRow, getKeyButton, hint])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),

            keyRow.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 14),
            keyRow.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -14),
            apiKeyField.widthAnchor.constraint(greaterThanOrEqualToConstant: 360),

            modelRow.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 14),
            modelRow.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -14),
        ])

        item.view = container
        return item
    }

    // MARK: - Prompts tab

    private func makePromptsTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "prompts")
        item.label = "Prompts"

        let container = NSView()

        let title = NSTextField(labelWithString: "System prompts")
        title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)

        let hint = NSTextField(labelWithString: "These prompts are sent as the “system” role for each feature. Edit to change the assistant's tone, structure or rules.")
        hint.font = NSFont.systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        hint.maximumNumberOfLines = 3

        let improveSection = makePromptSection(
            title: "Improve answer (main window)",
            textView: improvePromptTextView,
            scrollView: improvePromptScroll,
            currentPrompt: Settings.improvePrompt,
            tempSlider: improveTempSlider,
            tempLabel: improveTempValueLabel,
            currentTemp: Settings.improveTemperature,
            tempAction: #selector(improveTempChanged),
            resetAction: #selector(resetImprove)
        )

        let teachSection = makePromptSection(
            title: "Teach selected text (Service / popover)",
            textView: teachPromptTextView,
            scrollView: teachPromptScroll,
            currentPrompt: Settings.teachPrompt,
            tempSlider: teachTempSlider,
            tempLabel: teachTempValueLabel,
            currentTemp: Settings.teachTemperature,
            tempAction: #selector(teachTempChanged),
            resetAction: #selector(resetTeach)
        )

        let stack = NSStackView(views: [title, hint, improveSection, teachSection])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            improveSection.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 14),
            improveSection.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -14),
            teachSection.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 14),
            teachSection.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -14),

            improveSection.heightAnchor.constraint(equalTo: teachSection.heightAnchor),
        ])

        item.view = container
        return item
    }

    private func makePromptSection(
        title: String,
        textView: NSTextView,
        scrollView: NSScrollView,
        currentPrompt: String,
        tempSlider: NSSlider,
        tempLabel: NSTextField,
        currentTemp: Double,
        tempAction: Selector,
        resetAction: Selector
    ) -> NSView {
        let header = NSTextField(labelWithString: title)
        header.font = NSFont.systemFont(ofSize: 12, weight: .semibold)

        let reset = NSButton(title: "Reset to default", target: self, action: resetAction)
        reset.bezelStyle = .accessoryBarAction
        reset.controlSize = .small

        let headerRow = NSStackView(views: [header, NSView(), reset])
        headerRow.orientation = .horizontal
        headerRow.spacing = 8
        headerRow.alignment = .centerY

        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.string = currentPrompt

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        let tempCaption = NSTextField(labelWithString: "Temperature:")
        tempCaption.font = NSFont.systemFont(ofSize: 11)
        tempCaption.textColor = .secondaryLabelColor

        tempSlider.minValue = Settings.temperatureRange.lowerBound
        tempSlider.maxValue = Settings.temperatureRange.upperBound
        tempSlider.doubleValue = currentTemp
        tempSlider.isContinuous = true
        tempSlider.numberOfTickMarks = 5
        tempSlider.allowsTickMarkValuesOnly = false
        tempSlider.target = self
        tempSlider.action = tempAction

        tempLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        tempLabel.textColor = .secondaryLabelColor
        tempLabel.stringValue = String(format: "%.2f", currentTemp)
        tempLabel.alignment = .right

        let tempRow = NSStackView(views: [tempCaption, tempSlider, tempLabel])
        tempRow.orientation = .horizontal
        tempRow.spacing = 8
        tempRow.alignment = .centerY
        tempRow.translatesAutoresizingMaskIntoConstraints = false
        tempCaption.widthAnchor.constraint(equalToConstant: 86).isActive = true
        tempLabel.widthAnchor.constraint(equalToConstant: 36).isActive = true

        let section = NSStackView(views: [headerRow, scrollView, tempRow])
        section.orientation = .vertical
        section.alignment = .leading
        section.spacing = 4
        section.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 130),
            scrollView.widthAnchor.constraint(greaterThanOrEqualToConstant: 540),
            headerRow.widthAnchor.constraint(equalTo: section.widthAnchor),
            scrollView.widthAnchor.constraint(equalTo: section.widthAnchor),
            tempRow.widthAnchor.constraint(equalTo: section.widthAnchor),
        ])

        return section
    }

    // MARK: - Actions

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
        Settings.improvePrompt = improvePromptTextView.string
        Settings.teachPrompt = teachPromptTextView.string
        Settings.improveTemperature = improveTempSlider.doubleValue
        Settings.teachTemperature = teachTempSlider.doubleValue

        let newMenuBarMode = menuBarToggle.state == .on
        Settings.runAsMenuBarApp = newMenuBarMode
        if newMenuBarMode != initialMenuBarMode {
            restartHint.stringValue = "⚠︎ Quit and relaunch Me Write Good for the menu-bar setting to take effect."
        } else {
            restartHint.stringValue = ""
        }

        statusLabel.stringValue = "Saved at \(timestamp())."
    }

    @objc private func menuBarToggleChanged() {
        let newMenuBarMode = menuBarToggle.state == .on
        if newMenuBarMode != initialMenuBarMode {
            restartHint.stringValue = "Click Save, then quit and relaunch Me Write Good for this change to take effect."
        } else {
            restartHint.stringValue = ""
        }
    }

    @objc private func resetImprove() {
        Settings.resetImproveDefaults()
        improvePromptTextView.string = Settings.improvePrompt
        improveTempSlider.doubleValue = Settings.improveTemperature
        improveTempValueLabel.stringValue = String(format: "%.2f", Settings.improveTemperature)
        statusLabel.stringValue = "Reset “Improve answer” to defaults — click Save to keep."
    }

    @objc private func resetTeach() {
        Settings.resetTeachDefaults()
        teachPromptTextView.string = Settings.teachPrompt
        teachTempSlider.doubleValue = Settings.teachTemperature
        teachTempValueLabel.stringValue = String(format: "%.2f", Settings.teachTemperature)
        statusLabel.stringValue = "Reset “Teach selected text” to defaults — click Save to keep."
    }

    @objc private func improveTempChanged() {
        improveTempValueLabel.stringValue = String(format: "%.2f", improveTempSlider.doubleValue)
    }

    @objc private func teachTempChanged() {
        teachTempValueLabel.stringValue = String(format: "%.2f", teachTempSlider.doubleValue)
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

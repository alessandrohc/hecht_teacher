import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

if Settings.runAsMenuBarApp {
    app.setActivationPolicy(.accessory)
} else {
    app.setActivationPolicy(.regular)
    app.activate(ignoringOtherApps: true)
}

app.run()

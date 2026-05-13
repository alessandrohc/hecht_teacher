import AppKit

final class ServiceProvider: NSObject {

    private let popover = PopoverPanel()

    @objc func teachSelectedText(_ pboard: NSPasteboard, userData: String, error errorPointer: AutoreleasingUnsafeMutablePointer<NSString>) {
        guard let text = readString(from: pboard), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorPointer.pointee = "No text was selected." as NSString
            return
        }

        let mouse = NSEvent.mouseLocation

        Task { @MainActor in
            popover.showLoading(near: mouse, for: text)
            do {
                let response = try await OpenAIClient.shared.teachSelectedText(text)
                popover.show(result: response)
            } catch {
                popover.showError(error.localizedDescription)
            }
        }
    }

    private func readString(from pboard: NSPasteboard) -> String? {
        if let s = pboard.string(forType: .string) { return s }
        if let items = pboard.pasteboardItems {
            for item in items {
                if let s = item.string(forType: .string) { return s }
                if let s = item.string(forType: NSPasteboard.PasteboardType("public.utf8-plain-text")) { return s }
            }
        }
        return nil
    }
}

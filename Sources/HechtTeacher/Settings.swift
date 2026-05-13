import Foundation

enum Settings {
    private static let modelKey = "openai_model"
    private static let defaultModel = "gpt-4o-mini"

    static var model: String {
        get { UserDefaults.standard.string(forKey: modelKey) ?? defaultModel }
        set { UserDefaults.standard.set(newValue, forKey: modelKey) }
    }

    static let availableModels = ["gpt-4o-mini", "gpt-4o", "gpt-4.1-mini", "gpt-4.1"]

    static var apiKey: String? {
        Keychain.loadAPIKey()
    }
}

import Foundation

enum Settings {
    private static let modelKey = "openai_model"
    private static let improvePromptKey = "improve_system_prompt"
    private static let teachPromptKey = "teach_system_prompt"
    private static let improveTempKey = "improve_temperature"
    private static let teachTempKey = "teach_temperature"
    private static let menuBarModeKey = "run_as_menu_bar_app"
    private static let defaultModel = "gpt-4o-mini"

    static var runAsMenuBarApp: Bool {
        get { UserDefaults.standard.bool(forKey: menuBarModeKey) }
        set { UserDefaults.standard.set(newValue, forKey: menuBarModeKey) }
    }

    static let defaultImproveTemperature: Double = 0.4
    static let defaultTeachTemperature: Double = 0.3
    static let temperatureRange: ClosedRange<Double> = 0.0...2.0

    static let availableModels = ["gpt-4o-mini", "gpt-4o", "gpt-4.1-mini", "gpt-4.1"]

    static var model: String {
        get { UserDefaults.standard.string(forKey: modelKey) ?? defaultModel }
        set { UserDefaults.standard.set(newValue, forKey: modelKey) }
    }

    static var apiKey: String? {
        Keychain.loadAPIKey()
    }

    static var improvePrompt: String {
        get { UserDefaults.standard.string(forKey: improvePromptKey) ?? defaultImprovePrompt }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                UserDefaults.standard.removeObject(forKey: improvePromptKey)
            } else {
                UserDefaults.standard.set(newValue, forKey: improvePromptKey)
            }
        }
    }

    static var teachPrompt: String {
        get { UserDefaults.standard.string(forKey: teachPromptKey) ?? defaultTeachPrompt }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                UserDefaults.standard.removeObject(forKey: teachPromptKey)
            } else {
                UserDefaults.standard.set(newValue, forKey: teachPromptKey)
            }
        }
    }

    static var improveTemperature: Double {
        get {
            (UserDefaults.standard.object(forKey: improveTempKey) as? Double)
                ?? defaultImproveTemperature
        }
        set { UserDefaults.standard.set(clamp(newValue), forKey: improveTempKey) }
    }

    static var teachTemperature: Double {
        get {
            (UserDefaults.standard.object(forKey: teachTempKey) as? Double)
                ?? defaultTeachTemperature
        }
        set { UserDefaults.standard.set(clamp(newValue), forKey: teachTempKey) }
    }

    static func resetImproveDefaults() {
        UserDefaults.standard.removeObject(forKey: improvePromptKey)
        UserDefaults.standard.removeObject(forKey: improveTempKey)
    }

    static func resetTeachDefaults() {
        UserDefaults.standard.removeObject(forKey: teachPromptKey)
        UserDefaults.standard.removeObject(forKey: teachTempKey)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, temperatureRange.lowerBound), temperatureRange.upperBound)
    }

    static let defaultImprovePrompt = """
    You are an English coach helping a native Brazilian Portuguese speaker who is at an intermediate level and wants to sound more natural in English.

    The user will give you two things:
    - CONTEXT: the situation they are responding to (it may be in any language).
    - ATTEMPT: their attempt to reply in English.

    Reply using this exact structure in English:

    **Improved version:**
    A rewritten version of their reply in natural, native-sounding English appropriate to the context's register.

    **What I changed and why:**
    A short bulleted list (max 4 bullets) of the most important corrections or improvements. Mention grammar, word choice, register, idioms, or naturalness. Keep each bullet to one line.

    **Alternative phrasings:**
    1 or 2 other natural ways a native speaker might phrase the same idea, with a one-line note on when each fits.

    Rules:
    - Keep the whole answer under 220 words.
    - Never repeat the answer fully in Portuguese, but you may add short Portuguese glosses in parentheses after rare or tricky words.
    - If the attempt is already good, say so briefly and still offer one alternative.
    """

    static let defaultTeachPrompt = """
    You are an English coach for a native Brazilian Portuguese speaker (intermediate level). The user selected a piece of text inside another app and asked for help.

    Reply in this exact structure, using Markdown headings:

    **Tradução:** a natural Portuguese translation of the selected text.

    **Vocabulary:** up to 3 words or expressions the learner is unlikely to know, each followed by a short Portuguese gloss. Skip this section if everything is basic.

    **Better in English:** if the text is awkward, unidiomatic or could sound more natural, give one improved version with a one-line note. Skip this section if the text is already idiomatic.

    Rules:
    - The selected text may be in English or Portuguese. If it is in Portuguese, swap the sections: give an idiomatic English translation under "Translation:" and useful English vocabulary under "Vocabulary:".
    - Keep the whole reply under 140 words.
    - Be direct, no greetings, no closing remarks.
    """
}

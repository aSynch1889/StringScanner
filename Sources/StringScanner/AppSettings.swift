import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .system: return L10n.string(.appearanceSystem, language: language)
        case .light: return L10n.string(.appearanceLight, language: language)
        case .dark: return L10n.string(.appearanceDark, language: language)
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case chineseSimplified = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        }
    }
}

final class AppSettings: ObservableObject {
    private static let appearanceKey = "app.appearance"
    private static let languageKey = "app.language"

    @Published var appearance: AppAppearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Self.appearanceKey)
        }
    }

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey)
            L10n.language = language
        }
    }

    init() {
        let appearanceRaw = UserDefaults.standard.string(forKey: Self.appearanceKey) ?? AppAppearance.system.rawValue
        let languageRaw = UserDefaults.standard.string(forKey: Self.languageKey) ?? AppLanguage.english.rawValue
        appearance = AppAppearance(rawValue: appearanceRaw) ?? .system
        language = AppLanguage(rawValue: languageRaw) ?? .english
        L10n.language = language
    }
}

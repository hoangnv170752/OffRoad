//
//  AppSettings.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI
import Observation

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return String(localized: "System")
        case .light: return String(localized: "Light")
        case .dark: return String(localized: "Dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case french = "fr"
    case spanish = "es"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .french: return "Français"
        case .spanish: return "Español"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .french: return "🇫🇷"
        case .spanish: return "🇪🇸"
        }
    }
}

@Observable
class AppSettings {
    var theme: AppTheme = .system {
        didSet {
            UserDefaults.standard.set(theme.rawValue, forKey: "appTheme")
        }
    }

    var language: AppLanguage = .english {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
            applyLanguage()
        }
    }

    init() {
        let themeRaw = UserDefaults.standard.string(forKey: "appTheme") ?? "system"
        self.theme = AppTheme(rawValue: themeRaw) ?? .system

        let langRaw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self.language = AppLanguage(rawValue: langRaw) ?? .english

        applyLanguage()
    }

    func applyLanguage() {
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
    }
}

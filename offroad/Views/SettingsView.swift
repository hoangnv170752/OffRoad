//
//  SettingsView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) var appSettings

    var body: some View {
        NavigationStack {
            List {
                themeSection
                languageSection
                aboutSection
            }
            .navigationTitle(appSettings.localized("Settings"))
        }
    }

    // MARK: - Theme

    private var themeSection: some View {
        Section {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appSettings.theme = theme
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: theme.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(themeIconColor(theme))
                            .frame(width: 28)

                        Text(theme.displayName)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)

                        Spacer()

                        if appSettings.theme == theme {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.15, green: 0.40, blue: 0.30))
                        }
                    }
                }
            }
        } header: {
            Text(appSettings.localized("Appearance"))
        } footer: {
            Text(appSettings.localized("Choose how OffRoad looks on your device."))
        }
    }

    private func themeIconColor(_ theme: AppTheme) -> Color {
        switch theme {
        case .system: return .purple
        case .light: return .orange
        case .dark: return .indigo
        }
    }

    // MARK: - Language

    private var languageSection: some View {
        Section {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button(action: {
                    appSettings.language = language
                }) {
                    HStack(spacing: 12) {
                        Text(language.flag)
                            .font(.system(size: 22))
                            .frame(width: 28)

                        Text(language.displayName)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)

                        Spacer()

                        if appSettings.language == language {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.15, green: 0.40, blue: 0.30))
                        }
                    }
                }
            }
        } header: {
            Text(appSettings.localized("Language"))
        } footer: {
            Text(appSettings.localized("Changing language will take full effect after restarting the app."))
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text(appSettings.localized("Version"))
                Spacer()
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            HStack {
                Text(appSettings.localized("Build"))
                Spacer()
                Text("1")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text(appSettings.localized("About"))
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings())
}

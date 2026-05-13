//
//  BottomTabBar.swift
//  offroad
//
//  Created by Codex on 13/5/26.
//

import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: AppTab
    var onSearchTap: () -> Void

    @Environment(AppSettings.self) private var appSettings

    private let accent = Color(red: 0.15, green: 0.35, blue: 0.25)

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                tabBarPillContent
                    .glassEffect(.regular.interactive(), in: .capsule)

                searchButtonContent
                    .glassEffect(.regular.interactive(), in: .circle)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    // MARK: - Tab Pill Content

    private var tabBarPillContent: some View {
        HStack(spacing: 0) {
            tabItem(.home,
                    systemImage: "house.fill",
                    label: appSettings.localized("Home"))
            tabItem(.chats,
                    systemImage: "bubble.left.and.bubble.right.fill",
                    label: appSettings.localized("Chats"))
            tabItem(.contacts,
                    systemImage: "person.2.fill",
                    label: appSettings.localized("Contacts"))
            tabItem(.settings,
                    systemImage: "gearshape.fill",
                    label: appSettings.localized("Settings"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    private func tabItem(_ tab: AppTab, systemImage: String, label: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if selectedTab != tab {
                withAnimation(.easeInOut(duration: 0.15)) {
                    selectedTab = tab
                }
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? accent : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Search Button Content

    private var searchButtonContent: some View {
        Button(action: onSearchTap) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 56, height: 56)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(appSettings.localized("Search FAQ"))
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(.systemGroupedBackground), Color(red: 0.85, green: 0.92, blue: 0.88)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            Spacer()
            BottomTabBar(selectedTab: .constant(.settings), onSearchTap: {})
                .environment(AppSettings())
        }
    }
}

import SwiftUI

struct BottomTabBar: View {
    @Binding var selectedTab: AppTab
    var onSearchTap: () -> Void

    @Environment(AppSettings.self) private var appSettings

    private let accent = Color(red: 0.15, green: 0.35, blue: 0.25)

    @Namespace private var tabHighlight

    var body: some View {
        if #available(iOS 26.0, *) {
            glassTabBar
        } else {
            materialTabBar
        }
    }

    // MARK: - iOS 26+ Glass Tab Bar

    @available(iOS 26.0, *)
    private var glassTabBar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                glassTabBarPillContent
                    .glassEffect(.regular.interactive(), in: .capsule)

                searchButtonContent
                    .glassEffect(.regular.interactive(), in: .circle)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    // MARK: - iOS 18 Material Tab Bar

    private var materialTabBar: some View {
        HStack(spacing: 10) {
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
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            )

            Button(action: onSearchTap) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(appSettings.localized("Search FAQ"))
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    // MARK: - Tab Pill Content (iOS 26+ glass)

    @available(iOS 26.0, *)
    private var glassTabBarPillContent: some View {
        HStack(spacing: 0) {
            glassTabItem(.home,
                         systemImage: "house.fill",
                         label: appSettings.localized("Home"))
            glassTabItem(.chats,
                         systemImage: "bubble.left.and.bubble.right.fill",
                         label: appSettings.localized("Chats"))
            glassTabItem(.contacts,
                         systemImage: "person.2.fill",
                         label: appSettings.localized("Contacts"))
            glassTabItem(.settings,
                         systemImage: "gearshape.fill",
                         label: appSettings.localized("Settings"))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab Pill Content (iOS 18 material)

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

    // MARK: - iOS 26+ Glass Tab Item

    @available(iOS 26.0, *)
    private func glassTabItem(_ tab: AppTab, systemImage: String, label: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if selectedTab != tab {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedTab = tab
                }
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? accent : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            .background {
                if isSelected {
                    Capsule()
                        .fill(.clear)
                        .glassEffect(.regular.interactive(), in: .capsule)
                        .matchedGeometryEffect(id: "tabHighlight", in: tabHighlight)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - iOS 18 Material Tab Item

    private func tabItem(_ tab: AppTab, systemImage: String, label: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if selectedTab != tab {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    selectedTab = tab
                }
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 19, weight: isSelected ? .semibold : .regular))
                    .scaleEffect(isSelected ? 1.12 : 1.0)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? accent : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accent.opacity(0.12))
                        .matchedGeometryEffect(id: "tabHighlight", in: tabHighlight)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedTab)
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

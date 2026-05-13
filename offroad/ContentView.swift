//
//  ContentView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

enum AppTab: String {
    case home, chats, contacts, settings
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var isFAQSearchPresented = false
    @StateObject private var chatStore: ChatStore
    @StateObject private var bluetoothManager: BluetoothManager
    @Environment(AppSettings.self) private var appSettings

    init() {
        let store = ChatStore()
        let manager = BluetoothManager()
        manager.chatStore = store
        _chatStore = StateObject(wrappedValue: store)
        _bluetoothManager = StateObject(wrappedValue: manager)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tag(AppTab.home)
                .toolbar(.hidden, for: .tabBar)

            ChatsView()
                .tag(AppTab.chats)
                .toolbar(.hidden, for: .tabBar)

            ContactsView()
                .tag(AppTab.contacts)
                .toolbar(.hidden, for: .tabBar)

            SettingsView()
                .tag(AppTab.settings)
                .toolbar(.hidden, for: .tabBar)
        }
        .tint(Color(red: 0.15, green: 0.35, blue: 0.25))
        .environmentObject(bluetoothManager)
        .environmentObject(chatStore)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomTabBar(
                selectedTab: $selectedTab,
                onSearchTap: { isFAQSearchPresented = true }
            )
            .background(
                Color(.systemGroupedBackground)
                    .opacity(0.001)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .sheet(isPresented: $isFAQSearchPresented) {
            FAQSearchView()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppSettings())
}

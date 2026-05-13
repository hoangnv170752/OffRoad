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

struct HideTabBarKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var hideTabBar: Binding<Bool> {
        get { self[HideTabBarKey.self] }
        set { self[HideTabBarKey.self] = newValue }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var isFAQSearchPresented = false
    @State private var chatDevice: DiscoveredDevice?
    @State private var hideTabBar = false
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
            if !hideTabBar {
                BottomTabBar(
                    selectedTab: $selectedTab,
                    onSearchTap: { isFAQSearchPresented = true }
                )
                .background(
                    Color(.systemGroupedBackground)
                        .opacity(0.001)
                        .ignoresSafeArea(edges: .bottom)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .environment(\.hideTabBar, $hideTabBar)
        .sheet(isPresented: $isFAQSearchPresented) {
            FAQSearchView()
        }
        .alert(
            "Connection Request",
            isPresented: Binding(
                get: { bluetoothManager.incomingRequest != nil },
                set: { if !$0 { bluetoothManager.incomingRequest = nil } }
            )
        ) {
            Button("Accept") {
                bluetoothManager.acceptIncomingConnection()
            }
            Button("Decline", role: .cancel) {
                bluetoothManager.declineIncomingConnection()
            }
        } message: {
            Text("\(bluetoothManager.incomingRequest?.peerName ?? "A device") wants to chat with you via Bluetooth.")
        }
        .sheet(item: $chatDevice) { device in
            NavigationStack {
                BluetoothChatView(device: device)
                    .environmentObject(bluetoothManager)
                    .environmentObject(chatStore)
            }
        }
        .onChange(of: bluetoothManager.shouldNavigateToChat) {
            if let device = bluetoothManager.shouldNavigateToChat {
                chatDevice = device
                bluetoothManager.shouldNavigateToChat = nil
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppSettings())
}

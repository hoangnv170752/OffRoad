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
    @StateObject private var bluetoothManager = BluetoothManager()
    @Environment(AppSettings.self) var appSettings

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(appSettings.localized("Home"))
                }
                .tag(AppTab.home)

            ChatsView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text(appSettings.localized("Chats"))
                }
                .tag(AppTab.chats)

            ContactsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text(appSettings.localized("Contacts"))
                }
                .tag(AppTab.contacts)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text(appSettings.localized("Settings"))
                }
                .tag(AppTab.settings)
        }
        .tint(Color(red: 0.15, green: 0.35, blue: 0.25))
        .environmentObject(bluetoothManager)
    }
}

#Preview {
    ContentView()
}

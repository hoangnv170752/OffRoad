//
//  HomeView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI
import Combine

struct HomeView: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject private var chatStore: ChatStore
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var selectedDevice: DiscoveredDevice?
    @State private var now = Date()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private var recentChats: [ChatItem] {
        chatStore.conversations.prefix(4).map { stored in
            ChatItem(
                id: stored.id,
                name: stored.peerName,
                lastMessage: stored.messages.last?.text ?? "No messages",
                time: relativeTimeString(for: stored.lastUpdated, relativeTo: now),
                unreadCount: 0,
                avatarColor: avatarColor(for: stored.peerName),
                isOnline: bluetoothManager.discoveredDevices.contains(where: { $0.peripheralId == stored.id })
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    HomeHeaderView(selectedTab: $selectedTab)

                    PrivacyBannerView()
                        .padding(.top, 16)

                    RecentChatsSection(chats: recentChats)
                        .padding(.top, 24)

                    NearbyDevicesSection(
                        devices: bluetoothManager.discoveredDevices,
                        onSelectDevice: { device in
                            selectedDevice = device
                        },
                        onScanTap: {
                            bluetoothManager.refreshScan()
                        }
                    )
                        .padding(.top, 24)
                }
                .padding(.horizontal, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(for: UUID.self) { peerId in
                ChatDetailView(peerId: peerId)
            }
        }
        .sheet(item: $selectedDevice) { device in
            NavigationStack {
                BluetoothChatView(device: device)
                    .environmentObject(bluetoothManager)
            }
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { value in
            now = value
        }
    }
}

private extension HomeView {
    func avatarColor(for peerName: String) -> Color {
        let palette: [Color] = [.green, .teal, .brown, .orange, .blue, .indigo, .pink, .purple]
        let hash = abs(peerName.hashValue)
        return palette[hash % max(palette.count, 1)]
    }

    func relativeTimeString(for date: Date, relativeTo now: Date) -> String {
        if abs(now.timeIntervalSince(date)) < 1 {
            return "Just now"
        }
        return Self.relativeFormatter.localizedString(for: date, relativeTo: now)
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environmentObject(BluetoothManager())
}

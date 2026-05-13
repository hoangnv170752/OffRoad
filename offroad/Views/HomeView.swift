//
//  HomeView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @State private var selectedDevice: DiscoveredDevice?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HomeHeaderView(selectedTab: $selectedTab)

                PrivacyBannerView()
                    .padding(.top, 16)

                RecentChatsSection(chats: [])
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
        .sheet(item: $selectedDevice) { device in
            NavigationStack {
                BluetoothChatView(device: device)
                    .environmentObject(bluetoothManager)
            }
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environmentObject(BluetoothManager())
}

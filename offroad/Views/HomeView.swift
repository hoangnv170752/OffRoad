//
//  HomeView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

// MARK: - Mock Data

struct ChatItem: Identifiable {
    let id = UUID()
    let name: String
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let avatarColor: Color
    let isOnline: Bool
}

struct NearbyDevice: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
    let avatarColor: Color
}

// MARK: - HomeView

struct HomeView: View {
    let recentChats: [ChatItem] = [
        ChatItem(name: "Linh Nguyen", lastMessage: "See you at the camp 🔥", time: "Just now", unreadCount: 2, avatarColor: .green, isOnline: true),
        ChatItem(name: "Mountain Crew", lastMessage: "Plan updated for tomorrow.", time: "12m ago", unreadCount: 5, avatarColor: .brown, isOnline: true),
        ChatItem(name: "Alex Tran", lastMessage: "My location: 21.3812, 104.0304", time: "35m ago", unreadCount: 1, avatarColor: .teal, isOnline: false),
        ChatItem(name: "Hiking Buddies", lastMessage: "🖼 Photo", time: "1h ago", unreadCount: 3, avatarColor: .orange, isOnline: true),
    ]

    let nearbyDevices: [NearbyDevice] = [
        NearbyDevice(name: "Linh Nguyen", distance: "5 m", avatarColor: .green),
        NearbyDevice(name: "Alex Tran", distance: "12 m", avatarColor: .teal),
        NearbyDevice(name: "Mountain Crew", distance: "18 m", avatarColor: .brown),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                privacyBanner
                    .padding(.top, 16)
                recentChatsSection
                    .padding(.top, 24)
                nearbyDevicesSection
                    .padding(.top, 24)
                safeVaultCard
                    .padding(.top, 24)
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            HStack(spacing: 10) {
                Image("OffroadLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("OFFROAD")
                        .font(.system(size: 28, weight: .black, design: .default))
                        .tracking(1)
                    Text("Offline. Private. Yours.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            bluetoothStatusBadge
        }
        .padding(.top, 8)
    }

    private var bluetoothStatusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 1) {
                Text("Connected")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.25, blue: 0.20))
                Text("2 nearby")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Privacy Banner

    private var privacyBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.25))
                    Text("Offline & Private")
                        .font(.system(size: 17, weight: .semibold))
                }
                Text("Messages are stored only\non your phone and your\npartner's.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            Spacer()
            ZStack {
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary.opacity(0.3))
                    .offset(x: -14)
                Image(systemName: "iphone.gen3")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary.opacity(0.5))
                    .offset(x: 14)
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 16))
                    .foregroundColor(.blue.opacity(0.6))
            }
            .frame(width: 80)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Recent Chats

    private var recentChatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Chats")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button("See All") {}
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.35))
            }

            VStack(spacing: 0) {
                ForEach(Array(recentChats.enumerated()), id: \.element.id) { index, chat in
                    chatRow(chat: chat)
                    if index < recentChats.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }

    private func chatRow(chat: ChatItem) -> some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(chat.avatarColor.opacity(0.25))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(chat.name.prefix(1)))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(chat.avatarColor)
                    )
                if chat.isOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle().stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(chat.name)
                    .font(.system(size: 15, weight: .semibold))
                Text(chat.lastMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(chat.time)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if chat.unreadCount > 0 {
                Text("\(chat.unreadCount)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.25))
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(Color(red: 0.85, green: 0.93, blue: 0.88))
                    )
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Nearby Devices

    private var nearbyDevicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nearby Devices")
                .font(.system(size: 18, weight: .semibold))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(nearbyDevices) { device in
                        nearbyDeviceItem(device: device)
                    }
                    addScanItem
                }
            }
        }
    }

    private func nearbyDeviceItem(device: NearbyDevice) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(device.avatarColor.opacity(0.25))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(String(device.name.prefix(1)))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(device.avatarColor)
                )
            Text(device.name)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
            Text(device.distance)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(width: 76)
    }

    private var addScanItem: some View {
        VStack(spacing: 6) {
            Circle()
                .strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                )
            Text("Add / Scan")
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
            Text("QR or Invite")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(width: 76)
    }

    // MARK: - Safe Vault

    private var safeVaultCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.25))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.85, green: 0.93, blue: 0.88))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("My Safe Vault")
                    .font(.system(size: 16, weight: .semibold))
                Text("End-to-end encrypted")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {}) {
                Text("Open")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.35))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .strokeBorder(Color(red: 0.15, green: 0.45, blue: 0.35), lineWidth: 1.5)
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    HomeView()
}

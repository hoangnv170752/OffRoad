//
//  ChatsView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct ChatsView: View {
    @Environment(AppSettings.self) private var appSettings
    @EnvironmentObject private var chatStore: ChatStore
    @EnvironmentObject private var bluetoothManager: BluetoothManager

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Group {
                if chatStore.conversations.isEmpty {
                    emptyState
                } else {
                    conversationsList
                }
            }
            .navigationTitle(appSettings.localized("Chats"))
        }
    }

    // MARK: - List

    private var conversationsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(chatStore.conversations.enumerated()), id: \.element.id) { index, stored in
                    NavigationLink(value: stored.id) {
                        StoredConversationRow(
                            stored: stored,
                            isOnline: isPeerOnline(stored.id),
                            timeString: Self.relativeFormatter.localizedString(for: stored.lastUpdated, relativeTo: Date())
                        )
                    }
                    .buttonStyle(.plain)

                    if index < chatStore.conversations.count - 1 {
                        Divider()
                            .padding(.leading, 76)
                    }
                }
            }
        }
        .navigationDestination(for: UUID.self) { peerId in
            ChatDetailView(peerId: peerId)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "lock.shield")
                .font(.system(size: 42))
                .foregroundStyle(.secondary.opacity(0.6))
            Text("No conversations yet")
                .font(.system(size: 17, weight: .semibold))
            Text("Find a friend in Home → Nearby Devices and tap to start a Bluetooth chat. Messages will be stored encrypted on this device.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func isPeerOnline(_ peerId: UUID) -> Bool {
        bluetoothManager.discoveredDevices.contains(where: { $0.peripheralId == peerId })
    }
}

// MARK: - Row

struct StoredConversationRow: View {
    let stored: StoredConversation
    let isOnline: Bool
    let timeString: String

    private var avatarColor: Color {
        let palette: [Color] = [.green, .teal, .brown, .orange, .blue, .indigo, .pink, .purple]
        let hash = abs(stored.peerName.hashValue)
        return palette[hash % max(palette.count, 1)]
    }

    private var lastMessage: String {
        stored.messages.last?.text ?? "No messages"
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(avatarColor.opacity(0.25))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text(String(stored.peerName.prefix(1)))
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(avatarColor)
                    )
                if isOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stored.peerName)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text(timeString)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(lastMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    ChatsView()
        .environment(AppSettings())
        .environmentObject(ChatStore())
        .environmentObject(BluetoothManager())
}

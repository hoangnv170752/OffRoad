//
//  ChatDetailView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct ChatDetailView: View {
    let peerId: UUID
    @EnvironmentObject private var chatStore: ChatStore
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""

    private var stored: StoredConversation? {
        chatStore.conversation(for: peerId)
    }

    private var messages: [Message] {
        stored?.messages ?? []
    }

    private var peerName: String {
        stored?.peerName ?? "Unknown"
    }

    private var isLive: Bool {
        bluetoothManager.isConnected && bluetoothManager.activePeerId == peerId
    }

    private var isInRange: Bool {
        bluetoothManager.discoveredDevices.contains(where: { $0.peripheralId == peerId })
    }

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            encryptionNotice
            messagesList
            connectionStatus
            inputBar
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(red: 0.15, green: 0.35, blue: 0.25))
            }

            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(avatarColor.opacity(0.25))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(peerName.prefix(1)))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(avatarColor)
                    )
                if isInRange {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 1.5))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(peerName)
                    .font(.system(size: 16, weight: .semibold))
                Text(isInRange ? "Online (Nearby)" : "Offline")
                    .font(.system(size: 12))
                    .foregroundStyle(isInRange ? Color.green : .secondary)
            }

            Spacer()

            if isLive {
                Button(action: { bluetoothManager.disconnect() }) {
                    Image(systemName: "antenna.radiowaves.left.and.right.slash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Disconnect")
            } else if isInRange {
                Button(action: reconnect) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(red: 0.15, green: 0.35, blue: 0.25))
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Reconnect")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Encryption Notice

    private var encryptionNotice: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text("Stored & encrypted on this device only")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Messages

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    if messages.isEmpty {
                        Text("No messages yet.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.top, 20)
                    }
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onAppear {
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
            .onChange(of: messages.count) {
                if let last = messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Connection Status

    private var connectionStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: isLive ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isLive ? .green : .orange)
            Text(isLive ? "Connected" : (isInRange ? "Nearby — tap antenna to reconnect" : "Out of range"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(isLive ? Color(red: 0.15, green: 0.35, blue: 0.25) : .orange)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Input

    private var inputBar: some View {
        ChatInputBar(text: $messageText, onSend: sendMessage)
            .opacity(isLive ? 1.0 : 0.55)
            .disabled(!isLive)
    }

    // MARK: - Actions

    private var avatarColor: Color {
        let palette: [Color] = [.green, .teal, .brown, .orange, .blue, .indigo, .pink, .purple]
        let hash = abs(peerName.hashValue)
        return palette[hash % max(palette.count, 1)]
    }

    private func sendMessage() {
        guard isLive else { return }
        bluetoothManager.sendMessage(messageText)
        messageText = ""
    }

    private func reconnect() {
        guard let device = bluetoothManager.discoveredDevices.first(where: { $0.peripheralId == peerId }) else { return }
        bluetoothManager.connect(to: device)
    }
}

#Preview {
    NavigationStack {
        ChatDetailView(peerId: UUID())
            .environmentObject(ChatStore())
            .environmentObject(BluetoothManager())
    }
}

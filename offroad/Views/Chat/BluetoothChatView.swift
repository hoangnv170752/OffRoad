//
//  BluetoothChatView.swift
//  offroad
//
//  Created by Codex on 13/5/26.
//

import SwiftUI

struct BluetoothChatView: View {
    let device: DiscoveredDevice
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    @EnvironmentObject private var chatStore: ChatStore
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""

    private var messages: [Message] {
        chatStore.messages(for: device.peripheralId)
    }

    var body: some View {
        VStack(spacing: 0) {
            statusBanner
            encryptionNotice
            messageList
            ChatInputBar(text: $messageText, onSend: sendMessage)
        }
        .navigationTitle(bluetoothManager.activePeerName ?? device.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if bluetoothManager.isConnected {
                    Button("Disconnect") {
                        bluetoothManager.disconnect()
                    }
                }
            }
        }
        .onAppear {
            bluetoothManager.connect(to: device)
        }
        .alert("Bluetooth Error", isPresented: Binding(
            get: { bluetoothManager.lastErrorMessage != nil },
            set: { newValue in
                if !newValue { bluetoothManager.lastErrorMessage = nil }
            }
        )) {
            Button("OK", role: .cancel) { bluetoothManager.lastErrorMessage = nil }
        } message: {
            Text(bluetoothManager.lastErrorMessage ?? "")
        }
    }

    // MARK: - Header & Status

    private var statusBanner: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(bluetoothManager.isConnected ? .green : .orange)
                .frame(width: 10, height: 10)

            Text(bluetoothManager.isConnected ? "Connected via Bluetooth" : "Connecting...")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(bluetoothManager.isConnected ? Color.green : Color.orange)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }

    private var encryptionNotice: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text("Stored & encrypted on this device only")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    // MARK: - Messages

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    if messages.isEmpty {
                        Text("No messages yet. Say hello 👋")
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
            .onChange(of: messages.count) {
                if let last = messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Actions

    private func sendMessage() {
        bluetoothManager.sendMessage(messageText)
        messageText = ""
    }
}

#Preview {
    NavigationStack {
        BluetoothChatView(
            device: DiscoveredDevice(
                peripheralId: UUID(),
                name: "Nearby User",
                rssi: -52,
                distance: "~2 m",
                lastSeen: Date(),
                isConnected: false
            )
        )
        .environmentObject(BluetoothManager())
        .environmentObject(ChatStore())
    }
}

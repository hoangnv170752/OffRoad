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
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""

    var body: some View {
        VStack(spacing: 0) {
            statusBanner
            messageList
            ChatInputBar(text: $messageText, onSend: sendMessage)
        }
        .navigationTitle(bluetoothManager.activePeerName ?? device.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
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
            bluetoothManager.clearLiveMessages()
            bluetoothManager.connect(to: device)
        }
        .alert("Bluetooth Error", isPresented: Binding(
            get: { bluetoothManager.lastErrorMessage != nil },
            set: { newValue in
                if !newValue {
                    bluetoothManager.lastErrorMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) { bluetoothManager.lastErrorMessage = nil }
        } message: {
            Text(bluetoothManager.lastErrorMessage ?? "")
        }
    }

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

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    if bluetoothManager.liveMessages.isEmpty {
                        Text("No messages yet. Say hello 👋")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.top, 20)
                    }
                    ForEach(bluetoothManager.liveMessages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: bluetoothManager.liveMessages.count) {
                if let last = bluetoothManager.liveMessages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

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
    }
}

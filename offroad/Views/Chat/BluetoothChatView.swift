import SwiftUI

struct BluetoothChatView: View {
    let device: DiscoveredDevice
    @EnvironmentObject private var bluetoothManager: BluetoothManager
    @EnvironmentObject private var chatStore: ChatStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.hideTabBar) private var hideTabBar
    @State private var messageText = ""
    @State private var isDeleteConfirmationPresented = false

    private var messages: [Message] {
        chatStore.messages(for: device.peripheralId)
    }

    var body: some View {
        VStack(spacing: 0) {
            statusBanner
            encryptionNotice
            messageList
            ChatInputBar(text: $messageText, onSend: sendMessage, onSendImage: sendImage)
        }
        .navigationTitle(bluetoothManager.activePeerName ?? device.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    isDeleteConfirmationPresented = true
                } label: {
                    Image(systemName: "trash")
                }

                if bluetoothManager.isConnected {
                    Button("Disconnect") {
                        bluetoothManager.disconnect()
                    }
                }
            }
        }
        .onAppear {
            withAnimation { hideTabBar.wrappedValue = true }
            bluetoothManager.connect(to: device)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                bluetoothManager.sendConnectRequest()
            }
        }
        .onDisappear {
            withAnimation { hideTabBar.wrappedValue = false }
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
        .confirmationDialog("Delete all messages in this chat?", isPresented: $isDeleteConfirmationPresented) {
            Button("Delete Chat", role: .destructive) {
                deleteCurrentConversation()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
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

    private func sendImage(_ data: Data) {
        bluetoothManager.sendImage(data)
    }

    private func deleteCurrentConversation() {
        let existingMessages = chatStore.messages(for: device.peripheralId)
        for message in existingMessages {
            if let fileName = message.attachmentFileName {
                ChatAttachmentStore.shared.delete(fileName: fileName)
            }
        }
        chatStore.deleteConversation(peerId: device.peripheralId)
        dismiss()
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

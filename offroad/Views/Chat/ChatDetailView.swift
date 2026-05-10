//
//  ChatDetailView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct ChatDetailView: View {
    let conversation: Conversation
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            encryptionNotice
            messagesList
            connectionStatus
            ChatInputBar(text: $messageText, onSend: sendMessage)
        }
        .navigationBarHidden(true)
        .onAppear {
            messages = conversation.messages
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.35, blue: 0.25))
            }

            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(conversation.avatarColor.opacity(0.25))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(conversation.name.prefix(1)))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(conversation.avatarColor)
                    )
                if conversation.isOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 1.5))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(conversation.name)
                    .font(.system(size: 16, weight: .semibold))
                Text(conversation.isNearby ? "Online (Nearby)" : "Offline")
                    .font(.system(size: 12))
                    .foregroundColor(conversation.isNearby ? .green : .secondary)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
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
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text("Messages are end-to-end encrypted")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Messages List

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .onChange(of: messages.count) {
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Connection Status

    private var connectionStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(conversation.isNearby ? .green : .orange)
            Text(conversation.isNearby ? "Connected" : "Out of range")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(conversation.isNearby ? Color(red: 0.15, green: 0.35, blue: 0.25) : .orange)

            if conversation.isNearby {
                Image(systemName: "cellularbars")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
                Text("Good signal")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Actions

    private func sendMessage() {
        let newMessage = Message(text: messageText, isFromMe: true, timestamp: Date())
        withAnimation(.easeInOut(duration: 0.15)) {
            messages.append(newMessage)
        }
        messageText = ""
    }
}

#Preview {
    NavigationStack {
        ChatDetailView(conversation: Conversation.mockData[0])
    }
}

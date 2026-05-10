//
//  ChatsView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct ChatsView: View {
    @Environment(AppSettings.self) var appSettings
    let conversations: [Conversation] = Conversation.mockData

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(conversations.enumerated()), id: \.element.id) { index, conversation in
                        NavigationLink(destination: ChatDetailView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                        .buttonStyle(.plain)

                        if index < conversations.count - 1 {
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
            }
            .navigationTitle(appSettings.localized("Chats"))
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(conversation.avatarColor.opacity(0.25))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text(String(conversation.name.prefix(1)))
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundColor(conversation.avatarColor)
                    )
                if conversation.isOnline {
                    Circle()
                        .fill(.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle().stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.name)
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Text(conversation.time)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text(conversation.lastMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(
                                Circle()
                                    .fill(Color(red: 0.15, green: 0.40, blue: 0.30))
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    ChatsView()
}

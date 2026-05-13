//
//  RecentChatsSection.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct RecentChatsSection: View {
    let chats: [ChatItem]

    var body: some View {
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
                ForEach(Array(chats.enumerated()), id: \.element.id) { index, chat in
                    NavigationLink(value: chat.id) {
                        ChatRowView(chat: chat)
                    }
                    .buttonStyle(.plain)
                    if index < chats.count - 1 {
                        Divider()
                            .padding(.leading, 76)
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
}

#Preview {
    RecentChatsSection(chats: ChatItem.mockData)
        .padding()
}

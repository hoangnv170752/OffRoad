//
//  ChatRowView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct ChatRowView: View {
    let chat: ChatItem

    var body: some View {
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
}

#Preview {
    ChatRowView(chat: ChatItem.mockData[0])
        .padding()
}

//
//  ChatItem.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct ChatItem: Identifiable {
    let id: UUID
    let name: String
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let avatarColor: Color
    let isOnline: Bool

    init(
        id: UUID = UUID(),
        name: String,
        lastMessage: String,
        time: String,
        unreadCount: Int,
        avatarColor: Color,
        isOnline: Bool
    ) {
        self.id = id
        self.name = name
        self.lastMessage = lastMessage
        self.time = time
        self.unreadCount = unreadCount
        self.avatarColor = avatarColor
        self.isOnline = isOnline
    }
}

extension ChatItem {
    static let mockData: [ChatItem] = [
        ChatItem(name: "Linh Nguyen", lastMessage: "See you at the camp 🔥", time: "Just now", unreadCount: 2, avatarColor: .green, isOnline: true),
        ChatItem(name: "Mountain Crew", lastMessage: "Plan updated for tomorrow.", time: "12m ago", unreadCount: 5, avatarColor: .brown, isOnline: true),
        ChatItem(name: "Alex Tran", lastMessage: "My location: 21.3812, 104.0304", time: "35m ago", unreadCount: 1, avatarColor: .teal, isOnline: false),
        ChatItem(name: "Hiking Buddies", lastMessage: "🖼 Photo", time: "1h ago", unreadCount: 3, avatarColor: .orange, isOnline: true),
    ]
}

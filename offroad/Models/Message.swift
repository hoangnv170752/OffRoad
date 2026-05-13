//
//  Message.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct Message: Identifiable, Codable, Hashable {
    let id: UUID
    let text: String
    let isFromMe: Bool
    let timestamp: Date
    let isImage: Bool
    let attachmentFileName: String?

    init(
        id: UUID = UUID(),
        text: String,
        isFromMe: Bool,
        timestamp: Date = Date(),
        isImage: Bool = false,
        attachmentFileName: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isFromMe = isFromMe
        self.timestamp = timestamp
        self.isImage = isImage
        self.attachmentFileName = attachmentFileName
    }
}

struct Conversation: Identifiable {
    let id: UUID
    let name: String
    let avatarColor: Color
    let isOnline: Bool
    let isNearby: Bool
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let messages: [Message]

    init(
        id: UUID = UUID(),
        name: String,
        avatarColor: Color,
        isOnline: Bool,
        isNearby: Bool,
        lastMessage: String,
        time: String,
        unreadCount: Int,
        messages: [Message]
    ) {
        self.id = id
        self.name = name
        self.avatarColor = avatarColor
        self.isOnline = isOnline
        self.isNearby = isNearby
        self.lastMessage = lastMessage
        self.time = time
        self.unreadCount = unreadCount
        self.messages = messages
    }
}

extension Conversation {
    static let mockData: [Conversation] = [
        Conversation(
            name: "Linh Nguyen",
            avatarColor: .green,
            isOnline: true,
            isNearby: true,
            lastMessage: "Yeah! Just arrived.",
            time: "Just now",
            unreadCount: 2,
            messages: [
                Message(text: "Hey! Are you at the campsite?", isFromMe: true, timestamp: Calendar.current.date(byAdding: .minute, value: -10, to: Date())!),
                Message(text: "Yeah! Just arrived.", isFromMe: false, timestamp: Calendar.current.date(byAdding: .minute, value: -8, to: Date())!),
                Message(text: "Perfect! We'll start dinner soon 🍳", isFromMe: true, timestamp: Calendar.current.date(byAdding: .minute, value: -5, to: Date())!),
                Message(text: "Cool, see you in a bit!", isFromMe: false, timestamp: Calendar.current.date(byAdding: .minute, value: -3, to: Date())!),
                Message(text: "campsite_photo", isFromMe: false, timestamp: Calendar.current.date(byAdding: .minute, value: -1, to: Date())!, isImage: true),
            ]
        ),
        Conversation(
            name: "Mountain Crew",
            avatarColor: .brown,
            isOnline: true,
            isNearby: true,
            lastMessage: "Plan updated for tomorrow.",
            time: "12m ago",
            unreadCount: 5,
            messages: [
                Message(text: "Hey everyone, change of plans", isFromMe: false, timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!),
                Message(text: "We'll take the east trail instead", isFromMe: false, timestamp: Calendar.current.date(byAdding: .minute, value: -28, to: Date())!),
                Message(text: "Sounds good to me 👍", isFromMe: true, timestamp: Calendar.current.date(byAdding: .minute, value: -25, to: Date())!),
                Message(text: "Plan updated for tomorrow.", isFromMe: false, timestamp: Calendar.current.date(byAdding: .minute, value: -12, to: Date())!),
            ]
        ),
        Conversation(
            name: "Alex Tran",
            avatarColor: .teal,
            isOnline: false,
            isNearby: false,
            lastMessage: "My location: 21.3812, 104.0304",
            time: "35m ago",
            unreadCount: 1,
            messages: [
                Message(text: "Where are you?", isFromMe: true, timestamp: Calendar.current.date(byAdding: .minute, value: -40, to: Date())!),
                Message(text: "My location: 21.3812, 104.0304", isFromMe: false, timestamp: Calendar.current.date(byAdding: .minute, value: -35, to: Date())!),
            ]
        ),
        Conversation(
            name: "Hiking Buddies",
            avatarColor: .orange,
            isOnline: true,
            isNearby: false,
            lastMessage: "🖼 Photo",
            time: "1h ago",
            unreadCount: 3,
            messages: [
                Message(text: "Check out this view! 🏔", isFromMe: false, timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!),
                Message(text: "mountain_view", isFromMe: false, timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, isImage: true),
                Message(text: "Wow, amazing!", isFromMe: true, timestamp: Calendar.current.date(byAdding: .minute, value: -55, to: Date())!),
            ]
        ),
    ]
}

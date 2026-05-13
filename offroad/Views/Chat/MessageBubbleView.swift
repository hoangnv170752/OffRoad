//
//  MessageBubbleView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromMe { Spacer(minLength: 60) }

            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
                if message.isImage {
                    imageBubble
                } else {
                    textBubble
                }

                TimelineView(.periodic(from: .now, by: 30)) { context in
                    Text(Self.relativeTimeString(for: message.timestamp, relativeTo: context.date))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
            }

            if !message.isFromMe { Spacer(minLength: 60) }
        }
    }

    private var textBubble: some View {
        Text(message.text)
            .font(.system(size: 15))
            .foregroundColor(message.isFromMe ? .white : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                message.isFromMe
                    ? Color(red: 0.15, green: 0.40, blue: 0.30)
                    : Color(.systemGray6)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var imageBubble: some View {
        Group {
            if let fileName = message.attachmentFileName {
                AsyncImage(url: ChatAttachmentStore.shared.fileURL(fileName: fileName)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderImageBubble
                    case .empty:
                        placeholderImageBubble
                    @unknown default:
                        placeholderImageBubble
                    }
                }
            } else {
                placeholderImageBubble
            }
        }
        .frame(width: 200, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var placeholderImageBubble: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [.green.opacity(0.3), .brown.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "photo.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
            )
    }

    private static func relativeTimeString(for date: Date, relativeTo now: Date) -> String {
        if abs(now.timeIntervalSince(date)) < 1 {
            return "Just now"
        }
        return relativeFormatter.localizedString(for: date, relativeTo: now)
    }
}

#Preview {
    VStack(spacing: 12) {
        MessageBubbleView(message: Message(text: "Hey there!", isFromMe: false))
        MessageBubbleView(message: Message(text: "Hi! How are you?", isFromMe: true))
        MessageBubbleView(message: Message(text: "photo", isFromMe: false, isImage: true))
    }
    .padding()
}

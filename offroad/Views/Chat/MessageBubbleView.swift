//
//  MessageBubbleView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.timestamp)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromMe { Spacer(minLength: 60) }

            VStack(alignment: message.isFromMe ? .trailing : .leading, spacing: 4) {
                if message.isImage {
                    imageBubble
                } else {
                    textBubble
                }

                Text(timeString)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
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
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [.green.opacity(0.3), .brown.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 200, height: 150)
            .overlay(
                Image(systemName: "photo.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
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

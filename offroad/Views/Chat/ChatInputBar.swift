//
//  ChatInputBar.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    var onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(red: 0.15, green: 0.40, blue: 0.30))
            }

            HStack {
                TextField("Type a message...", text: $text)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            .background(Color(.systemGray6))
            .clipShape(Capsule())

            Button(action: {
                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    onSend()
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(
                        text.trimmingCharacters(in: .whitespaces).isEmpty
                            ? .secondary
                            : Color(red: 0.15, green: 0.40, blue: 0.30)
                    )
                    .rotationEffect(.degrees(45))
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
    }
}

#Preview {
    ChatInputBar(text: .constant("Hello")) {
        print("Send")
    }
}

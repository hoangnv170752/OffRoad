//
//  ChatsView.swift
//  offroad
//
//  Created by Hoang Nguyen Van on 10/5/26.
//

import SwiftUI

struct ChatsView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("No chats yet")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Chats")
        }
    }
}

#Preview {
    ChatsView()
}

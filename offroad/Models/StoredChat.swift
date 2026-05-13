//
//  StoredChat.swift
//  offroad
//
//  Created by Codex on 13/5/26.
//

import Foundation

struct StoredConversation: Codable, Identifiable, Hashable {
    let id: UUID
    var peerName: String
    var messages: [Message]
    var lastUpdated: Date

    init(
        id: UUID,
        peerName: String,
        messages: [Message] = [],
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.peerName = peerName
        self.messages = messages
        self.lastUpdated = lastUpdated
    }
}

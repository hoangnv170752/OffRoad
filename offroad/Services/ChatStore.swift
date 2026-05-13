import Foundation
import CryptoKit
import Combine

/// Persists chat history on device with AES-GCM encryption.
/// The encryption key is held in the Keychain (device-only) by `SymmetricKeyStore`.
/// The encrypted blob is written to Application Support with `.completeFileProtection`,
/// so the data is unreadable while the device is locked.
final class ChatStore: ObservableObject {
    @Published private(set) var conversations: [StoredConversation] = []

    private let key: SymmetricKey
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.offroad.chatstore", qos: .userInitiated)

    init(key: SymmetricKey? = nil, fileURL: URL? = nil) {
        self.key = key ?? SymmetricKeyStore.shared.loadOrCreate()
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.conversations = Self.loadFromDisk(at: self.fileURL, using: self.key)
    }

    // MARK: - Reading

    func messages(for peerId: UUID) -> [Message] {
        conversations.first(where: { $0.id == peerId })?.messages ?? []
    }

    func conversation(for peerId: UUID) -> StoredConversation? {
        conversations.first(where: { $0.id == peerId })
    }

    // MARK: - Writing

    func append(_ message: Message, peerId: UUID, peerName: String) {
        if let index = conversations.firstIndex(where: { $0.id == peerId }) {
            conversations[index].messages.append(message)
            conversations[index].lastUpdated = message.timestamp
            if !peerName.isEmpty {
                conversations[index].peerName = peerName
            }
        } else {
            let conversation = StoredConversation(
                id: peerId,
                peerName: peerName,
                messages: [message],
                lastUpdated: message.timestamp
            )
            conversations.append(conversation)
        }

        conversations.sort { $0.lastUpdated > $1.lastUpdated }
        persist()
    }

    func deleteConversation(peerId: UUID) {
        conversations.removeAll { $0.id == peerId }
        persist()
    }

    func clearAll() {
        conversations.removeAll()
        persist()
    }

    // MARK: - Persistence

    private func persist() {
        let snapshot = conversations
        let key = self.key
        let url = self.fileURL

        queue.async {
            do {
                let data = try JSONEncoder().encode(snapshot)
                let sealed = try AES.GCM.seal(data, using: key)
                guard let combined = sealed.combined else { return }
                try combined.write(to: url, options: [.atomic, .completeFileProtection])
            } catch {
                #if DEBUG
                print("ChatStore.persist failed: \(error)")
                #endif
            }
        }
    }

    private static func loadFromDisk(at url: URL, using key: SymmetricKey) -> [StoredConversation] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let blob = try Data(contentsOf: url)
            guard !blob.isEmpty else { return [] }
            let box = try AES.GCM.SealedBox(combined: blob)
            let plaintext = try AES.GCM.open(box, using: key)
            return try JSONDecoder().decode([StoredConversation].self, from: plaintext)
        } catch {
            #if DEBUG
            print("ChatStore.load failed: \(error)")
            #endif
            return []
        }
    }

    private static func defaultFileURL() -> URL {
        let fm = FileManager.default
        let directory: URL
        if let supportDir = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            directory = supportDir
        } else {
            directory = fm.temporaryDirectory
        }
        return directory.appendingPathComponent("offroad-chats.enc")
    }
}

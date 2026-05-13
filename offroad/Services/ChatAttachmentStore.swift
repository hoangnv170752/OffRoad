import Foundation

final class ChatAttachmentStore {
    static let shared = ChatAttachmentStore()

    private let directoryURL: URL

    private init() {
        let fm = FileManager.default
        let baseURL: URL
        if let support = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            baseURL = support
        } else {
            baseURL = fm.temporaryDirectory
        }

        directoryURL = baseURL.appendingPathComponent("chat-attachments", isDirectory: true)
        try? fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    func save(data: Data, suggestedFileName: String) throws -> String {
        let sanitized = suggestedFileName.replacingOccurrences(of: "/", with: "_")
        let url = directoryURL.appendingPathComponent(sanitized)
        try data.write(to: url, options: [.atomic, .completeFileProtection])
        return sanitized
    }

    func loadData(fileName: String) -> Data? {
        let url = directoryURL.appendingPathComponent(fileName)
        return try? Data(contentsOf: url)
    }

    func fileURL(fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName)
    }

    func delete(fileName: String) {
        let url = directoryURL.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}

//
//  SymmetricKeyStore.swift
//  offroad
//
//  Created by Codex on 13/5/26.
//

import Foundation
import CryptoKit
import Security

/// Stores a single device-only AES-256 key in the iOS Keychain.
/// The key never leaves the device — no iCloud sync, accessible only after first unlock.
final class SymmetricKeyStore {
    static let shared = SymmetricKeyStore()

    private let service = "com.offroad.chats"
    private let account = "device-symmetric-key"

    private init() {}

    func loadOrCreate() -> SymmetricKey {
        if let data = read() {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        let raw = key.withUnsafeBytes { Data($0) }
        save(raw)
        return key
    }

    private func read() -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return data
    }

    private func save(_ data: Data) {
        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(attributes as CFDictionary)
        SecItemAdd(attributes as CFDictionary, nil)
    }
}

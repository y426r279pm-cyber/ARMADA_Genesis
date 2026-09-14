import Foundation
import Security

/// API keys, in the Keychain.
///
/// The prototype keeps keys in browser storage, which is the only option a
/// single HTML file has. Here they sit in the Keychain, encrypted at rest and
/// unreadable by other applications — which is the difference between a
/// prototype that demonstrates a key field and a console that can hold one.
///
/// `.whenUnlockedThisDeviceOnly` deliberately: a key that syncs to iCloud has
/// left the machine it was entered on, which is exactly what this product
/// promises does not happen.
public enum Keychain {
    static let service = "ai.armada.bridge.rails"

    public static func set(_ value: String, for account: String) throws {
        try remove(account)
        guard !value.isEmpty else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.status(status) }
    }

    public static func get(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func remove(_ account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.status(status)
        }
    }

    /// Whether a key exists, without reading it.
    ///
    /// Settings needs to show that a rail is configured; it does not need the
    /// key itself, and reading one to draw a checkmark is how secrets end up in
    /// logs and screenshots.
    public static func has(_ account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        return SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess
    }

    public enum KeychainError: Error, Equatable {
        case status(OSStatus)
    }
}

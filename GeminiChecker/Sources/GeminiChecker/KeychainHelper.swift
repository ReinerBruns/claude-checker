import Foundation
import Security

public struct AntigravityKeyringAuth: Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiry: Date?
    public let email: String?
}

public enum KeychainHelper {
    private static let serviceName = "gemini"
    private static let accountName = "antigravity"
    private static let lock = NSLock()
    private static var cachedAuth: AntigravityKeyringAuth?

    /// Loads the stored Antigravity token from the macOS Keychain
    public static func loadAntigravityAuth(forceReload: Bool = false) -> AntigravityKeyringAuth? {
        lock.lock()
        defer { lock.unlock() }

        if !forceReload, let cached = cachedAuth {
            return cached
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let rawString = String(data: data, encoding: .utf8) else {
            return nil
        }

        let auth = parseKeyringPayload(rawString)
        cachedAuth = auth
        return auth
    }

    private static func parseKeyringPayload(_ raw: String) -> AntigravityKeyringAuth? {
        var base64Part = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if base64Part.hasPrefix("go-keyring-base64:") {
            base64Part = String(base64Part.dropFirst("go-keyring-base64:".count))
        }

        guard let jsonData = Data(base64Encoded: base64Part),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        let email = json["id_token_email"] as? String

        guard let tokenObj = json["token"] as? [String: Any],
              let accessToken = tokenObj["access_token"] as? String else {
            return nil
        }

        let refreshToken = tokenObj["refresh_token"] as? String

        var expiryDate: Date?
        if let expiryStr = tokenObj["expiry"] as? String {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            expiryDate = iso.date(from: expiryStr)
            if expiryDate == nil {
                let simpleIso = ISO8601DateFormatter()
                expiryDate = simpleIso.date(from: expiryStr)
            }
        }

        return AntigravityKeyringAuth(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiry: expiryDate,
            email: email
        )
    }
}

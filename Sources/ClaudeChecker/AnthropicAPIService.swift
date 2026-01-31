import Foundation

final class ClaudeWebAPIService {
    private let baseURL = "https://claude.ai/api"
    private var sessionKey: String?
    private var organizationId: String?

    init(sessionKey: String? = nil) {
        self.sessionKey = sessionKey ?? KeychainHelper.load()
    }

    func setSessionKey(_ key: String) {
        self.sessionKey = key
        self.organizationId = nil // Reset org when key changes
    }

    /// Fetches plan usage data (session + weekly limits) from claude.ai
    func fetchUsage() async throws -> ClaudeUsageData {
        guard let sessionKey = sessionKey, !sessionKey.isEmpty else {
            throw ClaudeWebError.missingSessionKey
        }

        // Get org ID (cached after first call)
        if organizationId == nil {
            organizationId = try await fetchOrganizationId()
        }

        guard let orgId = organizationId else {
            throw ClaudeWebError.noOrganization
        }

        // GET /api/organizations/{orgId}/usage
        guard let url = URL(string: "\(baseURL)/organizations/\(orgId)/usage") else {
            throw ClaudeWebError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeWebError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try parseUsageResponse(data)
        case 401, 403:
            throw ClaudeWebError.sessionExpired
        case 429:
            throw ClaudeWebError.rateLimited
        default:
            throw ClaudeWebError.httpError(httpResponse.statusCode)
        }
    }

    /// Validates a session key by trying to fetch organizations
    func validateSessionKey(_ key: String) async throws -> Bool {
        let previous = sessionKey
        sessionKey = key
        do {
            _ = try await fetchOrganizationId()
            return true
        } catch ClaudeWebError.sessionExpired {
            sessionKey = previous
            organizationId = nil
            return false
        } catch {
            sessionKey = previous
            organizationId = nil
            throw error
        }
    }

    // MARK: - Private

    private func fetchOrganizationId() async throws -> String {
        guard let sessionKey = sessionKey else {
            throw ClaudeWebError.missingSessionKey
        }

        guard let url = URL(string: "\(baseURL)/organizations") else {
            throw ClaudeWebError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeWebError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw ClaudeWebError.sessionExpired
            }
            throw ClaudeWebError.httpError(httpResponse.statusCode)
        }

        guard let orgs = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstOrg = orgs.first,
              let uuid = firstOrg["uuid"] as? String else {
            throw ClaudeWebError.noOrganization
        }

        return uuid
    }

    private func parseUsageResponse(_ data: Data) throws -> ClaudeUsageData {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ClaudeWebError.parseError
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let formatterNoFrac = ISO8601DateFormatter()
        formatterNoFrac.formatOptions = [.withInternetDateTime]

        func parseDate(_ string: String) -> Date? {
            formatter.date(from: string) ?? formatterNoFrac.date(from: string)
        }

        // Session (five_hour)
        var sessionPercent = 0.0
        var sessionReset: Date?
        if let fiveHour = json["five_hour"] as? [String: Any] {
            sessionPercent = parseUtilization(fiveHour["utilization"])
            if let resetStr = fiveHour["resets_at"] as? String {
                sessionReset = parseDate(resetStr)
            }
        }

        // Weekly (seven_day)
        var weeklyPercent = 0.0
        var weeklyReset: Date?
        if let sevenDay = json["seven_day"] as? [String: Any] {
            weeklyPercent = parseUtilization(sevenDay["utilization"])
            if let resetStr = sevenDay["resets_at"] as? String {
                weeklyReset = parseDate(resetStr)
            }
        }

        return ClaudeUsageData(
            sessionPercent: sessionPercent,
            sessionResetTime: sessionReset,
            weeklyPercent: weeklyPercent,
            weeklyResetTime: weeklyReset
        )
    }

    private func parseUtilization(_ value: Any?) -> Double {
        guard let value = value else { return 0 }
        if let intVal = value as? Int { return Double(intVal) }
        if let doubleVal = value as? Double { return doubleVal }
        if let strVal = value as? String,
           let parsed = Double(strVal.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) {
            return parsed
        }
        return 0
    }
}

enum ClaudeWebError: LocalizedError {
    case missingSessionKey
    case invalidURL
    case invalidResponse
    case sessionExpired
    case noOrganization
    case rateLimited
    case parseError
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .missingSessionKey:
            return "Session-Key nicht konfiguriert"
        case .invalidURL:
            return "Ungueltige URL"
        case .invalidResponse:
            return "Ungueltige Server-Antwort"
        case .sessionExpired:
            return "Session abgelaufen – bitte neuen Session-Key eingeben"
        case .noOrganization:
            return "Keine Organisation gefunden"
        case .rateLimited:
            return "Zu viele Anfragen – bitte warten"
        case .parseError:
            return "Antwort konnte nicht verarbeitet werden"
        case .httpError(let code):
            return "HTTP-Fehler: \(code)"
        }
    }
}

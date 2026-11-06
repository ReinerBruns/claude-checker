import Foundation

public final class GeminiAPIService: @unchecked Sendable {
    private let agyBinaryPaths = [
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin/agy").path,
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gemini/bin/agy").path,
        "/usr/local/bin/agy",
        "/opt/homebrew/bin/agy",
        "/usr/bin/agy"
    ]

    private let dailyEndpoint = "https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary"
    private let userAgent = "antigravity/hub/2.9.1 darwin/arm64"

    public init() {}

    /// Fetches live quota data for Gemini, Argon, and Claude/GPT
    public func fetchUsage() async throws -> GeminiUsageData {
        // Try agy CLI first because it includes all aggregated buckets (Gemini, Claude, and Argon)
        do {
            let cliResult = try await fetchViaCLI()
            return cliResult
        } catch {
            print("[GeminiChecker] CLI-Abfrage nicht erfolgreich (\(error.localizedDescription)), nutze HTTP-Fallback...")
            return try await fetchViaHTTP()
        }
    }

    // MARK: - CLI Fetcher

    private func fetchViaCLI() async throws -> GeminiUsageData {
        guard let binaryPath = findAgyBinary(), FileManager.default.isExecutableFile(atPath: binaryPath) else {
            throw GeminiAPIError.agyBinaryNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: binaryPath)
                process.arguments = ["--output-format", "json", "-p", "/usage"]

                // Build a clean environment without internal Antigravity subagent session variables
                var cleanEnv = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("ANTIGRAVITY_") }
                let home = FileManager.default.homeDirectoryForCurrentUser.path
                cleanEnv["PATH"] = "\(home)/.local/bin:\(home)/.gemini/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
                process.environment = cleanEnv

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe

                do {
                    try process.run()

                    // Read pipes before waitUntilExit
                    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    let _ = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()

                    guard process.terminationStatus == 0, !stdoutData.isEmpty else {
                        continuation.resume(throwing: GeminiAPIError.cliExecutionFailed("Exit-Code \(process.terminationStatus)"))
                        return
                    }

                    let parsed = try self.parseCLIUsage(stdoutData)
                    continuation.resume(returning: parsed)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func findAgyBinary() -> String? {
        for path in agyBinaryPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    private func parseCLIUsage(_ data: Data) throws -> GeminiUsageData {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let command = json["command"] as? [String: Any],
              let cmdData = command["data"] as? [String: Any] else {
            throw GeminiAPIError.parseError("Ungültiges JSON-Format der CLI-Antwort")
        }

        let description = cmdData["description"] as? String
        let groupsArray = cmdData["groups"] as? [[String: Any]] ?? []

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let simpleIso = ISO8601DateFormatter()
        simpleIso.formatOptions = [.withInternetDateTime]

        func parseDate(_ str: String?) -> Date? {
            guard let str = str else { return nil }
            return iso.date(from: str) ?? simpleIso.date(from: str)
        }

        var parsedGroups: [QuotaGroup] = []

        for groupDict in groupsArray {
            let gName = groupDict["name"] as? String ?? "Unbekannt"
            let gDesc = groupDict["description"] as? String
            let bucketsArray = groupDict["buckets"] as? [[String: Any]] ?? []

            var parsedBuckets: [QuotaBucket] = []
            for bDict in bucketsArray {
                let bId = bDict["id"] as? String ?? UUID().uuidString
                let bName = bDict["name"] as? String ?? bId
                let bDesc = bDict["description"] as? String
                let window = bDict["window"] as? String
                let remFraction = bDict["remaining_fraction"] as? Double ?? 1.0
                let resetDate = parseDate(bDict["reset_time"] as? String)

                parsedBuckets.append(QuotaBucket(
                    id: bId,
                    name: bName,
                    bucketDescription: bDesc,
                    window: window,
                    remainingFraction: remFraction,
                    resetTime: resetDate
                ))
            }

            parsedGroups.append(QuotaGroup(
                name: gName,
                groupDescription: gDesc,
                buckets: parsedBuckets
            ))
        }

        return GeminiUsageData(
            groups: parsedGroups,
            accountEmail: KeychainHelper.loadAntigravityAuth()?.email,
            accountPlan: "Google AI Pro",
            generalDescription: description
        )
    }

    // MARK: - Direct HTTP Fetcher

    private func fetchViaHTTP() async throws -> GeminiUsageData {
        guard let auth = KeychainHelper.loadAntigravityAuth() else {
            throw GeminiAPIError.notLoggedIn
        }

        guard let url = URL(string: dailyEndpoint) else {
            throw GeminiAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(auth.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let body: [String: Any] = ["project": "aicode-consumers"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw GeminiAPIError.httpError(httpResponse.statusCode)
        }

        return try parseHTTPUsageResponse(data, email: auth.email)
    }

    private func parseHTTPUsageResponse(_ data: Data, email: String?) throws -> GeminiUsageData {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiAPIError.parseError("JSON-Parsing fehlgeschlagen")
        }

        let description = json["description"] as? String
        let groupsArray = json["groups"] as? [[String: Any]] ?? []

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let simpleIso = ISO8601DateFormatter()
        simpleIso.formatOptions = [.withInternetDateTime]

        func parseDate(_ str: String?) -> Date? {
            guard let str = str else { return nil }
            return iso.date(from: str) ?? simpleIso.date(from: str)
        }

        var parsedGroups: [QuotaGroup] = []

        for groupDict in groupsArray {
            let gName = groupDict["displayName"] as? String ?? "Unbekannt"
            let gDesc = groupDict["description"] as? String
            let bucketsArray = groupDict["buckets"] as? [[String: Any]] ?? []

            var parsedBuckets: [QuotaBucket] = []
            for bDict in bucketsArray {
                let bId = bDict["bucketId"] as? String ?? UUID().uuidString
                let bName = bDict["displayName"] as? String ?? bId
                let bDesc = bDict["description"] as? String
                let window = bDict["window"] as? String
                let remFraction = bDict["remainingFraction"] as? Double ?? 1.0
                let resetDate = parseDate(bDict["resetTime"] as? String)

                parsedBuckets.append(QuotaBucket(
                    id: bId,
                    name: bName,
                    bucketDescription: bDesc,
                    window: window,
                    remainingFraction: remFraction,
                    resetTime: resetDate
                ))
            }

            parsedGroups.append(QuotaGroup(
                name: gName,
                groupDescription: gDesc,
                buckets: parsedBuckets
            ))
        }

        return GeminiUsageData(
            groups: parsedGroups,
            accountEmail: email,
            accountPlan: "Google AI Pro",
            generalDescription: description
        )
    }
}

public enum GeminiAPIError: LocalizedError {
    case notLoggedIn
    case agyBinaryNotFound
    case cliExecutionFailed(String)
    case invalidURL
    case invalidResponse
    case parseError(String)
    case httpError(Int)

    public var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return "Nicht angemeldet – bitte 'agy' im Terminal ausführen"
        case .agyBinaryNotFound:
            return "'agy' CLI-Werkzeug wurde im System nicht gefunden"
        case .cliExecutionFailed(let msg):
            return "Fehler beim Aufruf der CLI: \(msg)"
        case .invalidURL:
            return "Ungültige API-URL"
        case .invalidResponse:
            return "Ungültige Antwort vom Google Cloud Code Dienst"
        case .parseError(let msg):
            return "Fehler beim Verarbeiten der Antwort: \(msg)"
        case .httpError(let code):
            return "HTTP-Fehler \(code)"
        }
    }
}

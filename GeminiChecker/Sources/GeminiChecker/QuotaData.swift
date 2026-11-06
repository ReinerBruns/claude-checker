import Foundation

public struct QuotaBucket: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let bucketDescription: String?
    public let window: String?
    public let remainingFraction: Double
    public let resetTime: Date?

    public var usedFraction: Double {
        max(0.0, min(1.0, 1.0 - remainingFraction))
    }

    public var usedPercent: Int {
        Int((usedFraction * 100.0).rounded())
    }

    public var remainingPercent: Int {
        Int((remainingFraction * 100.0).rounded())
    }

    public var isWeekly: Bool {
        if let window = window?.lowercased() {
            return window.contains("week") || window == "7d"
        }
        return id.lowercased().contains("week") || name.lowercased().contains("wöchentlich") || name.lowercased().contains("weekly")
    }

    public var isSession: Bool {
        if let window = window?.lowercased() {
            return window.contains("5h") || window.contains("hour") || window.contains("session")
        }
        return id.lowercased().contains("5h") || id.lowercased().contains("session") || name.lowercased().contains("five hour")
    }

    /// Fraction of the reset window that has already elapsed (0.0 at start of window -> 1.0 right before reset).
    public var clockElapsedFraction: Double {
        guard let resetTime = resetTime else { return 0.0 }
        let totalWindow: TimeInterval = isSession ? (5.0 * 3600.0) : (7.0 * 24.0 * 3600.0)
        let remaining = resetTime.timeIntervalSince(Date())
        if remaining <= 0 {
            return 1.0
        }
        let clampedRemaining = min(totalWindow, max(0.0, remaining))
        return max(0.0, min(1.0, 1.0 - (clampedRemaining / totalWindow)))
    }

    public var resetTimeString: String? {
        guard let resetTime = resetTime else { return nil }
        let now = Date()
        let diff = resetTime.timeIntervalSince(now)

        if diff <= 0 {
            return "Jetzt fällig"
        }

        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60

        if hours < 24 {
            if hours == 0 {
                return "Zurücksetzung in \(max(1, minutes)) Min."
            } else if minutes == 0 {
                return "Zurücksetzung in \(hours) Std."
            } else {
                return "Zurücksetzung in \(hours) Std. \(minutes) Min."
            }
        } else {
            let days = hours / 24
            let remHours = hours % 24
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "de_DE")
            formatter.dateFormat = "EEE HH:mm"
            let dayTime = formatter.string(from: resetTime)
            if remHours == 0 {
                return "Zurücksetzung \(dayTime) (in \(days) T.)"
            } else {
                return "Zurücksetzung \(dayTime) (in \(days) T. \(remHours) Std.)"
            }
        }
    }
}

public struct QuotaGroup: Identifiable, Sendable {
    public var id: String { name }
    public let name: String
    public let groupDescription: String?
    public let buckets: [QuotaBucket]

    public var weeklyBucket: QuotaBucket? {
        buckets.first(where: { $0.isWeekly }) ?? buckets.first
    }

    public var sessionBucket: QuotaBucket? {
        buckets.first(where: { $0.isSession })
    }

    public var isArgon: Bool {
        name.lowercased().contains("argon")
    }

    public var isGemini: Bool {
        name.lowercased().contains("gemini") && !isArgon
    }

    public var isThirdParty: Bool {
        name.lowercased().contains("claude") || name.lowercased().contains("gpt") || name.lowercased().contains("3p")
    }
}

public struct GeminiUsageData: Sendable {
    public let groups: [QuotaGroup]
    public let accountEmail: String?
    public let accountPlan: String?
    public let generalDescription: String?

    public static let empty = GeminiUsageData(
        groups: [],
        accountEmail: nil,
        accountPlan: nil,
        generalDescription: nil
    )

    public var geminiGroup: QuotaGroup? {
        groups.first(where: { $0.isGemini }) ?? groups.first
    }

    public var argonGroup: QuotaGroup? {
        groups.first(where: { $0.isArgon })
    }

    public var thirdPartyGroup: QuotaGroup? {
        groups.first(where: { $0.isThirdParty })
    }

    // 1. Gemini Models Weekly (Thick Bar)
    public var geminiWeeklyFraction: Double {
        geminiGroup?.weeklyBucket?.usedFraction ?? 0.0
    }

    // 2. Gemini Models 5-Hour (Small Bar)
    public var gemini5hFraction: Double {
        geminiGroup?.sessionBucket?.usedFraction ?? 0.0
    }

    // 3. Gemini 4 Argon Weekly (Thick Bar)
    public var argonWeeklyFraction: Double {
        argonGroup?.weeklyBucket?.usedFraction ?? 0.0
    }

    // Claude / GPT Models (if applicable)
    public var thirdPartyWeeklyFraction: Double {
        thirdPartyGroup?.weeklyBucket?.usedFraction ?? 0.0
    }

    public var thirdParty5hFraction: Double {
        thirdPartyGroup?.sessionBucket?.usedFraction ?? 0.0
    }

    // Reset Clock Fractions (0.0 -> 1.0 as reset approaches)
    /// Gemini Models: 5-Hour Session reset clock
    public var geminiResetClockFraction: Double {
        geminiGroup?.sessionBucket?.clockElapsedFraction ?? 0.0
    }

    /// Gemini 4 Argon: Weekly reset clock (no 5h bucket)
    public var argonResetClockFraction: Double {
        argonGroup?.weeklyBucket?.clockElapsedFraction ?? 0.0
    }

    /// Claude & GPT Models: 5-Hour Session reset clock
    public var thirdPartyResetClockFraction: Double {
        thirdPartyGroup?.sessionBucket?.clockElapsedFraction ?? 0.0
    }
}

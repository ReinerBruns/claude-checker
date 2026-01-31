import Foundation

/// Usage data from claude.ai plan limits (session + weekly)
struct ClaudeUsageData {
    // Session (5-hour rolling window) — "Current session" on claude.ai
    var sessionPercent: Double      // 0-100
    var sessionResetTime: Date?

    // Weekly (7-day) — "Wöchentliche Limits" on claude.ai
    var weeklyPercent: Double       // 0-100
    var weeklyResetTime: Date?

    // Normalized to 0.0-1.0 for progress bars
    var sessionFraction: Double { min(1.0, max(0.0, sessionPercent / 100.0)) }
    var weeklyFraction: Double { min(1.0, max(0.0, weeklyPercent / 100.0)) }

    static let empty = ClaudeUsageData(
        sessionPercent: 0, sessionResetTime: nil,
        weeklyPercent: 0, weeklyResetTime: nil
    )
}

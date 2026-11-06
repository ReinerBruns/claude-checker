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

    /// Elapsed fraction (0.0 -> 1.0) toward the 5-hour session reset
    var sessionResetClockFraction: Double {
        guard let reset = sessionResetTime else { return 0.0 }
        let totalWindow: TimeInterval = 5.0 * 3600.0
        let remaining = reset.timeIntervalSince(Date())
        if remaining <= 0 { return 1.0 }
        let clamped = min(totalWindow, max(0.0, remaining))
        return max(0.0, min(1.0, 1.0 - (clamped / totalWindow)))
    }

    /// Elapsed fraction (0.0 -> 1.0) toward the 7-day weekly reset
    var weeklyResetClockFraction: Double {
        guard let reset = weeklyResetTime else { return 0.0 }
        let totalWindow: TimeInterval = 7.0 * 24.0 * 3600.0
        let remaining = reset.timeIntervalSince(Date())
        if remaining <= 0 { return 1.0 }
        let clamped = min(totalWindow, max(0.0, remaining))
        return max(0.0, min(1.0, 1.0 - (clamped / totalWindow)))
    }

    static let empty = ClaudeUsageData(
        sessionPercent: 0, sessionResetTime: nil,
        weeklyPercent: 0, weeklyResetTime: nil
    )
}

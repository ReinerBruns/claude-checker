import Cocoa

/// Custom NSView drawing 3 Apple-Watch-style concentric activity rings side by side in the macOS menu bar:
/// 1. "G" (Gemini Models): Outer ring = Weekly, Inner ring = 5-Hour Session
/// 2. "A" (Gemini 4 Argon): Outer ring = Weekly ONLY
/// 3. "C" (Claude & GPT Models): Outer ring = Weekly, Inner ring = 5-Hour Session
///
/// Rings start at 12 o'clock and fill clockwise.
/// Color thresholds: Green (<50%), Orange (50-75%), Red (>=75%).
final class ProgressBarView: NSView {
    /// 1. Gemini Models (Weekly + 5h Session + 5h Reset Clock)
    var geminiWeeklyFraction: Double = 0.0 { didSet { needsDisplay = true } }
    var gemini5hFraction: Double = 0.0 { didSet { needsDisplay = true } }
    var geminiClockFraction: Double = 0.0 { didSet { needsDisplay = true } }

    /// 2. Gemini 4 Argon (Weekly only + Weekly Reset Clock)
    var argonWeeklyFraction: Double = 0.0 { didSet { needsDisplay = true } }
    var argonClockFraction: Double = 0.0 { didSet { needsDisplay = true } }

    /// 3. Claude & GPT Models (Weekly + 5h Session + 5h Reset Clock)
    var thirdPartyWeeklyFraction: Double = 0.0 { didSet { needsDisplay = true } }
    var thirdParty5hFraction: Double = 0.0 { didSet { needsDisplay = true } }
    var thirdPartyClockFraction: Double = 0.0 { didSet { needsDisplay = true } }

    // Ring geometry: uses the full vertical height of the macOS StatusBarButton (24pt on modern macOS)
    private let gaugeGap: CGFloat = 4.0

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 82.0, height: 24.0)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Use the full available height of the status bar button (typically 24pt)
        let availableHeight = max(22.0, bounds.height)
        let gaugeDiameter = availableHeight - 0.4
        let totalWidth = (gaugeDiameter * 3.0) + (gaugeGap * 2.0)

        let centerY = bounds.height / 2.0
        var currentCenterX = max(gaugeDiameter / 2.0, (bounds.width - totalWidth) / 2.0 + (gaugeDiameter / 2.0))

        // 1. "G" – Gemini Models (Weekly outer ring + 5h inner ring + 5h reset clock)
        drawGaugeRing(
            center: NSPoint(x: currentCenterX, y: centerY),
            diameter: gaugeDiameter,
            label: "G",
            weeklyFraction: geminiWeeklyFraction,
            sessionFraction: gemini5hFraction,
            clockFraction: geminiClockFraction
        )

        currentCenterX += gaugeDiameter + gaugeGap

        // 2. "A" – Gemini 4 Argon (Weekly outer ring only + Weekly reset clock)
        drawGaugeRing(
            center: NSPoint(x: currentCenterX, y: centerY),
            diameter: gaugeDiameter,
            label: "A",
            weeklyFraction: argonWeeklyFraction,
            sessionFraction: nil,
            clockFraction: argonClockFraction
        )

        currentCenterX += gaugeDiameter + gaugeGap

        // 3. "C" – Claude & GPT Models (Weekly outer ring + 5h inner ring + 5h reset clock)
        drawGaugeRing(
            center: NSPoint(x: currentCenterX, y: centerY),
            diameter: gaugeDiameter,
            label: "C",
            weeklyFraction: thirdPartyWeeklyFraction,
            sessionFraction: thirdParty5hFraction,
            clockFraction: thirdPartyClockFraction
        )
    }

    private func drawGaugeRing(
        center: NSPoint,
        diameter: CGFloat,
        label: String,
        weeklyFraction: Double,
        sessionFraction: Double?,
        clockFraction: Double
    ) {
        let scale = diameter / 23.6
        let outerLineWidth: CGFloat = 2.75 * scale
        let innerLineWidth: CGFloat = 2.15 * scale
        let outerRadius: CGFloat = (diameter / 2.0) - (outerLineWidth / 2.0) - 0.15
        let innerRadius: CGFloat = outerRadius - (outerLineWidth / 2.0) - (innerLineWidth / 2.0) - (0.55 * scale)

        // 1. Dark circular badge backing for the outer quota rings (Green/Orange/Red pop best on dark)
        let badgeRadius = diameter / 2.0
        let badgeRect = NSRect(
            x: center.x - badgeRadius,
            y: center.y - badgeRadius,
            width: diameter,
            height: diameter
        )
        let badgePath = NSBezierPath(ovalIn: badgeRect)
        NSColor(white: 0.10, alpha: 0.85).setFill()
        badgePath.fill()

        // 2. Crisp White Clock Dial in the center + Ocean/Sky Blue Clock Pie
        let clockRadius: CGFloat = (sessionFraction != nil)
            ? (innerRadius - (innerLineWidth / 2.0) - (0.35 * scale))
            : (outerRadius - (outerLineWidth / 2.0) - (0.50 * scale))

        let clockRect = NSRect(
            x: center.x - clockRadius,
            y: center.y - clockRadius,
            width: clockRadius * 2.0,
            height: clockRadius * 2.0
        )
        let clockCirclePath = NSBezierPath(ovalIn: clockRect)
        NSColor(white: 0.96, alpha: 0.98).setFill()
        clockCirclePath.fill()

        let clampedClock = max(0.0, min(1.0, clockFraction))
        if clampedClock > 0.005 {
            let clockColor = NSColor(red: 0.22, green: 0.62, blue: 1.00, alpha: 0.96)
            NSGraphicsContext.current?.saveGraphicsState()
            clockCirclePath.addClip()
            if clampedClock >= 0.998 {
                clockColor.setFill()
                clockCirclePath.fill()
            } else {
                let sweepDegrees = max(6.0, CGFloat(clampedClock) * 360.0)
                let piePath = NSBezierPath()
                piePath.move(to: center)
                piePath.appendArc(
                    withCenter: center,
                    radius: clockRadius,
                    startAngle: 90.0,
                    endAngle: 90.0 - sweepDegrees,
                    clockwise: true
                )
                piePath.close()
                clockColor.setFill()
                piePath.fill()
            }
            NSGraphicsContext.current?.restoreGraphicsState()
        }

        // 2. Outer Ring Track (Weekly)
        let outerTrackPath = NSBezierPath()
        outerTrackPath.appendArc(
            withCenter: center,
            radius: outerRadius,
            startAngle: 0,
            endAngle: 360
        )
        outerTrackPath.lineWidth = outerLineWidth
        NSColor(white: 1.0, alpha: 0.18).setStroke()
        outerTrackPath.stroke()

        // 3. Outer Ring Progress (Weekly, clockwise from 12 o'clock = 90°)
        let clampedWeekly = max(0.0, min(1.0, weeklyFraction))
        if clampedWeekly > 0.001 {
            // Minimum visible arc of ~12 degrees so even 1-3% is clearly visible
            let sweepDegrees = max(12.0, CGFloat(clampedWeekly) * 360.0)
            let startAngle: CGFloat = 90.0
            let endAngle: CGFloat = 90.0 - min(359.9, sweepDegrees)

            let outerArc = NSBezierPath()
            outerArc.appendArc(
                withCenter: center,
                radius: outerRadius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
            outerArc.lineWidth = outerLineWidth
            outerArc.lineCapStyle = .round
            colorForFraction(clampedWeekly, isInner: false).setStroke()
            outerArc.stroke()
        }

        // 4. Inner Ring (5-Hour Session, if applicable)
        if let sessionFraction = sessionFraction {
            let innerTrackPath = NSBezierPath()
            innerTrackPath.appendArc(
                withCenter: center,
                radius: innerRadius,
                startAngle: 0,
                endAngle: 360
            )
            innerTrackPath.lineWidth = innerLineWidth
            NSColor(white: 1.0, alpha: 0.13).setStroke()
            innerTrackPath.stroke()

            let clampedSession = max(0.0, min(1.0, sessionFraction))
            if clampedSession > 0.001 {
                let sweepDegrees = max(14.0, CGFloat(clampedSession) * 360.0)
                let startAngle: CGFloat = 90.0
                let endAngle: CGFloat = 90.0 - min(359.9, sweepDegrees)

                let innerArc = NSBezierPath()
                innerArc.appendArc(
                    withCenter: center,
                    radius: innerRadius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: true
                )
                innerArc.lineWidth = innerLineWidth
                innerArc.lineCapStyle = .round
                colorForFraction(clampedSession, isInner: true).setStroke()
                innerArc.stroke()
            }
        }

        // 5. Center Label ("G", "A", "C") in deep anthracite for high contrast on white & sky-blue clock dial
        let font = NSFont.systemFont(ofSize: round(8.5 * scale * 2.0) / 2.0, weight: .heavy)
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 0, height: 0)
        shadow.shadowBlurRadius = 1.0
        shadow.shadowColor = NSColor.white.withAlphaComponent(0.6)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(white: 0.08, alpha: 0.96),
            .shadow: shadow
        ]

        let attrString = NSAttributedString(string: label, attributes: attrs)
        let textSize = attrString.size()
        let textPoint = NSPoint(
            x: center.x - (textSize.width / 2.0),
            y: center.y - (textSize.height / 2.0)
        )
        attrString.draw(at: textPoint)
    }

    private func colorForFraction(_ fraction: Double, isInner: Bool) -> NSColor {
        // Usage: < 50% Green, 50-75% Orange, >= 75% Red
        // Inner ring uses a slightly brighter/lighter tint for crisp separation from the outer ring
        if fraction < 0.50 {
            return isInner
                ? NSColor(red: 0.30, green: 0.95, blue: 0.50, alpha: 1.0) // Bright Mint/Green
                : NSColor(red: 0.18, green: 0.82, blue: 0.34, alpha: 1.0) // Vivid Apple Green
        } else if fraction < 0.75 {
            return isInner
                ? NSColor(red: 1.00, green: 0.74, blue: 0.22, alpha: 1.0) // Bright Amber/Orange
                : NSColor(red: 1.00, green: 0.58, blue: 0.08, alpha: 1.0) // Vivid Apple Orange
        } else {
            return isInner
                ? NSColor(red: 1.00, green: 0.38, blue: 0.34, alpha: 1.0) // Bright Coral/Red
                : NSColor(red: 0.96, green: 0.22, blue: 0.20, alpha: 1.0) // Vivid Apple Red
        }
    }
}

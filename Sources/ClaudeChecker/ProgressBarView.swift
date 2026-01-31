import Cocoa

final class ProgressBarView: NSView {
    /// Session usage (5h window), 0.0 - 1.0
    var sessionFraction: Double = 0.0 { didSet { needsDisplay = true } }
    /// Weekly usage (7 day), 0.0 - 1.0
    var weeklyFraction: Double = 0.0 { didSet { needsDisplay = true } }

    private let barWidth: CGFloat = 80
    private let barHeight: CGFloat = 18
    private let innerInset: CGFloat = 3
    private let cornerRadius: CGFloat = 3

    override var intrinsicContentSize: NSSize {
        NSSize(width: barWidth, height: barHeight)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let fullRect = NSRect(x: 0, y: 0, width: barWidth, height: barHeight)

        // Background
        let bgPath = NSBezierPath(roundedRect: fullRect, xRadius: cornerRadius, yRadius: cornerRadius)
        NSColor(white: 0.2, alpha: 1.0).setFill()
        bgPath.fill()

        // Outer bar: Weekly usage (full height, darker shade)
        if weeklyFraction > 0 {
            let outerWidth = max(0, min(barWidth, CGFloat(weeklyFraction) * barWidth))
            let outerRect = NSRect(x: 0, y: 0, width: outerWidth, height: barHeight)
            let outerPath = NSBezierPath(roundedRect: outerRect, xRadius: cornerRadius, yRadius: cornerRadius)
            colorForFraction(weeklyFraction, dark: true).setFill()
            outerPath.fill()
        }

        // Inner bar: Session usage (inset, lighter shade)
        let innerHeight = barHeight - (innerInset * 2)
        if sessionFraction > 0 {
            let innerMaxWidth = barWidth - (innerInset * 2)
            let innerWidth = max(0, min(innerMaxWidth, CGFloat(sessionFraction) * innerMaxWidth))
            let innerRect = NSRect(x: innerInset, y: innerInset, width: innerWidth, height: innerHeight)
            let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: 2, yRadius: 2)
            colorForFraction(sessionFraction, dark: false).setFill()
            innerPath.fill()
        }

        // Text: "S% / W%"
        let sText = "\(Int(sessionFraction * 100))"
        let wText = "\(Int(weeklyFraction * 100))"
        let displayText = "\(sText)/\(wText)%"

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 0, height: -0.5)
        shadow.shadowBlurRadius = 1
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.7)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 8),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle,
            .shadow: shadow
        ]

        let textRect = NSRect(x: 0, y: (barHeight - 10) / 2, width: barWidth, height: 12)
        displayText.draw(in: textRect, withAttributes: attrs)
    }

    private func colorForFraction(_ fraction: Double, dark: Bool) -> NSColor {
        let alpha: CGFloat = dark ? 0.85 : 0.95
        if fraction < 0.50 {
            return dark ? NSColor(red: 0.15, green: 0.65, blue: 0.25, alpha: alpha)
                        : NSColor(red: 0.25, green: 0.80, blue: 0.35, alpha: alpha)
        } else if fraction < 0.75 {
            return dark ? NSColor(red: 0.85, green: 0.65, blue: 0.10, alpha: alpha)
                        : NSColor(red: 0.95, green: 0.78, blue: 0.20, alpha: alpha)
        } else {
            return dark ? NSColor(red: 0.80, green: 0.15, blue: 0.15, alpha: alpha)
                        : NSColor(red: 0.95, green: 0.30, blue: 0.25, alpha: alpha)
        }
    }
}

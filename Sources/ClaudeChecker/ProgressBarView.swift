import Cocoa

final class ProgressBarView: NSView {
    /// Session usage (5h window), 0.0 - 1.0
    var sessionFraction: Double = 0.0 { didSet { needsDisplay = true } }
    /// Weekly usage (7 day), 0.0 - 1.0
    var weeklyFraction: Double = 0.0 { didSet { needsDisplay = true } }
    /// Elapsed time toward 5h session reset, 0.0 - 1.0 (Top blue bar)
    var sessionResetFraction: Double = 0.0 { didSet { needsDisplay = true } }
    /// Elapsed time toward 7d weekly reset, 0.0 - 1.0 (Bottom blue bar)
    var weeklyResetFraction: Double = 0.0 { didSet { needsDisplay = true } }

    private let cornerRadius: CGFloat = 4.0
    private let resetBarHeight: CGFloat = 3.2
    private let separatorHeight: CGFloat = 0.8
    private let innerInset: CGFloat = 2.5

    override var intrinsicContentSize: NSSize {
        NSSize(width: 90, height: 24)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Use almost the entire status bar button bounds (full height up to 23.4pt)
        let horizontalMargin: CGFloat = 1.5
        let verticalMargin: CGFloat = 0.3
        let fullRect = NSRect(
            x: horizontalMargin,
            y: verticalMargin,
            width: max(80, bounds.width - (horizontalMargin * 2.0)),
            height: max(21.4, bounds.height - (verticalMargin * 2.0))
        )

        let outerClipPath = NSBezierPath(roundedRect: fullRect, xRadius: cornerRadius, yRadius: cornerRadius)

        NSGraphicsContext.current?.saveGraphicsState()
        outerClipPath.addClip()

        // 1. Base Background
        NSColor(white: 0.16, alpha: 0.96).setFill()
        fullRect.fill()

        // Geometry for Top Reset Bar, Middle Quota Area, and Bottom Reset Bar
        let topBarRect = NSRect(
            x: fullRect.minX,
            y: fullRect.maxY - resetBarHeight,
            width: fullRect.width,
            height: resetBarHeight
        )
        let bottomBarRect = NSRect(
            x: fullRect.minX,
            y: fullRect.minY,
            width: fullRect.width,
            height: resetBarHeight
        )
        let middleRect = NSRect(
            x: fullRect.minX,
            y: bottomBarRect.maxY + separatorHeight,
            width: fullRect.width,
            height: fullRect.height - (resetBarHeight * 2.0) - (separatorHeight * 2.0)
        )

        // 2. Middle Area: Outer bar = Weekly usage (darker shade)
        NSColor(white: 0.22, alpha: 1.0).setFill()
        middleRect.fill()

        if weeklyFraction > 0 {
            let outerWidth = max(0, min(middleRect.width, CGFloat(weeklyFraction) * middleRect.width))
            let outerRect = NSRect(x: middleRect.minX, y: middleRect.minY, width: outerWidth, height: middleRect.height)
            colorForFraction(weeklyFraction, dark: true).setFill()
            outerRect.fill()
        }

        // 3. Middle Area: Inner bar = 5h Session usage (inset, lighter shade)
        let innerHeight = middleRect.height - (innerInset * 2.0)
        if sessionFraction > 0 && innerHeight > 2 {
            let innerMaxWidth = middleRect.width - (innerInset * 2.0)
            let innerWidth = max(0, min(innerMaxWidth, CGFloat(sessionFraction) * innerMaxWidth))
            let innerRect = NSRect(
                x: middleRect.minX + innerInset,
                y: middleRect.minY + innerInset,
                width: innerWidth,
                height: innerHeight
            )
            let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: 2.0, yRadius: 2.0)
            colorForFraction(sessionFraction, dark: false).setFill()
            innerPath.fill()
        }

        // 4. Dark separators between quota area and top/bottom reset bars
        NSColor(white: 0.06, alpha: 0.95).setFill()
        NSRect(x: fullRect.minX, y: topBarRect.minY - separatorHeight, width: fullRect.width, height: separatorHeight).fill()
        NSRect(x: fullRect.minX, y: bottomBarRect.maxY, width: fullRect.width, height: separatorHeight).fill()

        // 5. Top Bar: 5-Hour Session Reset Progress (Ocean Blue on White Track)
        NSColor(white: 0.96, alpha: 0.98).setFill()
        topBarRect.fill()
        let clampedSessionReset = max(0.0, min(1.0, sessionResetFraction))
        if clampedSessionReset > 0.001 {
            let topFillWidth = max(2.5, CGFloat(clampedSessionReset) * topBarRect.width)
            let topFillRect = NSRect(x: topBarRect.minX, y: topBarRect.minY, width: topFillWidth, height: topBarRect.height)
            NSColor(red: 0.12, green: 0.56, blue: 1.00, alpha: 1.0).setFill()
            topFillRect.fill()
        }

        // 6. Bottom Bar: 7-Day Weekly Reset Progress (Ocean Blue on White Track)
        NSColor(white: 0.96, alpha: 0.98).setFill()
        bottomBarRect.fill()
        let clampedWeeklyReset = max(0.0, min(1.0, weeklyResetFraction))
        if clampedWeeklyReset > 0.001 {
            let bottomFillWidth = max(2.5, CGFloat(clampedWeeklyReset) * bottomBarRect.width)
            let bottomFillRect = NSRect(x: bottomBarRect.minX, y: bottomBarRect.minY, width: bottomFillWidth, height: bottomBarRect.height)
            NSColor(red: 0.06, green: 0.46, blue: 0.95, alpha: 1.0).setFill()
            bottomFillRect.fill()
        }

        // 7. Crisp Text in Middle Area: "S% / W%"
        let sText = "\(Int((sessionFraction * 100).rounded()))"
        let wText = "\(Int((weeklyFraction * 100).rounded()))"
        let displayText = "\(sText)/\(wText)%"

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(width: 0, height: -0.5)
        shadow.shadowBlurRadius = 1.5
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.85)

        let font = NSFont.systemFont(ofSize: 10.0, weight: .heavy)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraphStyle,
            .shadow: shadow
        ]

        let textSize = (displayText as NSString).size(withAttributes: attrs)
        let textRect = NSRect(
            x: middleRect.minX,
            y: middleRect.minY + (middleRect.height - textSize.height) / 2.0,
            width: middleRect.width,
            height: textSize.height
        )
        displayText.draw(in: textRect, withAttributes: attrs)

        NSGraphicsContext.current?.restoreGraphicsState()

        // Subtle outer border
        NSColor(white: 1.0, alpha: 0.16).setStroke()
        outerClipPath.lineWidth = 0.5
        outerClipPath.stroke()
    }

    private func colorForFraction(_ fraction: Double, dark: Bool) -> NSColor {
        let alpha: CGFloat = dark ? 0.88 : 0.96
        if fraction < 0.50 {
            return dark ? NSColor(red: 0.15, green: 0.65, blue: 0.25, alpha: alpha)
                        : NSColor(red: 0.25, green: 0.82, blue: 0.36, alpha: alpha)
        } else if fraction < 0.75 {
            return dark ? NSColor(red: 0.90, green: 0.52, blue: 0.08, alpha: alpha)
                        : NSColor(red: 1.00, green: 0.68, blue: 0.18, alpha: alpha)
        } else {
            return dark ? NSColor(red: 0.82, green: 0.15, blue: 0.15, alpha: alpha)
                        : NSColor(red: 0.96, green: 0.30, blue: 0.25, alpha: alpha)
        }
    }
}

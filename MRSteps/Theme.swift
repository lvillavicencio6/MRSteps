import SpriteKit
import UIKit

enum Theme {
    static let skyTop = SKColor(red: 0.07, green: 0.10, blue: 0.20, alpha: 1)
    static let skyBottom = SKColor(red: 0.16, green: 0.22, blue: 0.38, alpha: 1)
    static let star = SKColor(red: 0.95, green: 0.93, blue: 0.82, alpha: 1)
    static let moon = SKColor(red: 0.93, green: 0.88, blue: 0.68, alpha: 1)

    static let stepTop = SKColor(red: 0.93, green: 0.62, blue: 0.38, alpha: 1)
    static let stepMid = SKColor(red: 0.78, green: 0.42, blue: 0.28, alpha: 1)
    static let stepDark = SKColor(red: 0.42, green: 0.20, blue: 0.18, alpha: 1)
    static let stepGrout = SKColor(red: 0.28, green: 0.14, blue: 0.14, alpha: 1)
    static let stepHighlight = SKColor(red: 0.98, green: 0.82, blue: 0.55, alpha: 1)

    static let ink = SKColor(red: 0.10, green: 0.08, blue: 0.12, alpha: 1)
    static let cream = SKColor(red: 0.96, green: 0.93, blue: 0.84, alpha: 1)
    static let gold = SKColor(red: 0.96, green: 0.78, blue: 0.22, alpha: 1)
    static let danger = SKColor(red: 0.86, green: 0.22, blue: 0.28, alpha: 1)
    static let safe = SKColor(red: 0.32, green: 0.78, blue: 0.48, alpha: 1)

    static let cap = SKColor(red: 0.82, green: 0.18, blue: 0.24, alpha: 1)
    static let skin = SKColor(red: 0.94, green: 0.76, blue: 0.55, alpha: 1)
    static let shirt = SKColor(red: 0.18, green: 0.48, blue: 0.62, alpha: 1)
    static let pants = SKColor(red: 0.14, green: 0.22, blue: 0.38, alpha: 1)
    static let shoe = SKColor(red: 0.18, green: 0.12, blue: 0.10, alpha: 1)
}

enum Layout {
    static let stepPixelW = 40
    static let stepPixelH = 14
    static let artScale: CGFloat = 4
    static let stepSpacing: CGFloat = 92
    static let lateral: CGFloat = 78
    static let heroScale: CGFloat = 5
}

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func land() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func fail() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}

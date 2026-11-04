import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

enum Theme {
    static let bg = Color(hex: 0x07090A)
    static let bg2 = Color(hex: 0x0C1011)
    static let surface = Color(hex: 0x13181A)
    static let surface2 = Color(hex: 0x1A2023)
    static let surface3 = Color(hex: 0x222A2D)
    static let line = Color.white.opacity(0.07)
    static let line2 = Color.white.opacity(0.12)
    static let fg = Color(hex: 0xEEF3F2)
    static let fg2 = Color(hex: 0xC9D2D0)
    static let muted = Color(hex: 0x86928F)
    static let teal = Color(hex: 0x1FC8AD)
    static let cyan = Color(hex: 0x2FD3EA)
    static let blue = Color(hex: 0x3B9CF5)
    static let ok = Color(hex: 0x36D27A)
    static let term = Color(hex: 0x39E75F)

    static let card = LinearGradient(colors: [Color(hex: 0x151B1D), Color(hex: 0x121719)], startPoint: .top, endPoint: .bottom)
    static let tile = LinearGradient(colors: [Color(hex: 0x161C1E), Color(hex: 0x111618)], startPoint: .top, endPoint: .bottom)
    static let selected = LinearGradient(colors: [Color(hex: 0x1F4A4E), Color(hex: 0x173436)], startPoint: .top, endPoint: .bottom)
    static let wideButton = LinearGradient(colors: [Color(hex: 0x1C3A3D), Color(hex: 0x142A2C)], startPoint: .top, endPoint: .bottom)

    static let mono = Font.system(size: 14, design: .monospaced)
}

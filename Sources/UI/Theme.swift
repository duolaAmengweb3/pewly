import SwiftUI

/// Warm Utility — light, paper, quiet, reverent. Solid surfaces only (no glass), per house style.
/// Hierarchy = warm brightness steps + hairlines + restrained shadow. One accent: deep indigo.
/// Serif for sermon titles gives the archival/reverent character.
enum Theme {
    static let canvas   = Color(hex: 0xF5F3EF)   // warm white背景,不刺眼
    static let surface  = Color(hex: 0xFCFBF8)    // 卡 / 分组
    static let elevated = Color(hex: 0xFFFFFF)    // sheet / 浮层
    static let textHi   = Color(hex: 0x24221F)    // 深墨 ink
    static let textMid  = Color(hex: 0x6F6A63)
    static let textLow  = Color(hex: 0x9A958C)
    static let accent   = Color(hex: 0x3A4A78)    // 深靛蓝(reverent),覆盖 5-12%
    static let accentSoft = Color(hex: 0xE7E9F1)  // 靛蓝浅底
    static let hairline = Color(hex: 0x24221F).opacity(0.08)

    static let success  = Color(hex: 0x5C8A63)
    static let warning  = Color(hex: 0xC08A3E)
    static let gold     = Color(hex: 0xB99449)   // 经文/强调点缀

    static let cardRadius: CGFloat = 16
    static let heroRadius: CGFloat = 20

    /// serif 用于讲道标题(档案/虔敬感)
    static func serif(_ size: CGFloat, _ w: Font.Weight = .semibold) -> Font { .system(size: size, weight: w, design: .serif) }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff)/255, green: Double((hex >> 8) & 0xff)/255,
                  blue: Double(hex & 0xff)/255, opacity: alpha)
    }
}

struct Card: ViewModifier {
    var surface: Color = Theme.surface
    var radius: CGFloat = Theme.cardRadius
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content.padding(padding)
            .background(surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
            .shadow(color: Color(hex: 0x443C32).opacity(0.06), radius: 14, y: 5)
    }
}
extension View {
    func card(_ s: Color = Theme.surface, radius: CGFloat = Theme.cardRadius, padding: CGFloat = 16) -> some View {
        modifier(Card(surface: s, radius: radius, padding: padding))
    }
    func screenBackground() -> some View { frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.canvas.ignoresSafeArea()) }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold)).foregroundStyle(.white)
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1).scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.accent)
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
